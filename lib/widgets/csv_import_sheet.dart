// lib/widgets/csv_import_sheet.dart — bring a product or customer list in
// from a spreadsheet.
//
// The sheet shows the format first — which columns, which are needed,
// and an example — because the commonest failure is not a bug but a
// file shaped differently from what anyone expected. Then it reads the
// file, says exactly what it found (new, already there, rows it could
// not use and why), and only writes when the shopkeeper says so.
//
// Products go into both lists the app keeps: Products (with cost and
// stock) and the Catalog the invoice screen picks from. Anything whose
// name is already in a list is skipped there, never overwritten — an
// import should not quietly change a price someone set by hand.

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:billzap/theme/app_icons.dart';

import '../design/components.dart';
import '../i18n/translations.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../screens/main/catalog_screen.dart' show CatalogItem, CatalogService;
import '../services/gst_classifier.dart';
import '../tax/active_profile.dart';
import '../theme/app_theme.dart';
import '../utils/csv_import.dart';

enum CsvImportKind { products, customers }

Future<void> showCsvImport(BuildContext context, CsvImportKind kind) {
  HapticFeedback.lightImpact();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CsvImportSheet(kind: kind),
  );
}

class _CsvImportSheet extends ConsumerStatefulWidget {
  final CsvImportKind kind;
  const _CsvImportSheet({required this.kind});

  @override
  ConsumerState<_CsvImportSheet> createState() => _CsvImportSheetState();
}

class _CsvImportSheetState extends ConsumerState<_CsvImportSheet> {
  bool _busy = false;
  String? _fileName;
  String? _problem; // a whole-file problem, already translated

  // Products
  List<Product> _newProducts = [];
  List<CatalogItem> _newCatalog = [];
  // Customers
  List<Customer> _newCustomers = [];

  int _skipped = 0;
  List<CsvRowError> _errors = [];
  bool _read = false;

  bool get _products => widget.kind == CsvImportKind.products;
  int get _ready => _products ? _newProducts.length : _newCustomers.length;

  Future<void> _pick() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      final picked = await FilePicker.pickFile(type: FileType.any);
      final path = picked?.path;
      if (path == null) return;
      final bytes = await File(path).readAsBytes();
      // Excel on Windows still saves "CSV" in the old Windows code page;
      // reading it as UTF-8 with malformed bytes allowed keeps every
      // ASCII name and price intact instead of refusing the file.
      final text = utf8.decode(bytes, allowMalformed: true);
      _fileName = path.split(Platform.pathSeparator).last;
      if (_products) {
        await _readProducts(text);
      } else {
        _readCustomers(text);
      }
    } catch (_) {
      _problem = trGlobal('csv.err_read');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _readProducts(String text) async {
    final parsed = parseProductsCsv(text);
    if (!parsed.headerFound) {
      _problem = trGlobal('csv.err_header');
      _read = false;
      return;
    }
    final existing = ref.read(productProvider).map((p) => sameNameKey(p.name)).toSet();
    final catalog = (await CatalogService.getAll()).map((c) => sameNameKey(c.name)).toSet();
    final seen = <String>{};
    final products = <Product>[];
    final items = <CatalogItem>[];
    var skipped = 0;
    final india = activeProfile.countryCode == 'IN';
    for (final r in parsed.rows) {
      final key = sameNameKey(r.name);
      if (!seen.add(key)) {
        skipped++;
        continue;
      }
      // Tax: the file's own rate if it has one. Otherwise India's item-name
      // classifier where it applies, and the country's standard rate
      // everywhere else — the same defaults typing the item in would give.
      var rate = r.taxRate;
      if (rate == null && india) {
        final guess = GstClassifier.classify(r.name);
        if (guess >= 0) rate = guess.toDouble();
      }
      rate ??= activeProfile.defaultRate;
      final unit = r.unit.isEmpty ? 'Nos' : r.unit;
      final inProducts = existing.contains(key);
      final inCatalog = catalog.contains(key);
      if (inProducts && inCatalog) {
        skipped++;
        continue;
      }
      if (!inProducts) {
        products.add(Product(
          name: r.name,
          price: r.price,
          gstRate: rate,
          hsnCode: r.code,
          unit: unit,
          cost: r.cost ?? 0,
          stock: r.stock ?? -1,
          lowStockAt: r.lowStockAt ?? 0,
        ));
      }
      if (!inCatalog) {
        items.add(CatalogItem(
          id: genId(),
          name: r.name,
          price: r.price,
          gstRate: rate.round(),
          hsnCode: r.code,
          unit: unit,
        ));
      }
    }
    if (!mounted) return;
    setState(() {
      _newProducts = products;
      _newCatalog = items;
      _skipped = skipped;
      _errors = parsed.errors;
      _read = true;
    });
  }

  void _readCustomers(String text) {
    final parsed = parseCustomersCsv(text);
    if (!parsed.headerFound) {
      _problem = trGlobal('csv.err_header');
      _read = false;
      return;
    }
    final existing = ref.read(customerProvider);
    final phones = existing
        .map((c) => samePhoneKey(c.phone))
        .where((p) => p.isNotEmpty)
        .toSet();
    final names = existing.map((c) => sameNameKey(c.name)).toSet();
    final out = <Customer>[];
    var skipped = 0;
    for (final r in parsed.rows) {
      // Same phone number = same person, whatever the spelling of the
      // name. No phone: fall back to the name.
      final phone = samePhoneKey(r.phone);
      final dup = phone.isNotEmpty
          ? !phones.add(phone)
          : !names.add(sameNameKey(r.name));
      if (dup) {
        skipped++;
        continue;
      }
      names.add(sameNameKey(r.name));
      out.add(Customer(
        name: r.name,
        phone: r.phone,
        email: r.email,
        address: r.address,
        city: r.city,
        state: r.state,
        gstin: r.taxId,
      ));
    }
    _newCustomers = out;
    _skipped = skipped;
    _errors = parsed.errors;
    _read = true;
  }

  Future<void> _import() async {
    if (_busy || _ready == 0 && _newCatalog.isEmpty) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      String done;
      if (_products) {
        if (_newProducts.isNotEmpty) {
          await ref.read(productProvider.notifier).addAll(_newProducts);
        }
        if (_newCatalog.isNotEmpty) await CatalogService.addAll(_newCatalog);
        done = trGlobal('csv.done_products', {
          'n': _newProducts.length > _newCatalog.length
              ? _newProducts.length
              : _newCatalog.length,
        });
      } else {
        await ref.read(customerProvider.notifier).addAll(_newCustomers);
        done = trGlobal('csv.done_customers', {'n': _newCustomers.length});
      }
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(
          content: Text(done), backgroundColor: AppColors.green));
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(
          content: Text(trGlobal('common.error_detail', {'e': e})),
          backgroundColor: AppColors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    // Each chip shows the header exactly as the file must spell it —
    // the importer matches English header names — and, in any other
    // language, what the column means beside it.
    (String, String, bool) col(String header, String key, bool required) =>
        (header, trGlobal(key), required);
    // The tax-number column takes the local name where the importer
    // knows it (GSTIN, TRN, VAT number…), and "Tax ID" otherwise.
    final taxIdNorm =
        activeTaxIdLabel.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final taxIdHeader = customerColumns['taxid']!.contains(taxIdNorm)
        ? activeTaxIdLabel
        : 'Tax ID';
    final columns = _products
        ? <(String, String, bool)>[
            col('Name', 'csv.col_name', true),
            col('Price', 'csv.col_price', true),
            col('Tax %', 'csv.col_tax', false),
            col('Unit', 'csv.col_unit', false),
            col('Code', 'csv.col_code', false),
            col('Cost', 'csv.col_cost', false),
            col('Stock', 'csv.col_stock', false),
            col('Low stock at', 'csv.col_low', false),
          ]
        : <(String, String, bool)>[
            col('Name', 'csv.col_name', true),
            col('Phone', 'csv.col_phone', false),
            col('Email', 'csv.col_email', false),
            col('Address', 'csv.col_address', false),
            col('City', 'csv.col_city', false),
            col('State', 'csv.col_state', false),
            (taxIdHeader, activeTaxIdLabel, false),
          ];
    final example = _products
        ? 'Name,Price,Tax %,Unit,Code,Cost,Stock\n'
            'Sugar 1kg,48,5,Kg,1701,42,20\n'
            'Notebook A5,30,12,Nos,4820,22,\n'
            'Phone repair,250,18,Nos,,,'
        : 'Name,Phone,Email,Address,City\n'
            'Ravi Kumar,+91 98765 43210,ravi@mail.com,12 Main Road,Coimbatore\n'
            'Asha Traders,+254 712 345678,,Market St,Nairobi';

    return Container(
      constraints: BoxConstraints(maxHeight: h * 0.92),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(99))),
              ),
              const Gap(16),
              Row(children: [
                AppAvatar(icon: Symbols.table_view, size: 44),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          _products
                              ? trGlobal('csv.products_title')
                              : trGlobal('csv.customers_title'),
                          style: AppFont.sans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.t1)),
                      const Gap(2),
                      Text(trGlobal('csv.sub'),
                          style:
                              AppFont.sans(fontSize: 12.5, color: AppColors.t3)),
                    ],
                  ),
                ),
              ]),
              const Gap(18),

              // ── The format ─────────────────────────────────────
              Text(trGlobal('csv.columns').toUpperCase(),
                  style: AppFont.sans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.t3)),
              const Gap(8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final (header, meaning, required) in columns)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: required ? AppColors.brandSoft : AppColors.inset,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                          color: required
                              ? AppColors.brand.withValues(alpha: 0.4)
                              : AppColors.border),
                    ),
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(text: required ? '$header *' : header),
                        if (meaning.toLowerCase() != header.toLowerCase())
                          TextSpan(
                              text: '  $meaning',
                              style: AppFont.sans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.t3)),
                      ]),
                      style: AppFont.sans(
                          fontSize: 12,
                          fontWeight:
                              required ? FontWeight.w700 : FontWeight.w500,
                          color: required ? AppColors.brand : AppColors.t2),
                    ),
                  ),
              ]),
              const Gap(10),
              Text(
                  _products
                      ? trGlobal('csv.note_products')
                      : trGlobal('csv.note_customers'),
                  style: AppFont.sans(
                      fontSize: 12.5, color: AppColors.t2, height: 1.45)),
              const Gap(12),
              Text(trGlobal('csv.example').toUpperCase(),
                  style: AppFont.sans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.t3)),
              const Gap(6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.inset,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(example,
                      // Left-to-right whatever the app language: it is
                      // the literal file content.
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.5,
                          color: AppColors.t1)),
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: example));
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(trGlobal('csv.copied'))));
                  },
                  icon: Icon(Symbols.content_copy,
                      size: 15, color: AppColors.brand),
                  label: Text(trGlobal('csv.copy_example'),
                      style: AppFont.sans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brand)),
                ),
              ),
              const Gap(4),

              // ── The file ───────────────────────────────────────
              AppButton.outline(
                label: _fileName == null
                    ? trGlobal('csv.choose')
                    : trGlobal('csv.choose_other'),
                icon: Symbols.upload_file,
                busy: _busy && !_read,
                onPressed: _busy ? null : _pick,
              ),
              if (_problem != null) ...[
                const Gap(12),
                _Notice(
                    icon: Symbols.error,
                    tone: AppColors.red,
                    text: _problem!),
              ],
              if (_read) ...[
                const Gap(14),
                if (_fileName != null)
                  Text(_fileName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFont.sans(
                          fontSize: 12, color: AppColors.t3)),
                const Gap(8),
                _Notice(
                  icon: Symbols.check_circle,
                  tone: AppColors.green,
                  text: _products
                      ? trGlobal('csv.found_products', {
                          'n': _newProducts.length,
                          'c': _newCatalog.length,
                        })
                      : trGlobal('csv.found_customers',
                          {'n': _newCustomers.length}),
                ),
                if (_skipped > 0) ...[
                  const Gap(8),
                  _Notice(
                      icon: Symbols.info,
                      tone: AppColors.t3,
                      text: trGlobal('csv.skipped', {'n': _skipped})),
                ],
                if (_errors.isNotEmpty) ...[
                  const Gap(8),
                  _Notice(
                    icon: Symbols.warning,
                    tone: AppColors.orange,
                    text: [
                      trGlobal('csv.bad_rows', {'n': _errors.length}),
                      for (final e in _errors.take(6))
                        trGlobal('csv.line', {
                          'line': e.line,
                          'reason': trGlobal(e.reason),
                        }),
                      if (_errors.length > 6) '…',
                    ].join('\n'),
                  ),
                ],
                const Gap(16),
                AppButton(
                  label: trGlobal('csv.import_n', {
                    'n': _products
                        ? (_newProducts.length > _newCatalog.length
                            ? _newProducts.length
                            : _newCatalog.length)
                        : _newCustomers.length,
                  }),
                  icon: Symbols.check,
                  busy: _busy,
                  onPressed: (_busy ||
                          (_products
                              ? _newProducts.isEmpty && _newCatalog.isEmpty
                              : _newCustomers.isEmpty))
                      ? null
                      : _import,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final Color tone;
  final String text;
  const _Notice({required this.icon, required this.tone, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tone.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tone.withValues(alpha: 0.25)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 17, color: tone),
          const Gap(8),
          Expanded(
            child: Text(text,
                style: AppFont.sans(
                    fontSize: 12.5, color: AppColors.t1, height: 1.45)),
          ),
        ]),
      );
}

/// The small button in a list screen's app bar that opens the sheet.
class CsvImportButton extends StatelessWidget {
  final CsvImportKind kind;
  const CsvImportButton(this.kind, {super.key});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: trGlobal('csv.import_tooltip'),
        child: AppIconButton(
          icon: Symbols.upload_file,
          onTap: () => showCsvImport(context, kind),
        ),
      );
}
