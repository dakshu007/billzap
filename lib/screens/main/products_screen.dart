// lib/screens/main/products_screen.dart
import 'package:flutter/material.dart';
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
    final products = ref.watch(productProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.card,
        title: Text('Products', style: GoogleFonts.plusJakartaSans(
          fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.t1)),
        actions: [
          IconButton(
            icon: const Icon(Symbols.add_box, color: AppColors.brand),
            onPressed: () => _addSheet(context, ref)),
        ],
      ),
      body: products.isEmpty
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Symbols.inventory_2, size: 48, color: AppColors.t4),
            const Gap(10),
            Text('No products yet', style: GoogleFonts.plusJakartaSans(
              fontSize: 16, fontWeight: FontWeight.w800)),
            const Gap(6),
            Text('Add products to use in invoices', style: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: AppColors.t3)),
            const Gap(16),
            ElevatedButton.icon(
              onPressed: () => _addSheet(context, ref),
              icon: const Icon(Symbols.add_box, size: 18),
              label: const Text('Add Product')),
          ]))
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
            itemCount: products.length,
            itemBuilder: (ctx, i) {
              final p = products[i];
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
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(11)),
                    child: const Center(
                      child: Icon(Symbols.inventory_2, size: 20, color: AppColors.brand))),
                  const Gap(12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.name, style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.t1)),
                    Text(formatCurrency(p.price), style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: AppColors.t3)),
                    if (p.hsnCode.isNotEmpty)
                      Text('HSN: ${p.hsnCode}', style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5, color: AppColors.t4)),
                  ])),
                  GestureDetector(
                    onTap: () => _confirmDelete(ctx, ref, p),
                    child: const Icon(Symbols.delete, size: 16, color: AppColors.red)),
                ]),
              );
            }),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Product p) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('${p.name} will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(productProvider.notifier).delete(p.id);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
  }

  void _addSheet(BuildContext context, WidgetRef ref) {
    final name  = TextEditingController();
    final price = TextEditingController();
    final hsn   = TextEditingController();
    final unit  = TextEditingController(text: 'Nos');

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
                  Text('Add Product', style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w800)),
                  const Gap(16),
                  TextField(controller: name,
                    decoration: InputDecoration(labelText: 'Product Name *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10))),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5)),
                  const Gap(10),
                  Row(children: [
                    Expanded(child: TextField(controller: price,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Price (₹)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10))),
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5))),
                    const Gap(10),
                    Expanded(child: TextField(controller: unit,
                      decoration: InputDecoration(labelText: 'Unit',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10))),
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5))),
                  ]),
                  const Gap(10),
                  TextField(controller: hsn,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'HSN/SAC Code',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10))),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5)),
                  const Gap(20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving ? null : () async {
                        if (name.text.trim().isEmpty) return;
                        ss(() => saving = true);
                        try {
                          await ref.read(productProvider.notifier).add(Product(
                            name: name.text.trim(),
                            price: double.tryParse(price.text) ?? 0,
                            hsnCode: hsn.text.trim(),
                            unit: unit.text.trim()));
                          if (ctx.mounted) Navigator.pop(ctx);
                        } finally {
                          if (ctx.mounted) ss(() => saving = false);
                        }
                      },
                      child: saving
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                        : const Text('Save Product'))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
