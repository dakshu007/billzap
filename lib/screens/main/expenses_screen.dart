// lib/screens/main/expenses_screen.dart
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exps = ref.watch(expenseProvider);
    final invs = ref.watch(invoiceProvider);
    final now  = DateTime.now();
    final total = exps.fold<double>(0, (s, e) => s + e.amount);
    final mon   = exps.where((e) => e.date.month == now.month && e.date.year == now.year)
                      .fold<double>(0, (s, e) => s + e.amount);
    final rev   = invs.where((i) => i.status == InvoiceStatus.paid)
                      .fold<double>(0, (s, i) => s + i.grandTotal);
    final profit = rev - total;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false, backgroundColor: AppColors.card,
        title: Text('Expenses', style: GoogleFonts.plusJakartaSans(
          fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.t1)),
        actions: [
          IconButton(
            icon: const Icon(Symbols.add, color: AppColors.brand, size: 26),
            onPressed: () => _addSheet(context, ref)),
        ],
      ),
      body: Column(children: [
        // Summary row
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(children: [
            _SumCard('Total Expenses', formatCurrency(total), AppColors.red, AppColors.redSoft),
            const Gap(8),
            _SumCard('This Month', formatCurrency(mon), AppColors.yellow, AppColors.yellowSoft),
            const Gap(8),
            _SumCard('Net Profit', formatCurrency(profit),
              profit >= 0 ? AppColors.green : AppColors.red,
              profit >= 0 ? AppColors.greenSoft : AppColors.redSoft),
          ]),
        ),

        Expanded(child: exps.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Symbols.payments, size: 48, color: AppColors.t4), const Gap(10),
              Text('No expenses recorded', style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w800)),
              const Gap(6),
              Text('Track expenses to see P&L', style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: AppColors.t3)),
              const Gap(16),
              ElevatedButton.icon(
                onPressed: () => _addSheet(context, ref),
                icon: const Icon(Symbols.add, size: 18),
                label: const Text('Add Expense')),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
              itemCount: exps.length,
              itemBuilder: (_, i) {
                final e = exps[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(color: AppColors.card,
                    borderRadius: BorderRadius.circular(13), border: Border.all(color: AppColors.border)),
                  child: Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.brandSoft, borderRadius: BorderRadius.circular(8)),
                      child: Text(e.category, style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brand))),
                    const Gap(11),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.title, style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.t1)),
                      Text('${DateFormat('dd MMM yyyy').format(e.date)} \u00b7 ${e.paymentMode}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.t3)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(formatCurrency(e.amount), style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.red)),
                      const Gap(2),
                      GestureDetector(
                        onTap: () => ref.read(expenseProvider.notifier).delete(e.id),
                        child: const Icon(Symbols.delete, size: 15, color: AppColors.red)),
                    ]),
                  ]),
                );
              }),
        ),
      ]),
    );
  }

  void _addSheet(BuildContext context, WidgetRef ref) {
    String cat  = kExpenseCategories[0];
    String mode = 'UPI';
    final title  = TextEditingController();
    final amount = TextEditingController();
    DateTime date = DateTime.now();
    bool saving   = false;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(99)))),
            const Gap(16),
            Text('Add Expense', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
            const Gap(16),
            Row(children: [
              Expanded(child: DropdownButtonFormField<String>(
                value: cat,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: kExpenseCategories.map((c) => DropdownMenuItem(value: c,
                  child: Text(c, style: GoogleFonts.plusJakartaSans(fontSize: 13)))).toList(),
                onChanged: (v) => ss(() => cat = v ?? cat))),
              const Gap(10),
              Expanded(child: TextField(
                controller: amount, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (\u20b9) *', border: OutlineInputBorder()),
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5))),
            ]),
            const Gap(10),
            TextField(controller: title,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5)),
            const Gap(10),
            Row(children: [
              Expanded(child: DropdownButtonFormField<String>(
                value: mode,
                decoration: const InputDecoration(labelText: 'Payment Mode', border: OutlineInputBorder()),
                items: ['UPI', 'Cash', 'Bank Transfer', 'Cheque', 'Card'].map((m) =>
                  DropdownMenuItem(value: m, child: Text(m, style: GoogleFonts.plusJakartaSans(fontSize: 13)))).toList(),
                onChanged: (v) => ss(() => mode = v ?? mode))),
            ]),
            const Gap(20),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: saving ? null : () async {
                final amt = double.tryParse(amount.text);
                if (amt == null || amt <= 0) return;
                ss(() => saving = true);
                try {
                  await ref.read(expenseProvider.notifier).add(Expense(
                    category: cat,
                    title: title.text.trim().isEmpty ? cat : title.text.trim(),
                    amount: amt, date: date, paymentMode: mode));
                  if (ctx.mounted) Navigator.pop(ctx);
                } finally {
                  if (ctx.mounted) ss(() => saving = false);
                }
              },
              child: saving
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save Expense'))),
          ]),
        ),
      )),
    );
  }
}

class _SumCard extends StatelessWidget {
  final String label, value;
  final Color color, soft;
  const _SumCard(this.label, this.value, this.color, this.soft);
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      const Gap(3),
      Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w900, color: color),
        maxLines: 1, overflow: TextOverflow.ellipsis),
    ]));;
}
