// lib/screens/main/products_screen.dart
// UX upgrades: pull-to-refresh, swipe-to-delete, initial skeleton,
// success haptics on add.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_spacing.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../i18n/translations.dart';
import '../../widgets/skeleton.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});
  @override
  ConsumerState<ProductsScreen> createState() => _ProductsState();
}

class _ProductsState extends ConsumerState<ProductsScreen> {
  bool _firstFrame = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 220), () {
        if (mounted) setState(() => _firstFrame = false);
      });
    });
  }

  Future<void> _refresh() async {
    HapticFeedback.lightImpact();
    ref.read(productProvider.notifier).reload();
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  Future<bool> _confirmDelete(Product p) async {
    HapticFeedback.mediumImpact();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('common.delete', ref)),
        content: Text('${p.name} will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(tr('common.cancel', ref))),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(tr('common.delete', ref),
              style: const TextStyle(color: AppColors.red))),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _doDelete(Product p) async {
    await ref.read(productProvider.notifier).delete(p.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${p.name} deleted'),
      backgroundColor: AppColors.t1,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        iconTheme: IconThemeData(color: AppColors.t1),
        backgroundColor: AppColors.bg,
        title: Text(tr('prod.title', ref), style: GoogleFonts.plusJakartaSans(
          fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.t1)),
        actions: [
          IconButton(
            icon: const Icon(Symbols.add_box, color: AppColors.brand),
            onPressed: () => _addSheet(context, ref)),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.brand,
        onRefresh: _refresh,
        child: _firstFrame
          ? const SkeletonList()
          : products.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Symbols.inventory_2, size: 48, color: AppColors.t4),
                    const Gap(10),
                    Text(tr('prod.no_products', ref), style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, fontWeight: FontWeight.w800)),
                    const Gap(6),
                    Text(tr('prod.no_products', ref), style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: AppColors.t3)),
                    const Gap(16),
                    ElevatedButton.icon(
                      onPressed: () => _addSheet(context, ref),
                      icon: const Icon(Symbols.add_box, size: 18),
                      label: Text(tr('prod.add_new', ref))),
                  ]),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppSpacing.listScreen,
                itemCount: products.length,
                itemBuilder: (ctx, i) {
                  final p = products[i];
                  return Dismissible(
                    key: ValueKey('prod-${p.id}'),
                    direction: DismissDirection.endToStart,
                    background: _swipeBg(),
                    confirmDismiss: (_) => _confirmDelete(p),
                    onDismissed: (_) => _doDelete(p),
                    child: Container(
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
                          Text(p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.t1)),
                          Text(formatCurrency(p.price),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, color: AppColors.t3)),
                          if (p.hsnCode.isNotEmpty)
                            Text('HSN: ${p.hsnCode}', style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5, color: AppColors.t4)),
                        ])),
                        IconButton(
                          icon: const Icon(Symbols.delete, size: 18, color: AppColors.red),
                          tooltip: tr('common.delete', ref),
                          onPressed: () async {
                            if (await _confirmDelete(p)) {
                              await _doDelete(p);
                            }
                          },
                        ),
                      ]),
                    ),
                  );
                }),
      ),
    );
  }

  Widget _swipeBg() => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: AppColors.red,
      borderRadius: BorderRadius.circular(13),
    ),
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.symmetric(horizontal: 22),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Symbols.delete, color: Colors.white, size: 20),
        SizedBox(width: 6),
        Text('Delete',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13)),
      ],
    ),
  );

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
              // Theme-aware so the Add Product sheet flips with dark mode.
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
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
                  Text(trGlobal('prod.add_new'), style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w800)),
                  const Gap(16),
                  TextField(controller: name,
                    decoration: InputDecoration(labelText: trGlobal('prod.name'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10))),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5)),
                  const Gap(10),
                  Row(children: [
                    Expanded(child: TextField(controller: price,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: trGlobal('set.price'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10))),
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5))),
                    const Gap(10),
                    Expanded(child: TextField(controller: unit,
                      decoration: InputDecoration(labelText: trGlobal('prod.unit'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10))),
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5))),
                  ]),
                  const Gap(10),
                  TextField(controller: hsn,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: trGlobal('create.hsn'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10))),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5)),
                  const Gap(20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving ? null : () async {
                        if (name.text.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Text(trGlobal('cust.required')),
                            backgroundColor: AppColors.red));
                          return;
                        }
                        ss(() => saving = true);
                        try {
                          await ref.read(productProvider.notifier).add(Product(
                            name: name.text.trim(),
                            price: double.tryParse(price.text) ?? 0,
                            hsnCode: hsn.text.trim(),
                            unit: unit.text.trim()));
                          if (ctx.mounted) {
                            HapticFeedback.mediumImpact();
                            Navigator.pop(ctx);
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('${name.text.trim()} added ✓'),
                              backgroundColor: AppColors.green));
                          }
                        } finally {
                          if (ctx.mounted) ss(() => saving = false);
                        }
                      },
                      child: saving
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                        : Text(trGlobal('common.save')))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
