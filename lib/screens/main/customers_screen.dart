// lib/screens/main/customers_screen.dart
// ✅ Delete dialog dark overlay fixed
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final custs = ref.watch(customerProvider);
    final invs  = ref.watch(invoiceProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          HapticFeedback.lightImpact();
          context.go('/home');
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false, backgroundColor: AppColors.card,
        title: Text('Customers', style: GoogleFonts.plusJakartaSans(
          fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.t1)),
        actions: [
          IconButton(
            icon: const Icon(Symbols.person_add, color: AppColors.brand),
            onPressed: () => _addSheet(context, ref)),
        ],
      ),
      body: custs.isEmpty
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Symbols.group, size: 48, color: AppColors.t4),
            const Gap(10),
            Text('No customers yet', style: GoogleFonts.plusJakartaSans(
              fontSize: 16, fontWeight: FontWeight.w800)),
            const Gap(6),
            Text('Add your first customer', style: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: AppColors.t3)),
            const Gap(16),
            ElevatedButton.icon(
              onPressed: () => _addSheet(context, ref),
              icon: const Icon(Symbols.person_add, size: 18),
              label: const Text('Add Customer')),
          ]))
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
            itemCount: custs.length,
            itemBuilder: (ctx, i) {
              final c   = custs[i];
              final ci  = invs.where((inv) => inv.customerName == c.name).toList();
              final tot = ci.fold<double>(0, (s, inv) => s + inv.grandTotal);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.card,
                  borderRadius: BorderRadius.circular(13), border: Border.all(color: AppColors.border)),
                child: Row(children: [
                  Container(width: 42, height: 42,
                    decoration: BoxDecoration(color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(11)),
                    child: Center(child: Text(c.name[0].toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.brand)))),
                  const Gap(12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.name, style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.t1)),
                    if (c.phone.isNotEmpty)
                      Text(c.phone, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.t3)),
                    if (c.gstin.isNotEmpty)
                      Text('GSTIN: ${c.gstin}', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.t4)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(formatCurrency(tot), style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.t1)),
                    Text('${ci.length} inv', style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5, color: AppColors.t3)),
                    const Gap(4),
                    // ✅ FIX: Use separate function to avoid dark overlay bug
                    GestureDetector(
                      onTap: () => _deleteCustomer(ctx, ref, c),
                      child: const Icon(Symbols.delete, size: 18, color: AppColors.red)),
                  ]),
                ]),
              );
            }),
    );
  }

  // ✅ FIX: Separate function with correct context
  void _deleteCustomer(BuildContext context, WidgetRef ref, Customer c) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete customer?'),
        content: Text('${c.name} will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ref.read(customerProvider.notifier).delete(c.id);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
  }

  void _addSheet(BuildContext context, WidgetRef ref) {
    final name  = TextEditingController();
    final phone = TextEditingController();
    final gstin = TextEditingController();
    final addr  = TextEditingController();
    bool saving = false;

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
            Text('Add Customer', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
            const Gap(16),
            TextField(controller: name,
              decoration: InputDecoration(labelText: 'Name *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5)),
            const Gap(10),
            TextField(controller: phone, keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: 'Phone',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5)),
            const Gap(10),
            Row(children: [
              Expanded(child: TextField(controller: gstin,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(labelText: 'GSTIN',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5))),
              const Gap(10),
              Expanded(child: TextField(controller: addr,
                decoration: InputDecoration(labelText: 'City',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5))),
            ]),
            const Gap(20),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: saving ? null : () async {
                if (name.text.trim().isEmpty) return;
                ss(() => saving = true);
                try {
                  await ref.read(customerProvider.notifier).add(Customer(
                    name: name.text.trim(), phone: phone.text.trim(),
                    gstin: gstin.text.trim().toUpperCase(), city: addr.text.trim()));
                  if (ctx.mounted) Navigator.pop(ctx);
                } finally {
                  if (ctx.mounted) ss(() => saving = false);
                }
              },
              child: saving
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save Customer'))),
          ]),
        ),
      )),
    ),
    );
  }
}
