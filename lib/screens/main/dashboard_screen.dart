// lib/screens/main/dashboard_screen.dart
// ✅ Greeting fixed (real time check)
// ✅ Business name updates live from provider
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  // ✅ FIX: Real greeting based on current hour
  String _greeting() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12)  return 'Good morning';
    if (h >= 12 && h < 17) return 'Good afternoon';
    if (h >= 17 && h < 21) return 'Good evening';
    return 'Good night';
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
    // ✅ FIX: Watch businessProvider so it updates when name changes in settings
    final biz      = ref.watch(businessProvider);
    final invoices = ref.watch(invoiceProvider);
    final customers= ref.watch(customerProvider);
    final now      = DateTime.now();
    final greet    = _greeting();
    final emoji    = _greetingEmoji();

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

    // ✅ FIX: Show business name from provider, updates immediately after settings save
    final bizName = biz?.name.isNotEmpty == true ? biz!.name : null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.card,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Dashboard', style: GoogleFonts.plusJakartaSans(
            fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.t1)),
          Text('$greet $emoji', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.t3)),
        ]),
        actions: [
          GestureDetector(
            onTap: () => context.go('/settings'),
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.brand, borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(
                // ✅ FIX: Show first letter of business name, updates live
                (bizName?.isNotEmpty == true ? bizName![0] : 'B').toUpperCase(),
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white))),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
        children: [
          // Hero banner — shows business name live
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
                // ✅ Shows business name immediately after update
                Text(bizName ?? 'Set up your business profile',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white60, fontSize: 12)),
                if (biz?.gstin.isNotEmpty == true) ...[
                  const Gap(2),
                  Text('GSTIN: ${biz!.gstin}',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 10.5)),
                ],
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(formatCurrency(revenue), style: GoogleFonts.plusJakartaSans(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                Text('Total revenue', style: GoogleFonts.plusJakartaSans(
                  color: Colors.white54, fontSize: 10)),
              ]),
            ]),
          ),
          const Gap(14),

          // Stat cards
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.55,
            children: [
              _StatCard('Revenue', formatCurrency(revenue), Symbols.trending_up,
                AppColors.brand, AppColors.brandSoft, '${thisMo.length} this month'),
              _StatCard('Pending', formatCurrency(pendAmt), Symbols.schedule,
                AppColors.yellow, AppColors.yellowSoft,
                '${invoices.where((i) => i.status == InvoiceStatus.sent || i.status == InvoiceStatus.pending).length} invoices'),
              _StatCard('GST Collected', formatCurrency(gstCollected), Symbols.calculate,
                AppColors.green, AppColors.greenSoft, 'Auto-calculated'),
              _StatCard('Customers', '${customers.length}', Symbols.group,
                AppColors.purple, AppColors.purpleSoft,
                '${invoices.where((i) => i.isOverdue).length} overdue'),
            ],
          ),
          const Gap(16),

          // Quick actions
          Row(children: [
            _QuickBtn('⚡', 'New Invoice', AppColors.brand, AppColors.brandSoft,
              () => context.push('/create')),
            const Gap(8),
            _QuickBtn('👥', 'Customers', AppColors.green, AppColors.greenSoft,
              () => context.go('/customers')),
            const Gap(8),
            _QuickBtn('📊', 'Reports', AppColors.purple, AppColors.purpleSoft,
              () => context.go('/reports')),
          ]),
          const Gap(20),

          // Recent invoices
          Row(children: [
            Text('Recent Invoices', style: GoogleFonts.plusJakartaSans(
              fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.t1)),
            const Spacer(),
            TextButton(
              onPressed: () => context.go('/invoices'),
              child: Text('View all', style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.brand))),
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
      borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 32, height: 32,
        decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 17, color: color)),
      const Gap(6),
      Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.t3, fontWeight: FontWeight.w600)),
      const Gap(1),
      Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.t1),
        maxLines: 1, overflow: TextOverflow.ellipsis),
      Text(sub, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.t3)),
    ]),
  );
}

class _QuickBtn extends StatelessWidget {
  final String emoji, label;
  final Color color, soft;
  final VoidCallback onTap;
  const _QuickBtn(this.emoji, this.label, this.color, this.soft, this.onTap);

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2))),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const Gap(4),
          Text(label, style: GoogleFonts.plusJakartaSans(
            fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    ),
  );
}

class _InvoiceRow extends StatelessWidget {
  final Invoice inv;
  final VoidCallback onTap;
  const _InvoiceRow({required this.inv, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = inv.status == InvoiceStatus.paid ? AppColors.green
        : inv.isOverdue ? AppColors.red : AppColors.yellow;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: AppColors.card,
          borderRadius: BorderRadius.circular(13), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Container(width: 38, height: 38,
            decoration: BoxDecoration(color: AppColors.brandSoft, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(
              inv.customerName.isNotEmpty ? inv.customerName[0].toUpperCase() : '?',
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.brand)))),
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
              child: Text(inv.isOverdue ? 'OVERDUE' : inv.status.name.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w800, color: c))),
          ]),
        ]),
      ),
    );
  }
}

class _EmptyInvoice extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyInvoice({required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: AppColors.card,
      borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
    child: Column(children: [
      const Icon(Symbols.receipt_long, size: 44, color: AppColors.t4),
      const Gap(10),
      Text('No invoices yet', style: GoogleFonts.plusJakartaSans(
        fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.t1)),
      const Gap(4),
      Text('Create your first GST invoice', style: GoogleFonts.plusJakartaSans(
        fontSize: 13, color: AppColors.t3)),
      const Gap(16),
      ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Symbols.add, size: 18),
        label: const Text('Create Invoice')),
    ]),
  );
}
