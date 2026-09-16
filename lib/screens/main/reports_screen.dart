// lib/screens/main/reports_screen.dart
//
// Reports.
//
// A shop owner reads reports to answer three questions, so the screen is
// three blocks in that order: am I growing (revenue trend), what do I owe
// the government (GST), and did I actually make money (P&L). Customer and
// status breakdowns come after, because they are diagnostics rather than
// headlines.
//
// The revenue chart is deliberately bars, not a line: monthly totals are
// discrete buckets, and a line implies a continuous series between them.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:billzap/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/components.dart';
import '../../design/money.dart';
import '../../design/motion.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../i18n/translations.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/platform.dart';
import '../reports/export_reports_sheet.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = ref.watch(invoiceProvider);
    final expenses = ref.watch(expenseProvider);
    final now = DateTime.now();

    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final months = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - 5 + i);
      return (month: d.month, year: d.year, label: monthNames[d.month - 1]);
    });

    final paid = invoices.where((i) => i.status == InvoiceStatus.paid);

    final series = months
        .map((m) => paid
            .where((i) =>
                i.invoiceDate.month == m.month && i.invoiceDate.year == m.year)
            .fold<double>(0, (s, i) => s + i.grandTotal))
        .toList();
    final peak = series.isEmpty
        ? 1.0
        : series.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);

    final cgst = paid.fold<double>(0, (s, i) => s + i.totalCgst);
    final sgst = paid.fold<double>(0, (s, i) => s + i.totalSgst);
    final igst = paid.fold<double>(0, (s, i) => s + i.totalIgst);
    final revenue = paid.fold<double>(0, (s, i) => s + i.grandTotal);
    final spend = expenses.fold<double>(0, (s, e) => s + e.amount);
    final profit = revenue - spend;

    // Month-on-month movement, so the trend has a number attached to it
    // rather than only a shape.
    final thisMonth = series.isNotEmpty ? series.last : 0.0;
    final lastMonth = series.length > 1 ? series[series.length - 2] : 0.0;
    final delta = lastMonth > 0
        ? ((thisMonth - lastMonth) / lastMonth) * 100
        : (thisMonth > 0 ? 100.0 : 0.0);

    final byCustomer = <String, double>{};
    for (final i in paid) {
      byCustomer[i.customerName] =
          (byCustomer[i.customerName] ?? 0) + i.grandTotal;
    }
    final top = byCustomer.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: AppColor.canvas,
      body: DesktopMaxWidth(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0,
                AppSpace.gutter, AppSpace.navClearance),
            children: [
              ScreenTitle(
                tr('rep.title', ref),
                eyebrow: 'Last 6 months',
                padding: const EdgeInsets.fromLTRB(
                    0, AppSpace.lg, 0, AppSpace.lg),
                trailing: AppButton.outline(
                  label: 'Export',
                  icon: Symbols.download,
                  compact: true,
                  expand: false,
                  onPressed: () => ExportReportsSheet.show(context),
                ),
              ),

              Entrance(
                index: 0,
                child: _Panel(
                  title: tr('rep.monthly_revenue', ref),
                  trailing: _Delta(delta),
                  child: _RevenueChart(
                      series: series,
                      peak: peak,
                      labels: [for (final m in months) m.label]),
                ),
              ),
              const SizedBox(height: AppSpace.md),

              Entrance(
                index: 1,
                child: _Panel(
                  title: tr('rep.gst_summary', ref),
                  child: Column(children: [
                    Row(children: [
                      Expanded(child: _GstCell('CGST', cgst)),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(child: _GstCell('SGST', sgst)),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(child: _GstCell('IGST', igst)),
                    ]),
                    const SizedBox(height: AppSpace.lg),
                    // The number that actually has to be paid, given the
                    // weight it deserves.
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.lg, vertical: AppSpace.lg),
                      decoration: BoxDecoration(
                        color: AppColor.wash(AppColor.info),
                        borderRadius: AppRadius.all(AppRadius.md),
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Text(tr('rep.total_gst_payable', ref),
                              style: AppFont.style(AppType.labelM,
                                  color: AppColor.textSecondary)),
                        ),
                        Money(cgst + sgst + igst,
                            style: AppType.amountL,
                            color: AppColor.info,
                            round: true),
                      ]),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: AppSpace.md),

              Entrance(
                index: 2,
                child: _Panel(
                  title: tr('rep.profit_loss', ref),
                  child: Column(children: [
                    _Line(tr('rep.total_revenue', ref), revenue,
                        AppColor.paid),
                    _Line(tr('rep.total_expenses', ref), spend,
                        AppColor.overdue),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpace.md),
                      child: Divider(height: 1, color: AppColor.hairline),
                    ),
                    Row(children: [
                      Expanded(
                        child: Text(tr('rep.net_profit', ref),
                            style: AppFont.style(AppType.titleS,
                                color: AppColor.textPrimary)),
                      ),
                      Money(profit,
                          round: true,
                          style: AppType.amountL,
                          color: profit >= 0
                              ? AppColor.paid
                              : AppColor.overdue),
                    ]),
                  ]),
                ),
              ),
              const SizedBox(height: AppSpace.md),

              Entrance(
                index: 3,
                child: _Panel(
                  title: tr('rep.invoice_status', ref),
                  child: Column(children: [
                    _StatusBar(
                        label: tr('inv.paid', ref),
                        tone: AppColor.paid,
                        count: invoices
                            .where((i) =>
                                i.status == InvoiceStatus.paid && !i.isOverdue)
                            .length,
                        total: invoices.length),
                    _StatusBar(
                        label: tr('inv.sent', ref),
                        tone: AppColor.info,
                        count: invoices
                            .where((i) =>
                                i.status == InvoiceStatus.sent && !i.isOverdue)
                            .length,
                        total: invoices.length),
                    _StatusBar(
                        label: tr('inv.pending', ref),
                        tone: AppColor.pending,
                        count: invoices
                            .where((i) =>
                                i.status == InvoiceStatus.pending &&
                                !i.isOverdue)
                            .length,
                        total: invoices.length),
                    _StatusBar(
                        label: tr('inv.overdue', ref),
                        tone: AppColor.overdue,
                        count: invoices.where((i) => i.isOverdue).length,
                        total: invoices.length,
                        last: true),
                  ]),
                ),
              ),

              if (top.isNotEmpty) ...[
                const SizedBox(height: AppSpace.md),
                Entrance(
                  index: 4,
                  child: _Panel(
                    title: tr('rep.top_customers', ref),
                    child: Column(children: [
                      for (var i = 0; i < top.take(5).length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                              bottom: i == top.take(5).length - 1
                                  ? 0
                                  : AppSpace.lg),
                          child: Row(children: [
                            AppAvatar(label: top[i].key, size: 38),
                            const SizedBox(width: AppSpace.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(top[i].key,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppFont.style(AppType.labelM,
                                          color: AppColor.textPrimary)),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius:
                                        AppRadius.all(AppRadius.pill),
                                    child: LinearProgressIndicator(
                                      value: top.first.value > 0
                                          ? (top[i].value / top.first.value)
                                              .clamp(0.0, 1.0)
                                          : 0,
                                      minHeight: 6,
                                      backgroundColor: AppColor.sunken,
                                      valueColor: AlwaysStoppedAnimation(
                                          AppColor.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpace.md),
                            Money(top[i].value,
                                style: AppType.amountS, round: true),
                          ]),
                        ),
                    ]),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _Panel({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) => AppSurface(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(title,
                  style: AppFont.style(AppType.titleS,
                      color: AppColor.textPrimary)),
            ),
            if (trailing != null) trailing!,
          ]),
          const SizedBox(height: AppSpace.xl),
          child,
        ]),
      );
}

/// Month-on-month change, tinted by direction.
class _Delta extends StatelessWidget {
  final double percent;
  const _Delta(this.percent);

  @override
  Widget build(BuildContext context) {
    if (percent == 0) return const SizedBox.shrink();
    final up = percent > 0;
    final tone = up ? AppColor.paid : AppColor.overdue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColor.wash(tone),
        borderRadius: AppRadius.all(AppRadius.pill),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 13, color: tone),
        const SizedBox(width: 4),
        Text('${percent.abs().toStringAsFixed(0)}%',
            style: AppFont.style(AppType.labelS, color: tone)),
      ]),
    );
  }
}

/// The revenue chart.
///
/// Bars rather than a line: monthly totals are discrete buckets, and a
/// line implies a continuous series between them.
///
/// The animation is the point here. Bars grow from the baseline on a
/// stagger so the chart assembles left to right, each one easing out of
/// a slight overshoot so it settles rather than stopping dead. The
/// current month is jade; earlier months recede to the sunken tone so
/// the eye lands on "now" first. Touch any bar to read its exact value —
/// a chart you cannot interrogate is decoration.
class _RevenueChart extends StatefulWidget {
  final List<double> series;
  final List<String> labels;
  final double peak;

  const _RevenueChart({
    required this.series,
    required this.labels,
    required this.peak,
  });

  @override
  State<_RevenueChart> createState() => _RevenueChartState();
}

class _RevenueChartState extends State<_RevenueChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1150),
  );
  int? _touched;

  @override
  void initState() {
    super.initState();
    // A beat before it starts, so the card has landed and the growth is
    // something you watch rather than something already finished.
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void didUpdateWidget(_RevenueChart old) {
    super.didUpdateWidget(old);
    // Re-run when the underlying figures change (a bill gets paid).
    if (!listEquals(old.series, widget.series)) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const maxBar = 128.0;
    final n = widget.series.length;

    return SizedBox(
      height: 186,
      child: LayoutBuilder(
        builder: (context, box) {
          final slot = box.maxWidth / n;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) {
              final i = (d.localPosition.dx / slot).floor().clamp(0, n - 1);
              HapticFeedback.selectionClick();
              setState(() => _touched = i);
            },
            onTapUp: (_) => setState(() => _touched = null),
            onTapCancel: () => setState(() => _touched = null),
            onHorizontalDragUpdate: (d) {
              final i = (d.localPosition.dx / slot).floor().clamp(0, n - 1);
              if (i != _touched) {
                HapticFeedback.selectionClick();
                setState(() => _touched = i);
              }
            },
            onHorizontalDragEnd: (_) => setState(() => _touched = null),
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(n, (i) {
                  final current = i == n - 1;
                  final active = _touched == i || (_touched == null && current);
                  final value = widget.series[i];

                  // Each bar owns a slice of the timeline, overlapping its
                  // neighbour so the stagger reads as a wave, not as six
                  // separate animations.
                  final begin = (i / n) * 0.55;
                  final t = Curves.easeOutBack.transform(
                    ((_c.value - begin) / (1 - begin)).clamp(0.0, 1.0),
                  );
                  final target = (value / widget.peak).clamp(0.0, 1.0);
                  final height = (maxBar * target * t).clamp(3.0, maxBar);

                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // The value rides above its bar and only for the
                        // bar in focus, so the chart stays quiet until
                        // you ask it something.
                        AnimatedOpacity(
                          opacity: active && value > 0 ? 1 : 0,
                          duration: AppMotion.fast,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColor.contrast,
                              borderRadius: AppRadius.all(AppRadius.xs),
                            ),
                            child: Text(
                              formatMoneyShort(value),
                              maxLines: 1,
                              style: AppFont.style(AppType.labelS,
                                  color: AppColor.onContrast),
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        AnimatedContainer(
                          duration: AppMotion.fast,
                          curve: AppMotion.standard,
                          height: height,
                          margin: EdgeInsets.symmetric(
                              horizontal: active ? 4 : 5.5),
                          decoration: BoxDecoration(
                            // A vertical gradient gives the jade bar a
                            // little depth instead of reading as a flat
                            // block of colour.
                            gradient: active
                                ? LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColor.primary,
                                      AppColor.primary
                                          .withValues(alpha: 0.72),
                                    ],
                                  )
                                : null,
                            color: active ? null : AppColor.sunken,
                            borderRadius: AppRadius.all(AppRadius.xs),
                            boxShadow: active
                                ? AppElevation.glow(AppColor.primary)
                                : null,
                          ),
                        ),
                        const SizedBox(height: AppSpace.sm),
                        Text(
                          widget.labels[i],
                          style: AppFont.style(
                            AppType.labelS,
                            color: active
                                ? AppColor.textPrimary
                                : AppColor.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GstCell extends StatelessWidget {
  final String label;
  final double value;
  const _GstCell(this.label, this.value);

  @override
  Widget build(BuildContext context) => AppWell(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.sm, vertical: AppSpace.md),
        radius: AppRadius.sm,
        child: Column(children: [
          Text(label,
              style: AppFont.style(AppType.overline,
                  color: AppColor.textTertiary)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Money(value,
                style: AppType.amountS, showSymbol: false, round: true),
          ),
        ]),
      );
}

class _Line extends StatelessWidget {
  final String label;
  final double value;
  final Color tone;
  const _Line(this.label, this.value, this.tone);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: tone, shape: BoxShape.circle)),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(label,
                style: AppFont.style(AppType.bodyM,
                    color: AppColor.textSecondary)),
          ),
          Money(value, style: AppType.amountS, round: true),
        ]),
      );
}

class _StatusBar extends StatelessWidget {
  final String label;
  final Color tone;
  final int count, total;
  final bool last;

  const _StatusBar({
    required this.label,
    required this.tone,
    required this.count,
    required this.total,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : AppSpace.lg),
        child: Row(children: [
          SizedBox(width: 86, child: StatusPill(label, tone: tone)),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: ClipRRect(
              borderRadius: AppRadius.all(AppRadius.pill),
              child: TweenAnimationBuilder<double>(
                tween: Tween(
                    begin: 0, end: total == 0 ? 0 : count / total),
                duration: AppMotion.slow,
                curve: AppMotion.enter,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  minHeight: 7,
                  backgroundColor: AppColor.sunken,
                  valueColor: AlwaysStoppedAnimation(tone),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          SizedBox(
            width: 26,
            child: Text('$count',
                textAlign: TextAlign.right,
                style: AppFont.style(AppType.amountS,
                    color: AppColor.textPrimary)),
          ),
        ]),
      );
}
