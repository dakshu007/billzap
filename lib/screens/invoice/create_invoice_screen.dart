// lib/screens/invoice/create_invoice_screen.dart
// FIX: "From Catalog" reads from CatalogService (Hive 'catalog' box), not productProvider
// Fully translated
// GST auto-classify on item name change
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/smart_amount.dart';
import 'package:billzap/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../design/components.dart';
import '../../design/motion.dart';
import '../../design/money.dart';
import '../../design/tokens.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../services/gst_classifier.dart';
import '../../utils/voice_parser.dart';
import '../../i18n/translations.dart';
import '../main/catalog_screen.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});
  @override
  ConsumerState<CreateInvoiceScreen> createState() => _CreateState();
}

class _CreateState extends ConsumerState<CreateInvoiceScreen> {
  final _custName  = TextEditingController();
  final _custPhone = TextEditingController();
  final _custGstin = TextEditingController();
  final _custAddr  = TextEditingController();
  final _notes     = TextEditingController();
  // Backed by controllers so the fields keep their value when a toggle
  // hides and re-shows them, instead of silently reverting to 0 while
  // the total still counted the old figure.
  final _discountCtrl = TextEditingController();
  final _shippingCtrl = TextEditingController();

  DateTime _date = DateTime.now();
  DateTime _due  = DateTime.now().add(const Duration(days: 30));
  GstType  _gstType = GstType.cgstSgst;
  // Defaulted from the business profile in initState — see _defaultPlace.
  String _place = kStates.first;

  bool _applyGst      = true;
  bool _applyDiscount = false;
  bool _applyShipping = false;
  double _discount    = 0;
  double _shipping    = 0;

  final List<_LineItem> _lines = [_LineItem()];
  bool _saving = false;

  // Autocomplete
  List<Customer> _acSugg = [];
  bool _acShow = false;

  @override
  void initState() {
    super.initState();
    _defaultPlaceOfSupply();

    // Prefill from voice if present
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouterState.of(context).extra;
      if (extra is ParsedInvoice) _applyVoiceData(extra);
    });

    _custName.addListener(_onNameChanged);
  }

  /// Seed place of supply from the seller's own state.
  ///
  /// It used to default to `kStates.first` (Andhra Pradesh), which is
  /// wrong for every shop outside that state — and place of supply is
  /// what decides CGST/SGST against IGST, so the wrong default silently
  /// produced the wrong tax split on the first bill of every session.
  void _defaultPlaceOfSupply() {
    final biz = ref.read(businessProvider);
    final code = biz?.stateCode.trim() ?? '';
    final name = biz?.state.trim() ?? '';

    final match = kStates.firstWhere(
      (s) =>
          (code.isNotEmpty && s.endsWith('($code)')) ||
          (name.isNotEmpty && s.startsWith(name)),
      orElse: () => '',
    );
    if (match.isNotEmpty) _place = match;
  }

  @override
  void dispose() {
    _custName.removeListener(_onNameChanged);
    _custName.dispose(); _custPhone.dispose();
    _custGstin.dispose(); _custAddr.dispose(); _notes.dispose();
    _discountCtrl.dispose(); _shippingCtrl.dispose();
    super.dispose();
  }


  void _applyVoiceData(ParsedInvoice voice) {
    if (voice.customerName != null && voice.customerName!.isNotEmpty) {
      _custName.text = voice.customerName!;
    }
    if (voice.items.isNotEmpty) {
      setState(() {
        _lines.clear();
        for (final pi in voice.items) {
          final detectedGst = GstClassifier.classify(pi.name);
          _lines.add(_LineItem(
            name: pi.name,
            qty: pi.qty,
            rate: pi.price,
            gstRate: detectedGst >= 0 ? detectedGst.toDouble() : 18.0,
          ));
        }
      });
    }
  }

  void _onNameChanged() {
    final q = _custName.text.toLowerCase().trim();
    if (q.isEmpty) { setState(() { _acSugg = []; _acShow = false; }); return; }
    final matches = ref.read(customerProvider)
      .where((c) => c.name.toLowerCase().contains(q) || c.phone.contains(q))
      .take(5).toList();
    setState(() { _acSugg = matches; _acShow = matches.isNotEmpty; });
  }

  void _fillCust(Customer c) {
    _custName.removeListener(_onNameChanged);
    _custName.text  = c.name;
    _custPhone.text = c.phone;
    _custGstin.text = c.gstin;
    _custAddr.text  = c.address;
    _custName.addListener(_onNameChanged);
    setState(() { _acShow = false; });
  }

  // Calculated totals
  double get _sub => _lines.fold(0, (s, l) => s + l.qty * l.rate);
  double get _gstAmt => _applyGst ? _lines.fold(0, (s, l) => s + l.qty * l.rate * l.gstRate / 100) : 0;
  double get _cgst => _gstType == GstType.cgstSgst ? _gstAmt / 2 : 0;
  double get _sgst => _gstType == GstType.cgstSgst ? _gstAmt / 2 : 0;
  double get _igst => _gstType == GstType.igst ? _gstAmt : 0;
  double get _grand => _sub + _gstAmt + (_applyShipping ? _shipping : 0) - (_applyDiscount ? _discount : 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leadingWidth: 62,
        leading: Center(
          child: AppIconButton(
              icon: Symbols.close,
              size: 40,
              onTap: () => context.go('/home')),
        ),
        title: Text(tr('create.title', ref), style: AppFont.sans(
          fontSize: 21, fontWeight: FontWeight.w700,
          letterSpacing: -0.5, color: AppColors.t1)),
      ),
      bottomNavigationBar: _TotalBar(
        total: _grand,
        itemCount: _lines.where((l) => l.name.trim().isNotEmpty).length,
        saving: _saving,
        label: tr('create.grand_total', ref),
        saveLabel: tr('common.save', ref),
        onSave: _saving ? null : _save,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter, AppSpace.md, AppSpace.gutter, AppSpace.xl),
        children: [
          // ── Who ────────────────────────────────────────────────
          _Section(
            tr('cust.title', ref),
            subtitle: 'Who this bill is for',
            icon: Symbols.person,
            children: [
              Stack(clipBehavior: Clip.none, children: [
                AppField(
                  label: tr('cust.name', ref),
                  controller: _custName,
                  icon: Symbols.person,
                  hint: tr('create.search_customer', ref),
                  helper: 'Start typing to pull up a saved customer',
                  onChanged: (_) => setState(() {}),
                ),
                // The suggestion list hangs off the field rather than
                // pushing the form down, so the layout does not jump
                // under the thumb while typing.
                if (_acShow)
                  Positioned(
                    top: 74,
                    left: 0,
                    right: 0,
                    child: AppSurface(
                      padding: EdgeInsets.zero,
                      shadow: AppElevation.lifted,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _acSugg
                            .map((cust) => PressScale(
                                  onTap: () => _fillCust(cust),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpace.md,
                                        vertical: AppSpace.md),
                                    child: Row(children: [
                                      AppAvatar(label: cust.name, size: 34),
                                      const Gap(AppSpace.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(cust.name,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: AppFont.style(
                                                    AppType.labelM,
                                                    color: AppColor
                                                        .textPrimary)),
                                            if (cust.phone.isNotEmpty)
                                              Text(cust.phone,
                                                  style: AppFont.style(
                                                      AppType.bodyS,
                                                      color: AppColor
                                                          .textTertiary)),
                                          ],
                                        ),
                                      ),
                                      Icon(Symbols.arrow_forward,
                                          size: 15,
                                          color: AppColor.textTertiary),
                                    ]),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
              ]),
              const Gap(AppSpace.md),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: AppField(
                    label: tr('cust.phone', ref),
                    controller: _custPhone,
                    hint: '98765 43210',
                    keyboardType: TextInputType.phone,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const Gap(AppSpace.md),
                Expanded(
                  child: AppField(
                    label: tr('cust.gstin', ref),
                    controller: _custGstin,
                    hint: '33RAAAA...',
                    caps: true,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ]),
              const Gap(AppSpace.md),
              AppField(
                label: tr('cust.address', ref),
                controller: _custAddr,
                icon: Symbols.location_on,
                hint: 'Street, area, city',
                validatable: false,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),

          // ── When, and where the supply happens ─────────────────
          _Section(
            tr('create.invoice_details', ref),
            subtitle: 'Dates, and the state that sets the tax split',
            icon: Symbols.calendar_today,
            tone: AppColor.info,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: _DateBtn(tr('create.invoice_date', ref), _date,
                        (d) => setState(() => _date = d))),
                const Gap(AppSpace.md),
                Expanded(
                    child: _DateBtn(tr('create.due_date', ref), _due,
                        (d) => setState(() => _due = d))),
              ]),
              const Gap(AppSpace.md),
              _PlaceOfSupply(
                value: _place,
                intraState: _gstType == GstType.cgstSgst,
                onChanged: (v) => setState(() {
                  _place = v;
                  // Intra-state -> CGST+SGST, inter-state -> IGST.
                  final biz = ref.read(businessProvider);
                  final code = biz?.stateCode.trim() ?? '';
                  if (code.isNotEmpty) {
                    _gstType = _place.endsWith('($code)')
                        ? GstType.cgstSgst
                        : GstType.igst;
                  }
                }),
              ),
            ],
          ),

          // ── What is being sold ─────────────────────────────────
          _Section(
            tr('create.line_items', ref),
            subtitle: '${_lines.length} ${_lines.length == 1 ? "line" : "lines"} on this bill',
            icon: Symbols.inventory,
            tone: AppColor.pending,
            trailing: AppButton.ghost(
              label: tr('cat.from_catalog', ref),
              icon: Symbols.add,
              onPressed: _showCatalogPicker,
            ),
            children: [
              ..._lines.asMap().entries.map((e) => _LineRow(
                  item: e.value,
                  index: e.key,
                  onRemove: _lines.length > 1
                      ? () => setState(() => _lines.removeAt(e.key))
                      : null,
                  onChange: () => setState(() {}))),
              const Gap(AppSpace.sm),
              AppButton.outline(
                label: tr('create.add_line_item', ref),
                icon: Symbols.add,
                onPressed: () => setState(() => _lines.add(_LineItem())),
              ),
            ],
          ),

          // ── Tax and adjustments ────────────────────────────────
          _Section(
            tr('create.tax_adjustments', ref),
            subtitle: 'GST, discount and delivery',
            icon: Symbols.calculate,
            tone: AppColor.info,
            children: [
              _TogRow(tr('create.apply_gst', ref),
                  tr('create.gst_auto_calc', ref), _applyGst,
                  (v) => setState(() => _applyGst = v)),
              if (_applyGst) ...[
                const Gap(AppSpace.md),
                SegmentedTabs(
                  index: _gstType == GstType.cgstSgst ? 0 : 1,
                  onSelect: (i) => setState(() => _gstType =
                      i == 0 ? GstType.cgstSgst : GstType.igst),
                  labels: [
                    tr('create.cgst_sgst', ref),
                    tr('create.igst', ref),
                  ],
                ),
              ],
              Divider(height: 28, color: AppColor.hairline),
              _TogRow(tr('create.apply_discount', ref),
                  tr('create.flat_discount', ref), _applyDiscount,
                  (v) => setState(() => _applyDiscount = v)),
              if (_applyDiscount) ...[
                const Gap(AppSpace.md),
                AppField(
                  label: tr('create.discount', ref),
                  controller: _discountCtrl,
                  icon: Symbols.percent,
                  hint: '0',
                  suffix: '\u20B9',
                  validatable: false,
                  keyboardType: TextInputType.number,
                  onChanged: (v) =>
                      setState(() => _discount = double.tryParse(v) ?? 0),
                ),
              ],
              Divider(height: 28, color: AppColor.hairline),
              _TogRow(tr('create.add_shipping', ref),
                  tr('create.delivery_charges', ref), _applyShipping,
                  (v) => setState(() => _applyShipping = v)),
              if (_applyShipping) ...[
                const Gap(AppSpace.md),
                AppField(
                  label: tr('create.shipping', ref),
                  controller: _shippingCtrl,
                  icon: Symbols.local_shipping,
                  hint: '0',
                  suffix: '\u20B9',
                  validatable: false,
                  keyboardType: TextInputType.number,
                  onChanged: (v) =>
                      setState(() => _shipping = double.tryParse(v) ?? 0),
                ),
              ],
            ],
          ),

          // ── What it comes to ───────────────────────────────────
          _Section(
            tr('create.summary', ref),
            subtitle: 'What the customer pays',
            icon: Symbols.receipt_long,
            children: [
              _SRow(tr('create.subtotal', ref), _sub),
              if (_cgst > 0) _SRow('CGST', _cgst),
              if (_sgst > 0) _SRow('SGST', _sgst),
              if (_igst > 0) _SRow('IGST', _igst),
              if (_applyShipping && _shipping > 0)
                _SRow(tr('create.shipping', ref), _shipping),
              if (_applyDiscount && _discount > 0)
                _SRow(tr('create.discount', ref), -_discount),
              const Gap(AppSpace.md),
              // The grand total sits in a jade well, the same shape the
              // finished invoice uses for TOTAL DUE — so the number the
              // customer will see is already recognisable here.
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.lg, vertical: AppSpace.md),
                decoration: BoxDecoration(
                  color: AppColor.wash(AppColor.primary),
                  borderRadius: AppRadius.all(AppRadius.md),
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tr('create.grand_total', ref).toUpperCase(),
                          style: AppFont.style(AppType.labelS,
                              color: AppColor.primary)),
                      Money(_grand,
                          style: AppType.amountL,
                          compact: false,
                          color: AppColor.primary),
                    ]),
              ),
            ],
          ),

          // ── Anything else ──────────────────────────────────────
          _Section(
            tr('create.notes', ref),
            subtitle: 'Prints at the foot of the bill',
            icon: Symbols.edit,
            tone: AppColor.textTertiary,
            children: [
              AppField(
                label: tr('create.notes', ref),
                controller: _notes,
                hint: tr('create.notes_hint', ref),
                maxLines: 3,
                validatable: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════
  // BUG FIX #1: Read from CatalogService not productProvider!
  // ═════════════════════════════════════════════════
  Future<void> _showCatalogPicker() async {
    final items = await CatalogService.getAll();
    if (!mounted) return;

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(trGlobal('create.catalog_empty'))));
      return;
    }

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65, maxChildSize: 0.9, minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(color: AppColors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(children: [
            Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(99))),
            Text(trGlobal('cat.from_catalog'), style: AppFont.sans(fontSize: 17, fontWeight: FontWeight.w600)),
            const Gap(10),
            Expanded(child: ListView.builder(
              controller: ctrl, itemCount: items.length,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemBuilder: (_, i) {
                final p = items[i];
                return GestureDetector(
                  onTap: () {
                    setState(() => _lines.add(_LineItem(
                      name: p.name, hsn: p.hsnCode, rate: p.price, gstRate: p.gstRate.toDouble())));
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border)),
                    child: Row(children: [
                      Container(width: 40, height: 40,
                        decoration: BoxDecoration(color: AppColors.brandSoft,
                          borderRadius: BorderRadius.circular(14)),
                        child: Icon(Symbols.shopping_basket, color: AppColors.brand, size: 20)),
                      const Gap(12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.name, style: AppFont.sans(fontSize: 13.5, fontWeight: FontWeight.w700)),
                        if (p.hsnCode.isNotEmpty)
                          Text('HSN: ${p.hsnCode} \u00b7 ${p.unit}',
                            style: AppFont.sans(fontSize: 11, color: AppColors.t3)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(formatCurrency(p.price), style: AppFont.sans(
                          fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.brand)),
                        Text('GST ${p.gstRate}%', style: AppFont.sans(
                          fontSize: 11, color: AppColors.green, fontWeight: FontWeight.w600)),
                      ]),
                    ]),
                  ),
                );
              })),
          ]),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_custName.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(trGlobal('create.cust_required')), backgroundColor: AppColors.red));
      return;
    }
    final valid = _lines.where((l) => l.name.isNotEmpty).toList();
    if (valid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(trGlobal('create.add_item_required')), backgroundColor: AppColors.red));
      return;
    }
    setState(() => _saving = true);
    try {
      final db    = ref.read(storageProvider);
      final invNo = db.nextInvoiceNumber();
      final items = valid.map((l) => InvoiceItem(
        name: l.name, hsnCode: l.hsn, quantity: l.qty,
        rate: l.rate, gstRate: l.gstRate, applyGst: _applyGst)).toList();

      final inv = Invoice(
        invoiceNumber: invNo,
        customerName: _custName.text.trim(),
        customerPhone: _custPhone.text.trim(),
        customerGstin: _custGstin.text.trim().toUpperCase(),
        customerAddress: _custAddr.text.trim(),
        invoiceDate: _date, dueDate: _due,
        lineItems: items, gstType: _gstType,
        shippingCharge: _applyShipping ? _shipping : 0,
        flatDiscount: _applyDiscount ? _discount : 0,
        notes: _notes.text.trim(), placeOfSupply: _place,
        status: InvoiceStatus.sent);

      await ref.read(invoiceProvider.notifier).add(inv);

      // Auto-save new customer
      final custs = ref.read(customerProvider);
      final exists = custs.any((c) => c.name.toLowerCase() == inv.customerName.toLowerCase());
      if (!exists && inv.customerPhone.isNotEmpty) {
        await ref.read(customerProvider.notifier).add(Customer(
          name: inv.customerName, phone: inv.customerPhone,
          gstin: inv.customerGstin, address: inv.customerAddress));
      }

      if (!mounted) return;
      ref.read(selectedInvoiceProvider.notifier).select(inv);
      context.go('/preview');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Line item state ─────────────────────────────────────────────────────────
class _LineItem {
  String name; String hsn; double qty; double rate; double gstRate;
  _LineItem({this.name='', this.hsn='', this.qty=1, this.rate=0, this.gstRate=18});
}

class _LineRow extends StatefulWidget {
  final _LineItem item; final int index;
  final VoidCallback? onRemove; final VoidCallback onChange;
  const _LineRow({required this.item, required this.index, this.onRemove, required this.onChange});
  @override
  State<_LineRow> createState() => _LineRowState();
}
class _LineRowState extends State<_LineRow> {
  late final TextEditingController _name, _hsn, _rate;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item.name)
      ..addListener(_onNameTyped);
    _hsn  = TextEditingController(text: widget.item.hsn)
      ..addListener(() => widget.item.hsn = _hsn.text);
    _rate = TextEditingController(text: widget.item.rate > 0 ? widget.item.rate.toStringAsFixed(0) : '')
      ..addListener(() { widget.item.rate = double.tryParse(_rate.text) ?? 0; widget.onChange(); });
  }

  // ═════════════════════════════════════════════════
  // GST AUTO-CLASSIFY: as user types item name
  // ═════════════════════════════════════════════════
  void _onNameTyped() {
    widget.item.name = _name.text;
    final detected = GstClassifier.classify(_name.text);
    if (detected >= 0 && detected.toDouble() != widget.item.gstRate) {
      setState(() => widget.item.gstRate = detected.toDouble());
    }
    widget.onChange();
  }

  @override
  void dispose() { _name.dispose(); _hsn.dispose(); _rate.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border)),
    child: Column(children: [
      Row(children: [
        Expanded(child: TextField(controller: _name,
          decoration: InputDecoration(hintText: 'Product / service name',
            hintStyle: AppFont.sans(fontSize: 13, color: AppColors.t4), isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11)),
          style: AppFont.sans(fontSize: 13.5))),
        if (widget.onRemove != null) ...[
          const Gap(8),
          GestureDetector(onTap: widget.onRemove,
            child: Container(width: 32, height: 32,
              decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(12)),
              child: Icon(Symbols.delete, size: 16, color: AppColors.red))),
        ],
      ]),
      const Gap(8),
      Row(children: [
        Expanded(child: TextField(controller: _hsn,
          decoration: InputDecoration(hintText: 'HSN/SAC',
            hintStyle: AppFont.sans(fontSize: 12, color: AppColors.t4), isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10)),
          style: AppFont.sans(fontSize: 12.5, color: AppColors.t3))),
        const Gap(8),
        // Qty stepper
        _QtyBtn('\u2212', () { if (widget.item.qty > 1) { setState(() => widget.item.qty--); widget.onChange(); } }),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('${widget.item.qty.toInt()}',
            style: AppFont.sans(fontSize: 16, fontWeight: FontWeight.w700))),
        _QtyBtn('+', () { setState(() => widget.item.qty++); widget.onChange(); }),
        const Gap(8),
        SizedBox(width: 90, child: TextField(controller: _rate,
          keyboardType: TextInputType.number,
              inputFormatters: [SmartAmountFormatter()], textAlign: TextAlign.right,
          decoration: InputDecoration(hintText: 'Rate \u20b9',
            hintStyle: AppFont.sans(fontSize: 12, color: AppColors.t4), isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10)),
          style: AppFont.sans(fontSize: 13.5))),
      ]),
      const Gap(8),
      Row(children: [
        Text('GST: ', style: AppFont.sans(fontSize: 12, color: AppColors.t3)),
        Expanded(child: DropdownButton<double>(
          value: [0, 0.25, 5, 12, 18, 28, 40].map((e) => e.toDouble()).contains(widget.item.gstRate)
            ? widget.item.gstRate : 18.0,
          isExpanded: true,
          underline: const SizedBox(),
          style: AppFont.sans(fontSize: 12, color: AppColors.brand, fontWeight: FontWeight.w700),
          items: [
            (r: 0.0,   l: '0% — Exempt'),
            (r: 0.25,  l: '0.25% — Stones'),
            (r: 5.0,   l: '5% — Essentials'),
            (r: 12.0,  l: '12% — Standard'),
            (r: 18.0,  l: '18% — General'),
            (r: 28.0,  l: '28% — Luxury'),
            (r: 40.0,  l: '40% — Sin tax'),
          ].map((g) => DropdownMenuItem(
            value: g.r,
            child: Text(g.l, style: AppFont.sans(fontSize: 12, color: AppColors.t1)))).toList(),
          onChanged: (v) {
            if (v != null) { setState(() => widget.item.gstRate = v); widget.onChange(); }
          },
        )),
        const Gap(8),
        Text(formatCurrency(widget.item.qty * widget.item.rate), style: AppFont.sans(
          fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.brand)),
      ]),
    ]),
  );
}

Widget _QtyBtn(String label, VoidCallback onTap) => GestureDetector(
  onTap: onTap,
  child: Container(width: 28, height: 28,
    decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(7)),
    child: Center(child: Text(label, style: TextStyle(
      color: AppColors.onBrand, fontSize: 16, fontWeight: FontWeight.bold)))));

// ── Shared helpers ──────────────────────────────────────────────────────────
/// One step of the bill, on its own surface with a tinted mark.
///
/// Making a bill is five decisions — who, when, what, tax, note — and
/// the icons let a person scrolling back find the one they want by
/// shape, before reading a word of it.
class _Section extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? tone;
  final Widget? trailing;
  final List<Widget> children;

  const _Section(
    this.title, {
    required this.icon,
    this.subtitle,
    this.tone,
    this.trailing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final accent = tone ?? AppColor.primary;
    return AppSurface(
      margin: const EdgeInsets.only(bottom: AppSpace.lg),
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColor.wash(accent),
              borderRadius: AppRadius.all(AppRadius.sm),
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const Gap(AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: AppFont.style(AppType.labelL,
                        color: AppColor.textPrimary)),
                if (subtitle != null) ...[
                  const Gap(1),
                  Text(subtitle!,
                      style: AppFont.style(AppType.bodyS,
                          color: AppColor.textTertiary)),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ]),
        const Gap(AppSpace.lg),
        ...children,
      ]),
    );
  }
}

Widget _LF(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 5),
  child: Text(t, style: AppFont.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.t3)));

Widget _TextField(TextEditingController ctrl, String hint,
    {TextInputType? type, bool caps = false}) =>
  TextField(controller: ctrl, keyboardType: type,
    textCapitalization: caps ? TextCapitalization.characters : TextCapitalization.sentences,
    decoration: InputDecoration(hintText: hint,
      hintStyle: AppFont.sans(fontSize: 13, color: AppColors.t4),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.brand, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13)),
    style: AppFont.sans(fontSize: 13.5, color: AppColors.t1));

/// A date, in the same shape as a text field so the row reads as one
/// set of inputs rather than a field next to a button.
Widget _DateBtn(String label, DateTime date, ValueChanged<DateTime> onPick) =>
    Builder(
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: AppFont.style(AppType.labelS,
                  color: AppColor.textTertiary)),
          const Gap(AppSpace.xs),
          PressScale(
            onTap: () async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) onPick(picked);
            },
            child: Container(
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(
                color: AppColor.sunken,
                borderRadius: AppRadius.all(AppRadius.md),
                border: Border.all(color: AppColor.hairline),
              ),
              child: Row(children: [
                Icon(Symbols.calendar_today,
                    size: 17, color: AppColor.textTertiary),
                const Gap(AppSpace.md),
                Expanded(
                  child: Text(DateFormat('d MMM yyyy').format(date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFont.style(AppType.bodyL,
                          color: AppColor.textPrimary)),
                ),
              ]),
            ),
          ),
        ],
      ),
    );

Widget _TogRow(String label, String sub, bool value, ValueChanged<bool> onChange) =>
  GestureDetector(
    onTap: () => onChange(!value),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppFont.sans(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.t1)),
        Text(sub, style: AppFont.sans(fontSize: 11, color: AppColors.t3)),
      ])),
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48, height: 28,
        decoration: BoxDecoration(
          color: value ? AppColors.brand : AppColors.borderDark,
          borderRadius: BorderRadius.circular(99)),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(99),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4)]),
          )),
      ),
    ]));

Widget _TypeBtn(String label, bool selected, VoidCallback onTap) =>
  Expanded(child: GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: selected ? AppColors.brand : AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? AppColors.brand : AppColors.border)),
      child: Text(label, textAlign: TextAlign.center,
        style: AppFont.sans(fontSize: 12, fontWeight: FontWeight.w700,
          color: selected ? AppColors.onBrand : AppColors.t2)))));

Widget _SRow(String label, double amount) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: AppFont.style(AppType.bodyM, color: AppColor.textSecondary)),
        Money(amount,
            style: AppType.amountS,
            compact: false,
            color: amount < 0 ? AppColor.paid : AppColor.textPrimary),
      ]));


/// Persistent total + save bar.
///
/// The running total stays on screen for the whole of the form because
/// that is the number the shopkeeper and the customer at the counter are
/// both watching. It tweens rather than cutting, so adding a line reads
/// as the total climbing.
class _TotalBar extends StatelessWidget {
  final double total;
  final int itemCount;
  final bool saving;
  final String label, saveLabel;
  final VoidCallback? onSave;

  const _TotalBar({
    required this.total,
    required this.itemCount,
    required this.saving,
    required this.label,
    required this.saveLabel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(
          AppSpace.gutter,
          AppSpace.lg,
          AppSpace.gutter,
          MediaQuery.of(context).padding.bottom + AppSpace.lg,
        ),
        decoration: BoxDecoration(
          color: AppColor.surface,
          border: Border(top: BorderSide(color: AppColor.hairline)),
          boxShadow: AppElevation.lifted,
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${label.toUpperCase()} · $itemCount ${itemCount == 1 ? "item" : "items"}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFont.style(AppType.overline,
                      color: AppColor.textTertiary),
                ),
                const Gap(4),
                Money(total,
                    style: AppType.amountL, compact: false, animate: true),
              ],
            ),
          ),
          const Gap(AppSpace.lg),
          AppButton(
            label: saveLabel,
            icon: Symbols.check,
            expand: false,
            busy: saving,
            onPressed: onSave,
          ),
        ]),
      );
}

/// Place of supply.
///
/// This is the most consequential field on the form and the one people
/// skip, because it looks like a dropdown of state names. It decides
/// whether the bill charges CGST+SGST or IGST, and getting it wrong
/// means reissuing. So it says what it is about to do — "Same state,
/// CGST + SGST" — rather than only naming a state, and it opens a
/// searchable sheet instead of a 36-entry menu.
class _PlaceOfSupply extends StatelessWidget {
  final String value;
  final bool intraState;
  final ValueChanged<String> onChanged;

  const _PlaceOfSupply({
    required this.value,
    required this.intraState,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tone = intraState ? AppColor.primary : AppColor.info;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PLACE OF SUPPLY',
            style:
                AppFont.style(AppType.labelS, color: AppColor.textTertiary)),
        const Gap(AppSpace.xs),
        PressScale(
          onTap: () => _open(context),
          child: Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: AppColor.sunken,
              borderRadius: AppRadius.all(AppRadius.md),
              border: Border.all(color: AppColor.hairline),
            ),
            child: Row(children: [
              Icon(Symbols.location_city, size: 18, color: tone),
              const Gap(AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFont.style(AppType.bodyL,
                            color: AppColor.textPrimary)),
                    const Gap(1),
                    Text(
                        intraState
                            ? 'Same state · CGST + SGST'
                            : 'Other state · IGST',
                        style: AppFont.style(AppType.bodyS, color: tone)),
                  ],
                ),
              ),
              Icon(Symbols.expand_more, size: 18, color: AppColor.textTertiary),
            ]),
          ),
        ),
      ],
    );
  }

  void _open(BuildContext context) {
    final search = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) {
        final q = search.text.trim().toLowerCase();
        final list = kStates
            .where((s) => q.isEmpty || s.toLowerCase().contains(q))
            .toList();
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.78,
          decoration: BoxDecoration(
            color: AppColor.canvas,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
          ),
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(children: [
            const Gap(AppSpace.md),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColor.hairline,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.gutter, AppSpace.lg, AppSpace.gutter, AppSpace.sm),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Place of supply',
                          style: AppFont.style(AppType.titleS,
                              color: AppColor.textPrimary)),
                      Text('Sets the tax split on this bill',
                          style: AppFont.style(AppType.bodyS,
                              color: AppColor.textTertiary)),
                    ],
                  ),
                ),
                AppIconButton(
                    icon: Symbols.close, onTap: () => Navigator.pop(ctx)),
              ]),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
              child: AppSearchField(
                controller: search,
                hint: 'Search states',
                hasValue: q.isNotEmpty,
                onChanged: (_) => ss(() {}),
                onClear: () {
                  search.clear();
                  ss(() {});
                },
              ),
            ),
            const Gap(AppSpace.md),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                    AppSpace.gutter, 0, AppSpace.gutter, AppSpace.xxl),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final full = list[i];
                  final n = full.split(' (')[0];
                  final code = kStateMap[n] ?? '';
                  final on = full == value;
                  return AppListRow(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onChanged(full);
                      Navigator.pop(ctx);
                    },
                    leading: AppAvatar(
                      label: code.isEmpty ? n : code,
                      tone: on ? AppColor.primary : AppColor.textTertiary,
                      size: 38,
                    ),
                    title: n,
                    subtitle: code.isEmpty ? null : 'State code $code',
                    trailing: on
                        ? Icon(Symbols.check_circle,
                            size: 20, color: AppColor.primary)
                        : const SizedBox.shrink(),
                  );
                },
              ),
            ),
          ]),
        );
      }),
    );
  }
}
