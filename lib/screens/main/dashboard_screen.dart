// lib/screens/main/dashboard_screen.dart
//
// Home. Same data and the same entry points as before the redesign —
// revenue / pending / GST / customers, day-close, voice billing, the
// quick actions and recent invoices — re-laid out in the clean language:
// one headline balance card, flat stat tiles, pill quick-actions, and
// borderless list rows. No gradients, no coloured panels; colour appears
// only where it carries meaning.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:billzap/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_spacing.dart';
import '../../providers/providers.dart';
import '../../widgets/insight_card.dart';
import '../../widgets/festival_banner.dart';
import '../../widgets/profile_setup_widgets.dart';
import '../../widgets/ui_kit.dart';
import '../../models/models.dart';
import '../../i18n/translations.dart';
import '../../utils/platform.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _greetingKey() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12)  return 'dash.greeting_morning';
    if (h >= 12 && h < 17) return 'dash.greeting_afternoon';
    if (h >= 17 && h < 21) return 'dash.greeting_evening';
    return 'dash.greeting_night';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biz       = ref.watch(businessProvider);
    final invoices  = ref.watch(invoiceProvider);
    final customers = ref.watch(customerProvider);
    final products  = ref.watch(productProvider);
    final lowStock  = products.where((p) => p.tracksStock &&
        (p.isOutOfStock || p.isLowStock)).toList();
    final now       = DateTime.now();
    final greet     = tr(_greetingKey(), ref);

    final thisMo = invoices.where((i) =>
      i.invoiceDate.month == now.month && i.invoiceDate.year == now.year).toList();
    final revenue = invoices
      .where((i) => i.status == InvoiceStatus.paid)
      .fold<double>(0, (s, i) => s + i.grandTotal);
    final pendAmt = invoices
      .where((i) => i.status == InvoiceStatus.sent || i.status == InvoiceStatus.pending)
      .fold<double>(0, (s, i) => s + i.grandTotal);
    final gstCollected = invoices
      .where((i) => i.status == InvoiceStatus.paid)
      .fold<double>(0, (s, i) => s + i.totalTax);
    final pendingCount = invoices.where((i) =>
        i.status == InvoiceStatus.sent || i.status == InvoiceStatus.pending).length;
    final overdueCount = invoices.where((i) => i.isOverdue).length;

    final bizName = biz?.name.isNotEmpty == true ? biz!.name : null;
    final desktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.bg,
        toolbarHeight: 72,
        titleSpacing: AppSpacing.screenH,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(greet,
              style: AppFont.sans(
                fontSize: 21, fontWeight: FontWeight.w700,
                letterSpacing: -0.5, color: AppColors.t1)),
            const Gap(2),
            Text(bizName ?? tr('dash.setup_profile', ref),
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: AppFont.sans(fontSize: 12.5, color: AppColors.t3)),
          ]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.screenH),
            child: GestureDetector(
              onTap: () => context.go('/settings'),
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  (bizName?.isNotEmpty == true ? bizName![0] : 'B').toUpperCase(),
                  style: AppFont.sans(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    color: AppColors.onBrand)),
              ),
            ),
          ),
        ],
      ),
      body: DesktopMaxWidth(child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, 6, AppSpacing.screenH, AppSpacing.bottomNavSafe),
        children: [
          // Auto-shows welcome modal on first home visit if profile is empty
          const WelcomeProfileModalTrigger(),

          // ─── Headline balance ──────────────────────────────────────
          _BalanceCard(
            revenue: revenue,
            label: tr('dash.total_revenue', ref),
            footnote: '${thisMo.length} ${tr('dash.this_month_label', ref)}',
            gstin: biz?.gstin.isNotEmpty == true ? biz!.gstin : null,
            onTap: () => context.go('/reports'),
          ),
          const Gap(AppSpacing.cardGap),

          // ⚠️ Profile incomplete banner (shown if <80% complete)
          const ProfileIncompleteBanner(),
          // 📦 Low-stock / out-of-stock alert
          if (lowStock.isNotEmpty) _LowStockBanner(items: lowStock),
          // 🎆 Festival banner (only on festival day or 1 day before)
          const FestivalBanner(),
          // ✨ Daily insight banner
          const InsightCard(),

          // ─── Stat tiles ────────────────────────────────────────────
          GridView.count(
            crossAxisCount: desktop ? 3 : 3, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: desktop ? 1.25 : 0.92,
            children: [
              _StatTile(
                label: tr('dash.pending', ref),
                value: formatCurrency(pendAmt),
                icon: Symbols.schedule,
                tone: AppColors.yellow,
                sub: '$pendingCount ${tr('inv.title', ref).toLowerCase()}'),
              _StatTile(
                label: tr('dash.gst_collected', ref),
                value: formatCurrency(gstCollected),
                icon: Symbols.calculate,
                tone: AppColors.green,
                sub: tr('dash.auto_calc', ref)),
              _StatTile(
                label: tr('cust.title', ref),
                value: '${customers.length}',
                icon: Symbols.group,
                tone: overdueCount > 0 ? AppColors.red : AppColors.t2,
                sub: '$overdueCount ${tr('inv.overdue', ref).toLowerCase()}'),
            ],
          ),
          const Gap(AppSpacing.section),

          // ─── Quick actions ─────────────────────────────────────────
          AppSectionHeader(tr('dash.quick_actions', ref)),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              children: [
                AppPill(tr('dash.new_invoice', ref),
                  icon: Symbols.receipt_long, selected: true,
                  onTap: () => context.push('/create')),
                const Gap(8),
                AppPill(tr('cust.title', ref),
                  icon: Symbols.group,
                  onTap: () => context.push('/customers')),
                const Gap(8),
                AppPill(tr('prod.title', ref),
                  icon: Symbols.shopping_basket,
                  onTap: () => context.push('/products')),
                const Gap(8),
                AppPill(tr('cat.title', ref),
                  icon: Symbols.inventory_2,
                  onTap: () => context.push('/catalog')),
                const Gap(8),
                AppPill(tr('exp.title', ref),
                  icon: Symbols.payments,
                  onTap: () => context.push('/expenses')),
                const Gap(8),
                AppPill(tr('rep.title', ref),
                  icon: Symbols.bar_chart,
                  onTap: () => context.go('/reports')),
              ],
            ),
          ),
          const Gap(AppSpacing.section),

          // ─── Feature cards ─────────────────────────────────────────
          _FeatureCard(
            icon: Symbols.point_of_sale,
            title: tr('dash.day_close', ref),
            subtitle: tr('dash.day_close_sub', ref),
            onTap: () { HapticFeedback.lightImpact(); context.push('/day-close'); },
          ),
          // Voice billing is hidden on desktop — the speech_to_text plugin
          // ships no macOS/Windows binding. /voice stays routable.
          if (AppPlatform.supportsVoiceBilling) ...[
            const Gap(AppSpacing.cardGap),
            _FeatureCard(
              icon: Symbols.mic,
              title: tr('dash.voice_bill', ref),
              subtitle: tr('dash.voice_bill_sub', ref),
              onTap: () { HapticFeedback.mediumImpact(); context.push('/voice'); },
            ),
          ],
          const Gap(AppSpacing.section),

          // ─── Recent invoices ───────────────────────────────────────
          AppSectionHeader(
            tr('dash.recent_invoices', ref),
            actionLabel: invoices.isEmpty ? null : tr('dash.see_all', ref),
            onAction: invoices.isEmpty ? null : () => context.go('/invoices'),
          ),
          if (invoices.isEmpty)
            AppCard(
              padding: EdgeInsets.zero,
              child: AppEmptyState(
                icon: Symbols.receipt_long,
                title: tr('dash.no_invoices', ref),
                message: tr('dash.create_first', ref),
                actionLabel: tr('dash.new_invoice', ref),
                onAction: () => context.push('/create'),
              ),
            )
          else
            ...invoices.take(6).map((inv) => _InvoiceRow(inv: inv, onTap: () {
              ref.read(selectedInvoiceProvider.notifier).select(inv);
              context.push('/preview');
            })),
        ],
      )),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Headline balance — the one large, quiet statement on the screen.
// ─────────────────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final double revenue;
  final String label, footnote;
  final String? gstin;
  final VoidCallback onTap;

  const _BalanceCard({
    required this.revenue,
    required this.label,
    required this.footnote,
    required this.gstin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        radius: AppRadius.xl,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(label,
                style: AppFont.sans(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: AppColors.t3)),
              const Spacer(),
              Icon(Symbols.arrow_forward, size: 17, color: AppColors.t3),
            ]),
            const Gap(10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(formatCurrency(revenue),
                maxLines: 1,
                style: AppFont.sans(
                  fontSize: 38, fontWeight: FontWeight.w700,
                  letterSpacing: -1.4, height: 1.05,
                  color: AppColors.t1)),
            ),
            const Gap(14),
            Row(children: [
              AppPill(footnote, icon: Symbols.trending_up, dense: true,
                tone: AppColors.green),
              if (gstin != null) ...[
                const Gap(7),
                Flexible(
                  child: AppPill('GSTIN $gstin', dense: true),
                ),
              ],
            ]),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────
// Stat tile — thin icon, muted label, tight numeral.
// ─────────────────────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color tone;

  const _StatTile({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(13),
        radius: AppRadius.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 19, color: tone),
            const Spacer(),
            Text(label,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: AppFont.sans(
                fontSize: 11, fontWeight: FontWeight.w500,
                color: AppColors.t3)),
            const Gap(3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                maxLines: 1,
                style: AppFont.sans(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  letterSpacing: -0.5, color: AppColors.t1)),
            ),
            const Gap(2),
            Text(sub,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: AppFont.sans(fontSize: 10.5, color: AppColors.t4)),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────
// Feature card — day close, voice billing.
// ─────────────────────────────────────────────────────────────────────
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(15),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: AppColors.brand,
              shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.onBrand, size: 21),
          ),
          const Gap(14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                style: AppFont.sans(
                  fontSize: 15, fontWeight: FontWeight.w600,
                  letterSpacing: -0.3, color: AppColors.t1)),
              const Gap(3),
              Text(subtitle,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: AppFont.sans(
                  fontSize: 12.5, color: AppColors.t3, height: 1.3)),
            ])),
          const Gap(8),
          Icon(Symbols.chevron_right, color: AppColors.t4, size: 20),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────
// Recent invoice row
// ─────────────────────────────────────────────────────────────────────
class _InvoiceRow extends ConsumerWidget {
  final Invoice inv;
  final VoidCallback onTap;
  const _InvoiceRow({required this.inv, required this.onTap});

  String _statusLabel(WidgetRef ref) {
    if (inv.isOverdue) return tr('inv.overdue', ref).toUpperCase();
    switch (inv.status) {
      case InvoiceStatus.paid:    return tr('inv.paid', ref).toUpperCase();
      case InvoiceStatus.sent:    return tr('inv.sent', ref).toUpperCase();
      case InvoiceStatus.pending: return tr('inv.pending', ref).toUpperCase();
      case InvoiceStatus.draft:   return tr('inv.draft', ref).toUpperCase();
      case InvoiceStatus.cancelled: return tr('inv.cancelled', ref).toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = inv.status == InvoiceStatus.paid ? AppColors.green
        : inv.isOverdue ? AppColors.red : AppColors.yellow;
    return AppListRow(
      onTap: onTap,
      leading: AppBadge(initial: inv.customerName, size: 44),
      title: inv.customerName,
      subtitle: '${inv.invoiceNumber} · '
          '${DateFormat('dd MMM').format(inv.invoiceDate)}',
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(formatCurrency(inv.grandTotal),
            style: AppFont.sans(
              fontSize: 14.5, fontWeight: FontWeight.w600,
              letterSpacing: -0.3, color: AppColors.t1)),
          const Gap(5),
          AppPill(_statusLabel(ref), dense: true, tone: c),
        ]),
    );
  }
}

// ─── Low-stock banner ─────────────────────────────────────────────────
// Tapping it jumps to Products so the owner can re-order or adjust stock.
// Deliberately one compact row so it doesn't dominate the dashboard.
class _LowStockBanner extends ConsumerWidget {
  final List<Product> items;
  const _LowStockBanner({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final out = items.where((p) => p.isOutOfStock).length;
    final low = items.length - out;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.cardGap),
      padding: const EdgeInsets.all(14),
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/products');
      },
      child: Row(children: [
        AppBadge(icon: Symbols.inventory_2, tone: AppColors.orange, size: 42),
        const Gap(13),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('dash.stock_alert', ref),
              style: AppFont.sans(
                fontSize: 14, fontWeight: FontWeight.w600,
                letterSpacing: -0.2, color: AppColors.t1)),
            const Gap(2),
            Text(
              out > 0 && low > 0
                ? '$out out of stock • $low running low'
                : out > 0
                  ? '$out item${out == 1 ? "" : "s"} out of stock'
                  : '$low item${low == 1 ? "" : "s"} running low',
              style: AppFont.sans(fontSize: 12.5, color: AppColors.t3)),
          ])),
        Icon(Symbols.chevron_right, color: AppColors.t4, size: 20),
      ]),
    );
  }
}
