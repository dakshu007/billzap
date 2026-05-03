// lib/screens/main/dashboard_screen.dart
// ✅ Fully translated
// ✅ Catalog quick action added
// ✅ Products quick action added
// ✅ Live business name from provider
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/insight_card.dart';
import '../../widgets/festival_banner.dart';
import '../../models/models.dart';
import '../../i18n/translations.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _greetingKey() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12)  return 'dash.greeting_morning';
    if (h >= 12 && h < 17) return 'dash.greeting_afternoon';
    if (h >= 17 && h < 21) return 'dash.greeting_evening';
    return 'dash.greeting_night';
  }

  String _greetingEmoji() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12)  return '☀️';
    if (h >= 12 && h < 17) return '🌤️';
    if (h >= 17 && h < 21) return '🌆';
    return '🌙';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biz       = ref.watch(businessProvider);
    final invoices  = ref.watch(invoiceProvider);
    final customers = ref.watch(customerProvider);
    final now       = DateTime.now();
    final greet     = tr(_greetingKey(), ref);
    final emoji     = _greetingEmoji();

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

    final bizName = biz?.name.isNotEmpty == true ? biz!.name : null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.card,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('nav.home', ref), style: GoogleFonts.plusJakartaSans(
            fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.t1)),
          Text('$greet $emoji', style: GoogleFonts.plusJakartaSans(
            fontSize: 12, color: AppColors.t3)),
        ]),
        actions: [
          GestureDetector(
            onTap: () => context.go('/settings'),
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(
                (bizName?.isNotEmpty == true ? bizName![0] : 'B').toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15, fontWeight: FontWeight.w900,
                  color: Colors.white))),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
        children: [
          // Hero banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A1E5E), Color(0xFF1557FF)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$greet $emoji', style: GoogleFonts.plusJakartaSans(
                  color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                const Gap(3),
                Text(bizName ?? tr('dash.setup_profile', ref),
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white60, fontSize: 12)),
                if (biz?.gstin.isNotEmpty == true) ...[
                  const Gap(2),
                  Text('GSTIN: ${biz!.gstin}',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white38, fontSize: 10.5)),
                ],
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(formatCurrency(revenue), style: GoogleFonts.plusJakartaSans(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                Text(tr('dash.total_revenue', ref),
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white54, fontSize: 10)),
              ]),
            ]),
          ),
          const Gap(14),

          // 🎆 Festival banner (only shows on festival day or 1 day before)
          const FestivalBanner(),
          // ✨ Daily insight banner
          const InsightCard(),
          // Stat cards
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.55,
            children: [
              _StatCard(
                tr('dash.revenue', ref),
                formatCurrency(revenue),
                Symbols.trending_up,
                AppColors.brand, AppColors.brandSoft,
                '${thisMo.length} ${tr('dash.this_month_label', ref)}'),
              _StatCard(
                tr('dash.pending', ref),
                formatCurrency(pendAmt),
                Symbols.schedule,
                AppColors.yellow, AppColors.yellowSoft,
                '${invoices.where((i) => i.status == InvoiceStatus.sent || i.status == InvoiceStatus.pending).length} ${tr('inv.title', ref).toLowerCase()}'),
              _StatCard(
                tr('dash.gst_collected', ref),
                formatCurrency(gstCollected),
                Symbols.calculate,
                AppColors.green, AppColors.greenSoft,
                tr('dash.auto_calc', ref)),
              _StatCard(
                tr('cust.title', ref),
                '${customers.length}',
                Symbols.group,
                AppColors.purple, AppColors.purpleSoft,
                '${invoices.where((i) => i.isOverdue).length} ${tr('inv.overdue', ref).toLowerCase()}'),
            ],
          ),
          const Gap(16),

          // 💰 Day Close — daily collections summary
          GestureDetector(
            onTap: () { HapticFeedback.lightImpact(); context.push('/day-close'); },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                  color: const Color(0xFF2E7D32).withOpacity(0.3),
                  blurRadius: 12, offset: const Offset(0, 5))],
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(11)),
                  child: const Icon(Symbols.point_of_sale, color: Colors.white, size: 24),
                ),
                const Gap(13),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Day Close',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                    Text('Today\'s collections by Cash, UPI, Bank',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5, color: Colors.white.withOpacity(0.85))),
                  ]),
                ),
                const Icon(Symbols.arrow_forward, color: Colors.white, size: 20),
              ]),
            ),
          ),

          // ✨ Voice Bill — featured banner
          GestureDetector(
            onTap: () { HapticFeedback.mediumImpact(); context.push('/voice'); },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE53E3E), Color(0xFFFF6B6B)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                  color: const Color(0xFFE53E3E).withOpacity(0.35),
                  blurRadius: 14, offset: const Offset(0, 6))],
              ),
              child: Row(children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Symbols.mic, color: Colors.white, size: 26),
                ),
                const Gap(14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Voice Bill',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16, fontWeight: FontWeight.w900,
                        color: Colors.white)),
                    Text('Speak to create invoices in your language',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5, color: Colors.white.withOpacity(0.85))),
                  ]),
                ),
                const Icon(Symbols.arrow_forward, color: Colors.white, size: 20),
              ]),
            ),
          ),

          // Quick actions row 1
          Row(children: [
            _QuickBtn(Symbols.receipt_long, tr('dash.new_invoice', ref),
              AppColors.brand, AppColors.brandSoft,
              () => context.push('/create')),
            const Gap(8),
            _QuickBtn(Symbols.group, tr('cust.title', ref),
              AppColors.green, AppColors.greenSoft,
              () => context.push('/customers')),
            const Gap(8),
            _QuickBtn(Symbols.bar_chart, tr('rep.title', ref),
              AppColors.purple, AppColors.purpleSoft,
              () => context.go('/reports')),
          ]),
          const Gap(8),
          // Quick actions row 2 — products & catalog
          Row(children: [
            _QuickBtn(Symbols.shopping_basket, tr('prod.title', ref),
              AppColors.brand, AppColors.brandSoft,
              () => context.push('/products')),
            const Gap(8),
            _QuickBtn(Symbols.inventory_2, tr('cat.title', ref),
              AppColors.purple, AppColors.purpleSoft,
              () => context.push('/catalog')),
            const Gap(8),
            _QuickBtn(Symbols.payments, tr('exp.title', ref),
              AppColors.yellow, AppColors.yellowSoft,
              () => context.push('/expenses')),
          ]),
          const Gap(20),

          // Recent invoices header
          Row(children: [
            Text(tr('dash.recent_invoices', ref), style: GoogleFonts.plusJakartaSans(
              fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.t1)),
            const Spacer(),
            TextButton(
              onPressed: () => context.go('/invoices'),
              child: Text(tr('dash.see_all', ref),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5, fontWeight: FontWeight.w600,
                  color: AppColors.brand))),
          ]),
          const Gap(6),

          if (invoices.isEmpty)
            _EmptyInvoice(onTap: () => context.push('/create'))
          else
            ...invoices.take(6).map((inv) => _InvoiceRow(inv: inv, onTap: () {
              ref.read(selectedInvoiceProvider.notifier).state = inv;
              context.push('/preview');
            })),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color color, soft;
  const _StatCard(this.label, this.value, this.icon, this.color, this.soft, this.sub);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 32, height: 32,
        decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 17, color: color)),
      const Gap(6),
      Text(label, style: GoogleFonts.plusJakartaSans(
        fontSize: 10.5, color: AppColors.t3, fontWeight: FontWeight.w600)),
      const Gap(1),
      Text(value, style: GoogleFonts.plusJakartaSans(
        fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.t1),
        maxLines: 1, overflow: TextOverflow.ellipsis),
      Text(sub, style: GoogleFonts.plusJakartaSans(
        fontSize: 10, color: AppColors.t3),
        maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  );
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color, soft;
  final VoidCallback onTap;
  const _QuickBtn(this.icon, this.label, this.color, this.soft, this.onTap);

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: soft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Icon(icon, size: 24, color: color),
          const Gap(5),
          Text(label,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    ),
  );
}

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: AppColors.card,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Container(width: 38, height: 38,
            decoration: BoxDecoration(color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(
              inv.customerName.isNotEmpty ? inv.customerName[0].toUpperCase() : '?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15, fontWeight: FontWeight.w900,
                color: AppColors.brand)))),
          const Gap(11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(inv.customerName, style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.t1)),
            Text('${inv.invoiceNumber} · ${DateFormat('dd MMM').format(inv.invoiceDate)}',
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.t3)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(formatCurrency(inv.grandTotal), style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.t1)),
            const Gap(3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: c.withOpacity(0.12),
                borderRadius: BorderRadius.circular(99)),
              child: Text(_statusLabel(ref),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5, fontWeight: FontWeight.w800, color: c))),
          ]),
        ]),
      ),
    );
  }
}

class _EmptyInvoice extends ConsumerWidget {
  final VoidCallback onTap;
  const _EmptyInvoice({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border)),
    child: Column(children: [
      const Icon(Symbols.receipt_long, size: 44, color: AppColors.t4),
      const Gap(10),
      Text(tr('dash.no_invoices', ref), style: GoogleFonts.plusJakartaSans(
        fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.t1)),
      const Gap(4),
      Text(tr('dash.create_first', ref), style: GoogleFonts.plusJakartaSans(
        fontSize: 13, color: AppColors.t3)),
      const Gap(16),
      ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Symbols.add, size: 18),
        label: Text(tr('dash.new_invoice', ref))),
    ]),
  );
}
