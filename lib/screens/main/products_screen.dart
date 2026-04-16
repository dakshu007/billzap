// lib/screens/main/products_screen.dart
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

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prods = ref.watch(productProvider);
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
        title: Text('Products & Services', style: GoogleFonts.plusJakartaSans(
          fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.t1)),
        actions: [
          IconButton(
            icon: const Icon(Symbols.add_box, color: AppColors.brand),
            onPressed: () => _addSheet(context, ref)),
        ],
      ),
      body: prods.isEmpty
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Symbols.inventory_2, size: 48, color: AppColors.t4), const Gap(10),
            Text('No products yet', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
            const Gap(6),
            Text('Build your catalog for faster invoicing',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.t3)),
            const Gap(16),
            ElevatedButton.icon(
              onPressed: () => _addSheet(context, ref),
              icon: const Icon(Symbols.add_box, size: 18),
              label: const Text('Add Product')),
          ]))
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
            itemCount: prods.length,
            itemBuilder: (_, i) {
              final p = prods[i];
              final isService = p.isService;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.card,
                  borderRadius: BorderRadius.circular(13), border: Border.all(color: AppColors.border)),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isService ? AppColors.purpleSoft : AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(7)),
                    child: Text(isService ? 'SVC' : 'GST',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800,
                        color: isService ? AppColors.purple : AppColors.brand))),
                  const Gap(12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.name, style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.t1)),
                    if (p.hsnCode.isNotEmpty)
                      Text('${isService ? 'SAC' : 'HSN'}: ${p.hsnCode} \u00b7 ${p.unit}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.t3))
                    else
                      Text(p.unit, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.t3)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(formatCurrency(p.price), style: GoogleFonts.plusJakartaSans(
                      fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.brand)),
                    Text('GST ${p.gstRate.toInt()}%', style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, color: AppColors.green, fontWeight: FontWeight.w600)),
                    const Gap(2),
                    GestureDetector(
                      onTap: () => ref.read(productProvider.notifier).delete(p.id),
                      child: const Icon(Symbols.delete, size: 16, color: AppColors.red)),
                  ]),
                ]),
              );
            }),
    ),
    );
  }

  void _addSheet(BuildContext context, WidgetRef ref) {
    final name  = TextEditingController();
    final hsn   = TextEditingController();
    final price = TextEditingController();
    double gstRate   = 18;
    bool   isService = false;
    bool   saving    = false;

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
            Text('Add Product / Service', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
            const Gap(16),
            TextField(controller: name,
              decoration: const InputDecoration(labelText: 'Name *',
                border: OutlineInputBorder()),
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5)),
            const Gap(10),
            Row(children: [
              Expanded(child: TextField(controller: hsn,
                decoration: const InputDecoration(labelText: 'HSN / SAC',
                  border: OutlineInputBorder()),
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5))),
              const Gap(10),
              Expanded(child: TextField(controller: price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (\u20b9)',
                  border: OutlineInputBorder()),
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5))),
            ]),
            const Gap(12),
            // GST rate selector
            Text('GST Rate', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.t3, fontWeight: FontWeight.w600)),
            const Gap(6),
            Row(children: [0, 5, 12, 18, 28].map((r) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => ss(() => gstRate = r.toDouble()),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: gstRate == r ? AppColors.brand : AppColors.bg,
                    borderRadius: BorderRadius.circular(8)),
                  child: Text('$r%', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700,
                    color: gstRate == r ? Colors.white : AppColors.t2)),
                ),
              ))).toList()),
            const Gap(12),
            // Type selector
            Row(children: [
              Text('Type: ', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.t2)),
              const Gap(8),
              GestureDetector(
                onTap: () => ss(() => isService = false),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: !isService ? AppColors.brand : AppColors.bg,
                    borderRadius: BorderRadius.circular(8)),
                  child: Text('Goods', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700,
                    color: !isService ? Colors.white : AppColors.t2)))),
              const Gap(8),
              GestureDetector(
                onTap: () => ss(() => isService = true),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isService ? AppColors.purple : AppColors.bg,
                    borderRadius: BorderRadius.circular(8)),
                  child: Text('Service', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700,
                    color: isService ? Colors.white : AppColors.t2)))),
            ]),
            const Gap(20),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: saving ? null : () async {
                if (name.text.trim().isEmpty) return;
                ss(() => saving = true);
                try {
                  await ref.read(productProvider.notifier).add(Product(
                    name: name.text.trim(), hsnCode: hsn.text.trim(),
                    price: double.tryParse(price.text) ?? 0,
                    gstRate: gstRate, isService: isService));
                  if (ctx.mounted) Navigator.pop(ctx);
                } finally {
                  if (ctx.mounted) ss(() => saving = false);
                }
              },
              child: saving
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save Product'))),
          ]),
        ),
      )),
  }
}
