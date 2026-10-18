// lib/screens/reports/export_reports_sheet.dart
// Bottom sheet that lets user export 4 report types as PDF or CSV.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:billzap/theme/app_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../i18n/dates.dart';
import '../../i18n/translations.dart';
import '../../providers/providers.dart';
import '../../utils/csv_helper.dart';
import '../../utils/report_csv_helper.dart';
import '../../utils/report_pdf_builder.dart';
import '../../utils/gstr1_builder.dart';

enum _ReportKind { monthlyRevenue, profitLoss, gstSummary, invoiceStatus }
enum _PeriodPreset { thisMonth, lastMonth, thisQuarter, thisYear, allTime, custom }

class ExportReportsSheet extends ConsumerStatefulWidget {
  const ExportReportsSheet({super.key});
  @override
  ConsumerState<ExportReportsSheet> createState() => _ExportReportsState();

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ExportReportsSheet(),
    );
  }
}

class _ExportReportsState extends ConsumerState<ExportReportsSheet> {
  _PeriodPreset _preset = _PeriodPreset.thisMonth;
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _setPreset(_PeriodPreset.thisMonth);
  }

  void _setPreset(_PeriodPreset p) {
    final now = DateTime.now();
    setState(() {
      _preset = p;
      switch (p) {
        case _PeriodPreset.thisMonth:
          _from = DateTime(now.year, now.month, 1);
          _to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          break;
        case _PeriodPreset.lastMonth:
          _from = DateTime(now.year, now.month - 1, 1);
          _to = DateTime(now.year, now.month, 0, 23, 59, 59);
          break;
        case _PeriodPreset.thisQuarter:
          final qStart = ((now.month - 1) ~/ 3) * 3 + 1;
          _from = DateTime(now.year, qStart, 1);
          _to = DateTime(now.year, qStart + 3, 0, 23, 59, 59);
          break;
        case _PeriodPreset.thisYear:
          _from = DateTime(now.year, 1, 1);
          _to = DateTime(now.year, 12, 31, 23, 59, 59);
          break;
        case _PeriodPreset.allTime:
          _from = DateTime(2000);
          _to = DateTime(now.year + 5);
          break;
        case _PeriodPreset.custom:
          // Keep current values; user picks via dialog
          break;
      }
    });
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _from, end: _to),
      builder: (ctx, child) {
        // Inherit the active theme (light or dark) so the date-range
        // picker doesn't snap back to a hardcoded light scheme.
        final base = Theme.of(ctx);
        return Theme(
          data: base.copyWith(
            colorScheme: base.colorScheme.copyWith(
              primary: AppColors.brand,
              onPrimary: Colors.white,
              surface: AppColors.card,
              onSurface: AppColors.t1,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _preset = _PeriodPreset.custom;
        _from = picked.start;
        _to = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // EXPORT HANDLERS
  // ═══════════════════════════════════════════════════════════════

  Future<void> _exportPdf(_ReportKind kind) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final invs = ref.read(invoiceProvider);
      final exps = ref.read(expenseProvider);
      final biz = ref.read(businessProvider);

      late final dynamic doc;
      late final String filename;

      switch (kind) {
        case _ReportKind.monthlyRevenue:
          doc = await ReportPdfBuilder.buildMonthlyRevenue(
            invoices: invs, from: _from, to: _to, biz: biz);
          filename = 'BillZap_Revenue_${_stamp()}.pdf';
          break;
        case _ReportKind.profitLoss:
          doc = await ReportPdfBuilder.buildProfitLoss(
            invoices: invs, expenses: exps, from: _from, to: _to, biz: biz);
          filename = 'BillZap_PL_${_stamp()}.pdf';
          break;
        case _ReportKind.gstSummary:
          doc = await ReportPdfBuilder.buildGstSummary(
            invoices: invs, from: _from, to: _to, biz: biz);
          filename = 'BillZap_GST_${_stamp()}.pdf';
          break;
        case _ReportKind.invoiceStatus:
          doc = await ReportPdfBuilder.buildInvoiceStatus(
            invoices: invs, from: _from, to: _to, biz: biz);
          filename = 'BillZap_InvoiceStatus_${_stamp()}.pdf';
          break;
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(await doc.save());
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: trGlobal('ex.subject'),
      );
      _toast(trGlobal('ex.exported', {'file': filename}), AppColors.green);
    } catch (e) {
      _toast(trGlobal('ex.failed', {'e': e}), AppColors.red);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportCsv(_ReportKind kind) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final invs = ref.read(invoiceProvider);
      final exps = ref.read(expenseProvider);

      String content;
      String filename;

      switch (kind) {
        case _ReportKind.monthlyRevenue:
          content = ReportCsvHelper.monthlyRevenueToCsv(invs, _from, _to);
          filename = 'BillZap_Revenue_${_stamp()}.csv';
          break;
        case _ReportKind.profitLoss:
          content = ReportCsvHelper.profitLossToCsv(invs, exps, _from, _to);
          filename = 'BillZap_PL_${_stamp()}.csv';
          break;
        case _ReportKind.gstSummary:
          // Filter invoices by date range first, then use existing helper
          final filtered = invs.where((i) =>
            !i.invoiceDate.isBefore(_from) && !i.invoiceDate.isAfter(_to)
          ).toList();
          content = CsvHelper.gstSummaryToCsv(filtered);
          filename = 'BillZap_GST_${_stamp()}.csv';
          break;
        case _ReportKind.invoiceStatus:
          content = ReportCsvHelper.invoiceStatusToCsv(invs, _from, _to);
          filename = 'BillZap_InvoiceStatus_${_stamp()}.csv';
          break;
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(content);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: trGlobal('ex.subject'),
      );
      _toast(trGlobal('ex.exported', {'file': filename}), AppColors.green);
    } catch (e) {
      _toast(trGlobal('ex.failed', {'e': e}), AppColors.red);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportGstr1Json() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final biz  = ref.read(businessProvider);
      final invs = ref.read(invoiceProvider);
      final json = Gstr1Builder.build(
        invoices: invs, from: _from, to: _to, biz: biz);
      final dir = await getApplicationDocumentsDirectory();
      final filename =
          'BillZap_GSTR1_${DateFormat('MMyyyy').format(_from)}.json';
      final file = File('${dir.path}/$filename');
      await file.writeAsString(json);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'GSTR-1 JSON — ${DateFormat('MMM yyyy').format(_from)}');
      _toast(trGlobal('ex.gstr1_ready'), AppColors.green);
    } catch (e) {
      _toast(trGlobal('ex.gstr1_failed', {'e': e}), AppColors.red);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating));
  }

  String _stamp() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  String _periodLabel(_PeriodPreset p) {
    switch (p) {
      case _PeriodPreset.thisMonth: return trGlobal('rep.this_month');
      case _PeriodPreset.lastMonth: return trGlobal('rep.last_month');
      case _PeriodPreset.thisQuarter: return trGlobal('ex.this_quarter');
      case _PeriodPreset.thisYear: return trGlobal('rep.this_year');
      case _PeriodPreset.allTime: return trGlobal('ex.all_time');
      case _PeriodPreset.custom: return trGlobal('ex.custom');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD UI
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    // GSTR-1 is an Indian filing and the only country-specific export
    // here. Everything else is a report any shop can read.
    final profile = ref.watch(taxProfileProvider);
    final india = profile.countryCode == 'IN';
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        // Theme-aware so the export sheet from the Reports page flips
        // with dark mode.
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(99))),
          const Gap(8),
          // Title bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(children: [
              Icon(Symbols.download, color: AppColors.brand, size: 22),
              const Gap(10),
              Text(trGlobal('ex.title'),
                style: AppFont.sans(
                  fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.t1)),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Symbols.close, color: AppColors.t2)),
            ]),
          ),
          const Divider(height: 1),
          // Body (scrollable)
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
              children: [
                // ──────── Date range section ────────
                Text(trGlobal('ex.period').toUpperCase(),
                  style: AppFont.sans(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: AppColors.t3, letterSpacing: 0.8)),
                const Gap(8),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: [
                    for (final p in _PeriodPreset.values)
                      _PeriodChip(
                        label: _periodLabel(p),
                        selected: _preset == p,
                        onTap: () {
                          if (p == _PeriodPreset.custom) {
                            _pickCustomRange();
                          } else {
                            _setPreset(p);
                          }
                        },
                      ),
                  ],
                ),
                const Gap(8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Icon(Symbols.event, size: 16, color: AppColors.brand),
                    const Gap(8),
                    Text(
                      '${uiDate('dd MMM y', _from)} → '
                      '${_preset == _PeriodPreset.allTime ? trGlobal('ex.present') : uiDate('dd MMM y', _to)}',
                      style: AppFont.sans(
                        fontSize: 12.5, fontWeight: FontWeight.w700,
                        color: AppColors.brand)),
                  ]),
                ),
                const Gap(20),

                // ──────── Reports ────────
                Text(trGlobal('ex.reports').toUpperCase(),
                  style: AppFont.sans(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: AppColors.t3, letterSpacing: 0.8)),
                const Gap(8),

                _ReportRow(
                  icon: Symbols.trending_up,
                  iconColor: AppColors.brand,
                  title: trGlobal('rep.monthly_revenue'),
                  subtitle: trGlobal('ex.revenue_sub'),
                  busy: _busy,
                  onPdf: () => _exportPdf(_ReportKind.monthlyRevenue),
                  onCsv: () => _exportCsv(_ReportKind.monthlyRevenue),
                ),
                const Gap(10),
                _ReportRow(
                  icon: Symbols.account_balance_wallet,
                  iconColor: AppColors.green,
                  title: trGlobal('rep.profit_loss'),
                  subtitle: trGlobal('ex.pl_sub'),
                  busy: _busy,
                  onPdf: () => _exportPdf(_ReportKind.profitLoss),
                  onCsv: () => _exportCsv(_ReportKind.profitLoss),
                ),
                const Gap(10),
                _ReportRow(
                  icon: Symbols.calculate,
                  iconColor: AppColors.purple,
                  title: trGlobal('rep.gst_summary'),
                  subtitle: india
                      ? trGlobal('ex.tax_sub_in')
                      : trGlobal('ex.tax_sub'),
                  busy: _busy,
                  onPdf: () => _exportPdf(_ReportKind.gstSummary),
                  onCsv: () => _exportCsv(_ReportKind.gstSummary),
                  // The JSON export is the GST offline-utility schema,
                  // which exists in India and nowhere else. Offering it
                  // to a Kenyan shopkeeper would produce a file no
                  // authority on earth accepts, so it is not offered.
                  onJson: india ? _exportGstr1Json : null,
                  jsonLabel: india ? 'GSTR-1 JSON' : null,
                ),
                const Gap(10),
                _ReportRow(
                  icon: Symbols.fact_check,
                  iconColor: AppColors.orange,
                  title: trGlobal('rep.invoice_status'),
                  subtitle: trGlobal('ex.status_sub'),
                  busy: _busy,
                  onPdf: () => _exportPdf(_ReportKind.invoiceStatus),
                  onCsv: () => _exportCsv(_ReportKind.invoiceStatus),
                ),

                const Gap(16),
                // Tip
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.yellowSoft,
                    borderRadius: BorderRadius.circular(14)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Symbols.lightbulb, size: 16, color: AppColors.orange),
                    const Gap(8),
                    Expanded(child: Text(
                      trGlobal('ex.tip'),
                      style: AppFont.sans(
                        fontSize: 11.5, color: AppColors.t2, height: 1.4))),
                  ]),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SUB-WIDGETS
// ═══════════════════════════════════════════════════════════════
class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PeriodChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand : AppColors.bg,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.border)),
        child: Text(label,
          style: AppFont.sans(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: selected ? AppColors.onBrand : AppColors.t2)),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool busy;
  final VoidCallback onPdf;
  final VoidCallback onCsv;
  // Optional third action — currently used by the GST Summary row to
  // expose the GSTR-1 JSON export. Hidden when not supplied.
  final VoidCallback? onJson;
  final String? jsonLabel;

  const _ReportRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.busy,
    required this.onPdf,
    required this.onCsv,
    this.onJson,
    this.jsonLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: iconColor, size: 20)),
          const Gap(11),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                style: AppFont.sans(
                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.t1)),
              Text(subtitle,
                style: AppFont.sans(
                  fontSize: 11.5, color: AppColors.t3, height: 1.3)),
            ])),
        ]),
        const Gap(10),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: busy ? null : onPdf,
            icon: Icon(Symbols.picture_as_pdf, size: 16, color: AppColors.brand),
            label: Text('PDF',
              style: AppFont.sans(
                fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.brand)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 9),
              side: BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          )),
          const Gap(8),
          Expanded(child: OutlinedButton.icon(
            onPressed: busy ? null : onCsv,
            icon: Icon(Symbols.table_view, size: 16, color: AppColors.green),
            label: Text('CSV',
              style: AppFont.sans(
                fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.green)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 9),
              side: BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          )),
        ]),
        // GSTR-1 JSON action — full-width second row, only when supplied.
        if (onJson != null) ...[
          const Gap(8),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: busy ? null : onJson,
            icon: Icon(Symbols.data_object, size: 16, color: AppColors.purple),
            label: Text(jsonLabel ?? 'JSON',
              style: AppFont.sans(
                fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.purple)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 9),
              side: BorderSide(color: AppColors.purple.withOpacity(0.35)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          )),
        ],
      ]),
    );
  }
}
