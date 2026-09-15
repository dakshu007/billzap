// lib/screens/main/reports_screen.dart
//
// Reports. Same figures as before — six-month revenue, GST split, P&L,
// invoice status mix and top customers — redrawn in the clean language:
// white panels, ink bars, inset tracks, no coloured backgrounds except
// where a number's meaning depends on it.
import 'package:flutter/material.dart';
import 'package:billzap/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_spacing.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../i18n/translations.dart';
import '../../utils/platform.dart';
import '../../widgets/ui_kit.dart';
import '../reports/export_reports_sheet.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invs = ref.watch(invoiceProvider);
    final exps = ref.watch(expenseProvider);
    final now  = DateTime.now();
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    final last6months = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - 5 + i);
      return [d.month, d.year, months[d.month - 1]];
    });

    final vals = last6months.map((l) => invs
      .where((i) => i.status == InvoiceStatus.paid &&
        i.invoiceDate.month == (l[0] as int) && i.invoiceDate.year == (l[1] as int))
      .fold<double>(0, (s, i) => s + i.grandTotal)).toList();

    final maxV = vals.isEmpty ? 1.0 : vals.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);

    final paidInvs = invs.where((i) => i.status == InvoiceStatus.paid);
    final cgst = paidInvs.fold<double>(0, (s, i) => s + i.totalCgst);
    final sgst = paidInvs.fold<double>(0, (s, i) => s + i.totalSgst);
    final igst = paidInvs.fold<double>(0, (s, i) => s + i.totalIgst);
    final rev  = paidInvs.fold<double>(0, (s, i) => s + i.grandTotal);
    final expTot = exps.fold<double>(0, (s, e) => s + e.amount);

    // Top customers
    final custMap = <String, double>{};
    for (final i in paidInvs) {
      custMap[i.customerName] = (custMap[i.customerName] ?? 0) + i.grandTotal;
    }
    final topCusts = custMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.bg,
        toolbarHeight: 66,
        titleSpacing: AppSpacing.screenH,
        title: Text(tr('rep.title', ref), style: AppFont.sans(
          fontSize: 24, fontWeight: FontWeight.w700,
          letterSpacing: -0.6, color: AppColors.t1)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.screenH),
            child: AppPill('Export',
              icon: Symbols.download,
              selected: true,
              onTap: () => ExportReportsSheet.show(context)),
          ),
        ],
      ),
      body: DesktopMaxWidth(child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, 6, AppSpacing.screenH, AppSpacing.bottomNavSafe),
        children: [
          // ─── Revenue chart ──────────────────────────────────────────
          _Panel(tr('rep.monthly_revenue', ref), child: SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(6, (i) {
                final current = i == 5;
                return Expanded(child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: (vals[i] / maxV * 116).clamp(6.0, 116.0),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: current ? AppColors.brand : AppColors.inset,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                    ),
                    const Gap(8),
                    Text(
                      last6months[i][2] as String,
                      style: AppFont.sans(
                        fontSize: 11,
                        fontWeight: current ? FontWeight.w600 : FontWeight.w500,
                        color: current ? AppColors.t1 : AppColors.t3,
                      ),
                    ),
                  ],
                ));
              }),
            ),
          )),
          const Gap(AppSpacing.cardGap),

          // ─── GST summary ────────────────────────────────────────────
          _Panel(tr('rep.gst_summary', ref), child: Column(children: [
            Row(children: [
              _GBox('CGST', cgst, AppColors.t2),
              const Gap(9),
              _GBox('SGST', sgst, AppColors.t2),
              const Gap(9),
              _GBox('IGST', igst, AppColors.t2),
            ]),
            const Gap(14),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(tr('rep.total_gst_payable', ref),
                    style: AppFont.sans(
                      fontSize: 13.5, fontWeight: FontWeight.w500,
                      color: AppColors.onBrand.withOpacity(0.7)))),
                  const Gap(10),
                  Text(formatCurrency(cgst + sgst + igst),
                    style: AppFont.sans(
                      fontSize: 19, fontWeight: FontWeight.w700,
                      letterSpacing: -0.5, color: AppColors.onBrand)),
                ])),
          ])),
          const Gap(AppSpacing.cardGap),

          // ─── P&L ────────────────────────────────────────────────────
          _Panel(tr('rep.profit_loss', ref), child: Column(children: [
            _PLRow(tr('rep.total_revenue', ref), rev, AppColors.green),
            _PLRow(tr('rep.total_expenses', ref), expTot, AppColors.red),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: AppColors.border)),
            _PLRow(tr('rep.net_profit', ref), rev - expTot,
              rev - expTot >= 0 ? AppColors.green : AppColors.red, bold: true),
          ])),
          const Gap(AppSpacing.cardGap),

          // ─── Invoice status mix ─────────────────────────────────────
          _Panel(tr('rep.invoice_status', ref), child: Column(children: [
            _StatusRow(
              label: tr('inv.paid', ref), color: AppColors.green,
              count: invs.where((i) =>
                i.status == InvoiceStatus.paid && !i.isOverdue).length,
              total: invs.length),
            _StatusRow(
              label: tr('inv.sent', ref), color: AppColors.blue,
              count: invs.where((i) =>
                i.status == InvoiceStatus.sent && !i.isOverdue).length,
              total: invs.length),
            _StatusRow(
              label: tr('inv.pending', ref), color: AppColors.yellow,
              count: invs.where((i) =>
                i.status == InvoiceStatus.pending && !i.isOverdue).length,
              total: invs.length),
            _StatusRow(
              label: tr('inv.overdue', ref), color: AppColors.red,
              count: invs.where((i) => i.isOverdue).length,
              total: invs.length, last: true),
          ])),
          const Gap(AppSpacing.cardGap),

          // ─── Top customers ──────────────────────────────────────────
          if (topCusts.isNotEmpty)
            _Panel(tr('rep.top_customers', ref), child: Builder(builder: (_) {
              final maxVal = topCusts.first.value;
              final rows = topCusts.take(5).toList();
              return Column(children: [
                for (var i = 0; i < rows.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == rows.length - 1 ? 0 : 16),
                    child: Row(children: [
                      AppBadge(initial: rows[i].key, size: 38),
                      const Gap(12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rows[i].key,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: AppFont.sans(
                              fontSize: 13.5, fontWeight: FontWeight.w600,
                              color: AppColors.t1)),
                          const Gap(6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: LinearProgressIndicator(
                              value: maxVal > 0
                                ? (rows[i].value / maxVal).clamp(0.0, 1.0) : 0,
                              backgroundColor: AppColors.inset, minHeight: 6,
                              valueColor:
                                AlwaysStoppedAnimation(AppColors.brand))),
                        ])),
                      const Gap(12),
                      Text(formatCurrency(rows[i].value),
                        style: AppFont.sans(
                          fontSize: 13.5, fontWeight: FontWeight.w600,
                          letterSpacing: -0.2, color: AppColors.t1)),
                    ]),
                  ),
              ]);
            })),
        ],
      )),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  const _Panel(this.title, {required this.child});

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
            style: AppFont.sans(
              fontSize: 15.5, fontWeight: FontWeight.w600,
              letterSpacing: -0.3, color: AppColors.t1)),
          const Gap(16),
          child,
        ]),
      );
}

class _GBox extends StatelessWidget {
  final String label;
  final double value;
  final Color tone;
  const _GBox(this.label, this.value, this.tone);

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.inset,
      borderRadius: BorderRadius.circular(AppRadius.sm)),
    child: Column(children: [
      Text(label,
        style: AppFont.sans(
          fontSize: 10.5, fontWeight: FontWeight.w600,
          letterSpacing: 0.3, color: AppColors.t3)),
      const Gap(6),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(formatCurrency(value),
          maxLines: 1,
          style: AppFont.sans(
            fontSize: 14, fontWeight: FontWeight.w600,
            letterSpacing: -0.3, color: AppColors.t1)),
      ),
    ])));
}

class _StatusRow extends StatelessWidget {
  final String label;
  final Color color;
  final int count, total;
  final bool last;
  const _StatusRow({
    required this.label,
    required this.color,
    required this.count,
    required this.total,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: last ? 0 : 14),
    child: Row(children: [
      SizedBox(
        width: 78,
        child: AppPill(label, dense: true, tone: color)),
      const Gap(12),
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: LinearProgressIndicator(
          value: total == 0 ? 0 : count / total,
          backgroundColor: AppColors.inset, minHeight: 7,
          valueColor: AlwaysStoppedAnimation(color)))),
      const Gap(12),
      SizedBox(width: 26, child: Text('$count',
        style: AppFont.sans(
          fontSize: 15, fontWeight: FontWeight.w600,
          letterSpacing: -0.3, color: AppColors.t1),
        textAlign: TextAlign.right)),
    ]));
}

class _PLRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool bold;
  const _PLRow(this.label, this.value, this.color, {this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: AppFont.sans(
        fontSize: 13.5,
        fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
        color: bold ? AppColors.t1 : AppColors.t3)),
      Text(formatCurrency(value), style: AppFont.sans(
        fontSize: bold ? 19 : 14.5, fontWeight: FontWeight.w600,
        letterSpacing: -0.4, color: color)),
    ]));
}
