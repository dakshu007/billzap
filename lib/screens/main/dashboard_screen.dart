// lib/screens/main/dashboard_screen.dart
//
// Home.
//
// The question this screen answers, in order, is what a shop owner
// actually asks when they open a billing app:
//
//   1. How much money came in?                -> the hero balance
//   2. How much is still owed to me?          -> outstanding, and how bad
//   3. Is anything on fire?                   -> alerts, only when real
//   4. Let me do the thing I came to do.      -> actions
//   5. What happened recently?                -> the last few bills
//
// Everything is ordered by that, not by what is easiest to render.

import 'package:flutter/material.dart';
import 'package:billzap/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../design/components.dart';
import '../../design/money.dart';
import '../../design/motion.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../i18n/translations.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/platform.dart';
import '../../widgets/festival_banner.dart';
import '../../widgets/insight_card.dart';
import '../../widgets/profile_setup_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _greetingKey() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'dash.greeting_morning';
    if (h >= 12 && h < 17) return 'dash.greeting_afternoon';
    if (h >= 17 && h < 21) return 'dash.greeting_evening';
    return 'dash.greeting_night';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biz = ref.watch(businessProvider);
    final invoices = ref.watch(invoiceProvider);
    final customers = ref.watch(customerProvider);
    final products = ref.watch(productProvider);
    final now = DateTime.now();

    final lowStock = products
        .where((p) => p.tracksStock && (p.isOutOfStock || p.isLowStock))
        .toList();

    final paid = invoices.where((i) => i.status == InvoiceStatus.paid);
    final unpaid = invoices.where((i) =>
        i.status == InvoiceStatus.sent || i.status == InvoiceStatus.pending);
    final overdue = invoices.where((i) => i.isOverdue).toList();

    final revenue = paid.fold<double>(0, (s, i) => s + i.grandTotal);
    final outstanding = unpaid.fold<double>(0, (s, i) => s + i.grandTotal);
    final overdueAmount = overdue.fold<double>(0, (s, i) => s + i.grandTotal);
    final gst = paid.fold<double>(0, (s, i) => s + i.totalTax);

    final thisMonth = invoices
        .where((i) =>
            i.invoiceDate.month == now.month && i.invoiceDate.year == now.year)
        .toList();
    final thisMonthRevenue = thisMonth
        .where((i) => i.status == InvoiceStatus.paid)
        .fold<double>(0, (s, i) => s + i.grandTotal);

    // Six months of paid revenue, so the headline figure can carry the
    // shape of how it got there rather than standing on its own.
    final trend = List.generate(6, (k) {
      final m = DateTime(now.year, now.month - 5 + k);
      return paid
          .where((i) =>
              i.invoiceDate.month == m.month && i.invoiceDate.year == m.year)
          .fold<double>(0, (s, i) => s + i.grandTotal);
    });

    final bizName = biz?.name.trim().isNotEmpty == true ? biz!.name : null;
    final wide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColor.canvas,
      body: DesktopMaxWidth(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: _Header(
                  greeting: tr(_greetingKey(), ref),
                  business: bizName,
                  onProfile: () => context.go('/settings'),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0,
                  AppSpace.gutter, AppSpace.navClearance),
              sliver: SliverList.list(children: [
                const WelcomeProfileModalTrigger(),

                // 1 — the number the owner came to see
                Entrance(
                  index: 0,
                  child: _EarningsCard(
                    revenue: revenue,
                    trend: trend,
                    label: tr('dash.total_revenue', ref),
                    monthLabel: tr('dash.this_month_label', ref),
                    monthRevenue: thisMonthRevenue,
                    billCount: thisMonth.length,
                    onTap: () => context.go('/reports'),
                  ),
                ),
                const SizedBox(height: AppSpace.md),

                // 2 — what is still owed, and how much of it is late
                Entrance(
                  index: 1,
                  child: _OutstandingCard(
                    outstanding: outstanding,
                    unpaidCount: unpaid.length,
                    overdueAmount: overdueAmount,
                    overdueCount: overdue.length,
                    label: tr('dash.pending', ref),
                    overdueLabel: tr('inv.overdue', ref),
                    onTap: () => context.go('/invoices'),
                  ),
                ),
                const SizedBox(height: AppSpace.md),

                // 3 — alerts. Each renders only when it has something to say.
                const ProfileIncompleteBanner(),
                if (lowStock.isNotEmpty)
                  Entrance(index: 2, child: _StockAlert(items: lowStock)),
                const FestivalBanner(),
                const InsightCard(),

                // Secondary figures, deliberately smaller than the two above
                Entrance(
                  index: 3,
                  child: Row(children: [
                    Expanded(
                      child: StatTile(
                        label: tr('dash.gst_collected', ref),
                        amount: gst,
                        icon: Symbols.calculate,
                        tone: AppColor.info,
                        caption: tr('dash.auto_calc', ref),
                        onTap: () => context.go('/reports'),
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: StatTile(
                        label: tr('cust.title', ref),
                        value: '${customers.length}',
                        icon: Symbols.group,
                        tone: AppColor.pending,
                        caption: '${products.length} ${tr('prod.title', ref).toLowerCase()}',
                        onTap: () => context.push('/customers'),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: AppSpace.xxl),

                // 4 — the things the owner does
                Entrance(index: 4, child: SectionHeader(tr('dash.quick_actions', ref))),
                Entrance(
                  index: 5,
                  child: _ActionGrid(
                    wide: wide,
                    actions: [
                      _Action(Symbols.point_of_sale, tr('dash.day_close', ref),
                          AppColor.paid, () => context.push('/day-close')),
                      if (AppPlatform.supportsVoiceBilling)
                        _Action(Symbols.mic, tr('dash.voice_bill', ref),
                            AppColor.info, () => context.push('/voice')),
                      _Action(Symbols.group, tr('cust.title', ref),
                          AppColor.pending, () => context.push('/customers')),
                      _Action(Symbols.shopping_basket, tr('prod.title', ref),
                          AppColor.info, () => context.push('/products')),
                      _Action(Symbols.inventory_2, tr('cat.title', ref),
                          AppColor.paid, () => context.push('/catalog')),
                      _Action(Symbols.payments, tr('exp.title', ref),
                          AppColor.overdue, () => context.push('/expenses')),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.xxl),

                // 5 — recent activity
                Entrance(
                  index: 6,
                  child: SectionHeader(
                    tr('dash.recent_invoices', ref),
                    action: invoices.isEmpty ? null : tr('dash.see_all', ref),
                    onAction:
                        invoices.isEmpty ? null : () => context.go('/invoices'),
                  ),
                ),
                if (invoices.isEmpty)
                  Entrance(
                    index: 7,
                    child: AppSurface(
                      padding: EdgeInsets.zero,
                      child: AppEmptyState(
                        icon: Symbols.receipt_long,
                        title: tr('dash.no_invoices', ref),
                        message: tr('dash.create_first', ref),
                        tone: AppColor.primary,
                        actionLabel: tr('dash.new_invoice', ref),
                        onAction: () => context.push('/create'),
                      ),
                    ),
                  )
                else
                  ...invoices.take(5).toList().asMap().entries.map(
                        (e) => Entrance(
                          index: 7 + e.key,
                          child: _RecentInvoiceRow(
                            invoice: e.value,
                            onTap: () {
                              ref
                                  .read(selectedInvoiceProvider.notifier)
                                  .select(e.value);
                              context.push('/preview');
                            },
                          ),
                        ),
                      ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String greeting;
  final String? business;
  final VoidCallback onProfile;

  const _Header({
    required this.greeting,
    required this.business,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter, AppSpace.lg, AppSpace.gutter, AppSpace.xl),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(greeting,
                    style: AppFont.style(AppType.bodyM,
                        color: AppColor.textTertiary)),
                const SizedBox(height: 2),
                Text(
                  business ?? 'BillZap',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFont.style(AppType.titleL,
                      color: AppColor.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.md),
          PressScale(
            onTap: onProfile,
            scale: 0.9,
            child: AppAvatar(
                label: business ?? 'B',
                size: 46,
                tone: AppColor.primary),
          ),
        ]),
      );
}

/// The hero. One number, large, with the month's contribution underneath.
/// The counter animation is reserved for this card and the invoice total —
/// used anywhere else it would be noise.
class _EarningsCard extends StatelessWidget {
  final double revenue, monthRevenue;
  final String label, monthLabel;
  final int billCount;
  final List<double> trend;
  final VoidCallback onTap;

  const _EarningsCard({
    required this.revenue,
    required this.label,
    required this.monthLabel,
    required this.monthRevenue,
    required this.billCount,
    required this.trend,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => AppSurface(
        onTap: onTap,
        radius: AppRadius.xl,
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(label.toUpperCase(),
                  style: AppFont.style(AppType.overline,
                      color: AppColor.textTertiary)),
              const Spacer(),
              Icon(Icons.north_east_rounded,
                  size: 16, color: AppColor.textTertiary),
            ]),
            const SizedBox(height: AppSpace.md),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: MoneyCounter(revenue, style: AppType.amountHero),
            ),
            // The trend, drawn small under the figure. Shown only once
            // there is a shape worth showing — a flat line across six
            // empty months says nothing and reads as broken.
            if (trend.any((v) => v > 0)) ...[
              const SizedBox(height: AppSpace.lg),
              SizedBox(
                height: 44,
                child: Sparkline(values: trend, color: AppColor.primary),
              ),
            ],
            const SizedBox(height: AppSpace.lg),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColor.wash(AppColor.paid),
                  borderRadius: AppRadius.all(AppRadius.pill),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.trending_up_rounded,
                      size: 13, color: AppColor.paid),
                  const SizedBox(width: 5),
                  Money(monthRevenue,
                      style: AppType.labelS,
                      color: AppColor.paid,
                      round: true),
                ]),
              ),
              const SizedBox(width: AppSpace.sm),
              Flexible(
                child: Text(
                  '$monthLabel · $billCount ${billCount == 1 ? "bill" : "bills"}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFont.style(AppType.bodyS,
                      color: AppColor.textTertiary),
                ),
              ),
            ]),
          ],
        ),
      );
}

/// Outstanding money. The overdue portion is broken out as its own line
/// because "₹40,000 owed" and "₹40,000 owed, ₹31,000 of it late" are very
/// different situations and the owner needs to see which one they are in.
class _OutstandingCard extends StatelessWidget {
  final double outstanding, overdueAmount;
  final int unpaidCount, overdueCount;
  final String label, overdueLabel;
  final VoidCallback onTap;

  const _OutstandingCard({
    required this.outstanding,
    required this.unpaidCount,
    required this.overdueAmount,
    required this.overdueCount,
    required this.label,
    required this.overdueLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasOverdue = overdueCount > 0;
    final ratio = outstanding > 0
        ? (overdueAmount / outstanding).clamp(0.0, 1.0)
        : 0.0;

    return AppSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label.toUpperCase(),
                      style: AppFont.style(AppType.overline,
                          color: AppColor.textTertiary)),
                  const SizedBox(height: AppSpace.sm),
                  Money(outstanding, style: AppType.amountL, round: true),
                  const SizedBox(height: 3),
                  Text('$unpaidCount unpaid',
                      style: AppFont.style(AppType.bodyS,
                          color: AppColor.textTertiary)),
                ],
              ),
            ),
            if (hasOverdue)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusPill(overdueLabel, tone: AppColor.overdue),
                  const SizedBox(height: AppSpace.sm),
                  Money(overdueAmount,
                      style: AppType.amountS,
                      color: AppColor.overdue,
                      round: true),
                  const SizedBox(height: 3),
                  Text('$overdueCount ${overdueCount == 1 ? "bill" : "bills"}',
                      style: AppFont.style(AppType.bodyS,
                          color: AppColor.textQuiet)),
                ],
              ),
          ]),
          if (hasOverdue) ...[
            const SizedBox(height: AppSpace.lg),
            // How much of what is owed has gone late, at a glance.
            ClipRRect(
              borderRadius: AppRadius.all(AppRadius.pill),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: ratio),
                duration: AppMotion.slow,
                curve: AppMotion.enter,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  minHeight: 7,
                  backgroundColor: AppColor.sunken,
                  valueColor: AlwaysStoppedAnimation(AppColor.overdue),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Action {
  final IconData icon;
  final String label;
  final Color tone;
  final VoidCallback onTap;
  const _Action(this.icon, this.label, this.tone, this.onTap);
}

class _ActionGrid extends StatelessWidget {
  final List<_Action> actions;
  final bool wide;
  const _ActionGrid({required this.actions, required this.wide});

  @override
  Widget build(BuildContext context) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: wide ? 6 : 3,
          crossAxisSpacing: AppSpace.sm,
          mainAxisSpacing: AppSpace.sm,
          childAspectRatio: 0.98,
        ),
        itemCount: actions.length,
        itemBuilder: (_, i) {
          final a = actions[i];
          return AppSurface(
            onTap: a.onTap,
            radius: AppRadius.md,
            padding: const EdgeInsets.all(AppSpace.md),
            // Full width on purpose. AppSurface lays its child out in a
            // Stack, which hands down loose constraints, so the Column
            // was shrinking to its widest item and getting pinned to the
            // start — icon and label both hugging the left edge of a
            // card wide enough to centre them in.
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColor.wash(a.tone),
                      borderRadius: AppRadius.all(AppRadius.sm),
                    ),
                    child: Icon(a.icon, size: 19, color: a.tone),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    a.label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: AppFont.style(AppType.labelS,
                        color: AppColor.textSecondary),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class _RecentInvoiceRow extends ConsumerWidget {
  final Invoice invoice;
  final VoidCallback onTap;
  const _RecentInvoiceRow({required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (label, tone) = statusOf(invoice, ref);
    return AppListRow(
      onTap: onTap,
      leading: AppAvatar(label: invoice.customerName, tone: tone),
      title: invoice.customerName,
      subtitle: '${invoice.invoiceNumber} · '
          '${DateFormat('d MMM').format(invoice.invoiceDate)}',
      amount: invoice.grandTotal,
      badge: StatusPill(label, tone: tone),
    );
  }
}

/// Shared status resolution so a bill reads identically everywhere.
(String, Color) statusOf(Invoice inv, WidgetRef ref) {
  if (inv.isOverdue) return (tr('inv.overdue', ref), AppColor.overdue);
  switch (inv.status) {
    case InvoiceStatus.paid:
      return (tr('inv.paid', ref), AppColor.paid);
    case InvoiceStatus.sent:
      return (tr('inv.sent', ref), AppColor.info);
    case InvoiceStatus.pending:
      return (tr('inv.pending', ref), AppColor.pending);
    case InvoiceStatus.draft:
      return (tr('inv.draft', ref), AppColor.draft);
    case InvoiceStatus.cancelled:
      return (tr('inv.cancelled', ref), AppColor.draft);
  }
}

class _StockAlert extends ConsumerWidget {
  final List<Product> items;
  const _StockAlert({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final out = items.where((p) => p.isOutOfStock).length;
    final low = items.length - out;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: AppSurface(
        onTap: () => context.push('/products'),
        padding: const EdgeInsets.all(AppSpace.md),
        child: Row(children: [
          AppAvatar(icon: Symbols.inventory_2, tone: AppColor.pending),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tr('dash.stock_alert', ref),
                    style: AppFont.style(AppType.labelL,
                        color: AppColor.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  out > 0 && low > 0
                      ? '$out out of stock · $low running low'
                      : out > 0
                          ? '$out ${out == 1 ? "item" : "items"} out of stock'
                          : '$low ${low == 1 ? "item" : "items"} running low',
                  style: AppFont.style(AppType.bodyS,
                      color: AppColor.textTertiary),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              size: 20, color: AppColor.textQuiet),
        ]),
      ),
    );
  }
}
