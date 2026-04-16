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
    final expenses = ref.watch(expenseProvider);
    final total = expenses.fold<double>(0, (s, e) => s + e.amount);
    final month = expenses.where((e) =>
      e.date.month == DateTime.now().month &&
      e.date.year  == DateTime.now().year).fold<double>(0, (s, e) => s + e.amount);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.card,
        title: Text('Expenses', style: GoogleFonts.plusJakartaSans(
          fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.t1)),
        actions: [
          IconButton(
            icon: const Icon(Symbols.add, color: AppColors.brand, size: 26),
            onPressed: () => _addSheet(context, ref)),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(children: [
            _SumCard('This Month', formatCurrency(month),
              AppColors.brand, AppColors.brandSoft),
            const Gap(10),
            _SumCard('Total', formatCurrency(total),
              AppColors.purple, AppColors.purpleSoft),
          ]),
        ),
        const Gap(10),
        Expanded(
          child: expenses.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Symbols.payments, size: 48, color: AppColors.t4),
                const Gap(10),
                Text('No expenses yet', style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w800)),
                const Gap(6),
                Text('Track your business expenses', style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: AppColors.t3)),
                const Gap(16),
                ElevatedButton.icon(
                  onPressed: () => _addSheet(context, ref),
                  icon: const Icon(Symbols.add, size: 18),
                  label: const Text('Add Expense')),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                itemCount: expenses.length,
                itemBuilder: (ctx, i) {
                  final e = expenses[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: AppColors.border)),
                    child: Row(children: [
                      Container(width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.purpleSoft,
                          borderRadius: BorderRadius.circular(11)),
                        child: const Center(
                          child: Icon(Symbols.receipt, size: 20,
                            color: AppColors.purple))),
                      const Gap(12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.title, style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: AppColors.t1)),
                          Text('${e.category} · ${DateFormat("dd MMM yyyy").format(e.date)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, color: AppColors.t3)),
                        ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(formatCurrency(e.amount), style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, fontWeight: FontWeight.w800,
                          color: AppColors.t1)),
                        const Gap(4),
                        GestureDetector(
                          onTap: () => ref.read(expenseProvider.notifier).delete(e.id),
                          child: const Icon(Symbols.delete, size: 15,
                            color: AppColors.red)),
                      ]),
                    ]),
                  );
                }),
        ),
      ]),
    );
  }

  void _addSheet(BuildContext context, WidgetRef ref) {
    final title  = TextEditingController();
    final amount = TextEditingController();
    String category = 'Other';
    DateTime date = DateTime.now();
    final cats = ['Rent','Salary','Utilities','Travel','Food',
                  'Marketing','Equipment','Other'];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) {
          bool saving = false;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(99)))),
                  const Gap(16),
                  Text('Add Expense', style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w800)),
                  const Gap(16),
                  TextField(controller: title,
                    decoration: InputDecoration(labelText: 'Title *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10))),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5)),
                  const Gap(10),
                  TextField(controller: amount,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Amount (₹)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10))),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5)),
                  const Gap(10),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: InputDecoration(labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10))),
                    items: cats.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c, style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5)))).toList(),
                    onChanged: (v) => ss(() => category = v ?? category)),
                  const Gap(20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving ? null : () async {
                        if (title.text.trim().isEmpty) return;
                        ss(() => saving = true);
                        try {
                          await ref.read(expenseProvider.notifier).add(Expense(
                            title: title.text.trim(),
                            amount: double.tryParse(amount.text) ?? 0,
                            category: category,
                            date: date));
                          if (ctx.mounted) Navigator.pop(ctx);
                        } finally {
                          if (ctx.mounted) ss(() => saving = false);
                        }
                      },
                      child: saving
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                        : const Text('Save Expense'))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SumCard extends StatelessWidget {
  final String label, value;
  final Color color, soft;
  const _SumCard(this.label, this.value, this.color, this.soft);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.plusJakartaSans(
          fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        const Gap(3),
        Text(value, style: GoogleFonts.plusJakartaSans(
          fontSize: 13, fontWeight: FontWeight.w900, color: color),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    ),
  );
}
