// lib/screens/reports/export_reports_sheet.dart
// Bottom sheet that lets user export 4 report types as PDF or CSV.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../utils/csv_helper.dart';
import '../../utils/report_csv_helper.dart';
import '../../utils/report_pdf_builder.dart';

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
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.brand,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppColors.t1,
          ),
        ),
        child: child!,
      ),
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
        subject: 'BillZap Report',
      );
      _toast('Exported $filename', AppColors.green);
    } catch (e) {
      _toast('Export failed: $e', AppColors.red);
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
        subject: 'BillZap Report',
      );
      _toast('Exported $filename', AppColors.green);
    } catch (e) {
      _toast('Export failed: $e', AppColors.red);
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
      case _PeriodPreset.thisMonth: return 'This Month';
      case _PeriodPreset.lastMonth: return 'Last Month';
      case _PeriodPreset.thisQuarter: return 'This Quarter';
      case _PeriodPreset.thisYear: return 'This Year';
      case _PeriodPreset.allTime: return 'All Time';
      case _PeriodPreset.custom: return 'Custom';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD UI
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
              const Icon(Symbols.download, color: AppColors.brand, size: 22),
              const Gap(10),
              Text('Export Reports',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.t1)),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Symbols.close, color: AppColors.t2)),
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
                Text('PERIOD',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, fontWeight: FontWeight.w800,
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
                    borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Icon(Symbols.event, size: 16, color: AppColors.brand),
                    const Gap(8),
                    Text(
                      '${DateFormat('dd MMM yyyy').format(_from)} → '
                      '${_preset == _PeriodPreset.allTime ? "Present" : DateFormat('dd MMM yyyy').format(_to)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5, fontWeight: FontWeight.w700,
                        color: AppColors.brand)),
                  ]),
                ),
                const Gap(20),

                // ──────── Reports ────────
                Text('REPORTS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, fontWeight: FontWeight.w800,
                    color: AppColors.t3, letterSpacing: 0.8)),
                const Gap(8),

                _ReportRow(
                  icon: Symbols.trending_up,
                  iconColor: AppColors.brand,
                  title: 'Monthly Revenue',
                  subtitle: 'Earnings, top customers, month-wise breakdown',
                  busy: _busy,
                  onPdf: () => _exportPdf(_ReportKind.monthlyRevenue),
                  onCsv: () => _exportCsv(_ReportKind.monthlyRevenue),
                ),
                const Gap(10),
                _ReportRow(
                  icon: Symbols.account_balance_wallet,
                  iconColor: AppColors.green,
                  title: 'Profit & Loss',
                  subtitle: 'Revenue − Expenses with category breakdown',
                  busy: _busy,
                  onPdf: () => _exportPdf(_ReportKind.profitLoss),
                  onCsv: () => _exportCsv(_ReportKind.profitLoss),
                ),
                const Gap(10),
                _ReportRow(
                  icon: Symbols.calculate,
                  iconColor: AppColors.purple,
                  title: 'GST Summary',
                  subtitle: 'CGST/SGST/IGST breakdown for GSTR-1 filing',
                  busy: _busy,
                  onPdf: () => _exportPdf(_ReportKind.gstSummary),
                  onCsv: () => _exportCsv(_ReportKind.gstSummary),
                ),
                const Gap(10),
                _ReportRow(
                  icon: Symbols.fact_check,
                  iconColor: AppColors.orange,
                  title: 'Invoice Status',
                  subtitle: 'Paid / Pending / Overdue + aging analysis',
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
                    borderRadius: BorderRadius.circular(10)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Symbols.lightbulb, size: 16, color: AppColors.orange),
                    const Gap(8),
                    Expanded(child: Text(
                      'PDFs are great for sharing and printing. CSVs work in Excel for further analysis.',
                      style: GoogleFonts.plusJakartaSans(
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
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.t2)),
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

  const _ReportRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.busy,
    required this.onPdf,
    required this.onCsv,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20)),
          const Gap(11),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.t1)),
              Text(subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5, color: AppColors.t3, height: 1.3)),
            ])),
        ]),
        const Gap(10),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: busy ? null : onPdf,
            icon: const Icon(Symbols.picture_as_pdf, size: 16, color: AppColors.brand),
            label: Text('PDF',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.brand)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 9),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          )),
          const Gap(8),
          Expanded(child: OutlinedButton.icon(
            onPressed: busy ? null : onCsv,
            icon: const Icon(Symbols.table_view, size: 16, color: AppColors.green),
            label: Text('CSV',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.green)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 9),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          )),
        ]),
      ]),
    );
  }
}
