// lib/screens/main/products_screen.dart
// UX upgrades: pull-to-refresh, swipe-to-delete, initial skeleton,
// success haptics on add.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:billzap/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../theme/app_theme.dart';
import '../../design/components.dart';
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
              style: TextStyle(color: AppColors.red))),
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
        title: Text(tr('prod.title', ref), style: AppFont.sans(
          fontSize: 21, fontWeight: FontWeight.w700,
          letterSpacing: -0.5, color: AppColors.t1)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: AppIconButton(
              icon: Symbols.add,
              background: AppColors.brand,
              foreground: AppColors.onBrand,
              onTap: () => _addSheet(context, ref))),
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
                    Text(tr('prod.no_products', ref), style: AppFont.sans(
                      fontSize: 16, fontWeight: FontWeight.w600)),
                    const Gap(6),
                    Text(tr('prod.no_products', ref), style: AppFont.sans(
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
                    child: GestureDetector(
                      onTap: () => _editSheet(context, ref, p),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border)),
                        child: Row(children: [
                          Container(width: 42, height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.brandSoft,
                              borderRadius: BorderRadius.circular(14)),
                            child: Center(
                              child: Icon(Symbols.inventory_2, size: 20, color: AppColors.brand))),
                          const Gap(12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppFont.sans(
                                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.t1))),
                              // Stock badge — only shown when tracking is on.
                              if (p.tracksStock) _StockBadge(p: p),
                            ]),
                            const Gap(2),
                            Row(children: [
                              Text(formatCurrency(p.price),
                                style: AppFont.sans(
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: AppColors.t2)),
                              // Profit-margin chip — only when a cost is set.
                              if (p.marginPercent != null) ...[
                                const Gap(8),
                                _MarginChip(margin: p.marginPercent!),
                              ],
                            ]),
                            if (p.hsnCode.isNotEmpty)
                              Text('HSN: ${p.hsnCode}', style: AppFont.sans(
                                fontSize: 10.5, color: AppColors.t4)),
                          ])),
                          IconButton(
                            icon: Icon(Symbols.delete, size: 18, color: AppColors.red),
                            tooltip: tr('common.delete', ref),
                            onPressed: () async {
                              if (await _confirmDelete(p)) {
                                await _doDelete(p);
                              }
                            },
                          ),
                        ]),
                      ),
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
      borderRadius: BorderRadius.circular(18),
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
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ],
    ),
  );

  void _addSheet(BuildContext context, WidgetRef ref) =>
      _showProductSheet(context, ref, existing: null);

  void _editSheet(BuildContext context, WidgetRef ref, Product p) =>
      _showProductSheet(context, ref, existing: p);

  /// Shared add/edit form. When `existing` is null we add; otherwise we
  /// mutate the passed product in place and save through `update`.
  void _showProductSheet(BuildContext context, WidgetRef ref,
      {required Product? existing}) {
    final isEdit = existing != null;
    final name  = TextEditingController(text: existing?.name ?? '');
    final price = TextEditingController(
        text: existing != null && existing.price > 0
            ? existing.price.toStringAsFixed(0) : '');
    final cost  = TextEditingController(
        text: existing != null && existing.cost > 0
            ? existing.cost.toStringAsFixed(0) : '');
    final hsn   = TextEditingController(text: existing?.hsnCode ?? '');
    final unit  = TextEditingController(text: existing?.unit ?? 'Nos');
    final stock = TextEditingController(
        text: existing != null && existing.stock >= 0
            ? existing.stock.toStringAsFixed(0) : '');
    final lowAt = TextEditingController(
        text: existing != null && existing.lowStockAt > 0
            ? existing.lowStockAt.toStringAsFixed(0) : '');
    bool trackStock = existing?.tracksStock ?? false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) {
          bool saving = false;
          // Live margin preview as the user types price & cost.
          double? livePrice = double.tryParse(price.text);
          double? liveCost  = double.tryParse(cost.text);
          double? livePct;
          if (livePrice != null && liveCost != null &&
              livePrice > 0 && liveCost > 0) {
            livePct = ((livePrice - liveCost) / livePrice) * 100;
          }
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: SingleChildScrollView(child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(99)))),
                  const Gap(16),
                  Text(isEdit ? 'Edit Product' : trGlobal('prod.add_new'),
                    style: AppFont.sans(
                      fontSize: 18, fontWeight: FontWeight.w600,
                      color: AppColors.t1)),
                  const Gap(16),
                  _SheetField(name, label: trGlobal('prod.name')),
                  const Gap(10),
                  Row(children: [
                    Expanded(child: _SheetField(price,
                      label: trGlobal('set.price'),
                      type: TextInputType.number,
                      onChanged: (_) => ss(() {}))),
                    const Gap(10),
                    // Cost field — feeds the margin calc above.
                    Expanded(child: _SheetField(cost,
                      label: 'Cost (optional)',
                      type: TextInputType.number,
                      onChanged: (_) => ss(() {}))),
                  ]),
                  if (livePct != null) ...[
                    const Gap(8),
                    Row(children: [
                      Icon(Symbols.trending_up, size: 16, color: AppColors.green),
                      const Gap(6),
                      Text('Margin: ${livePct.toStringAsFixed(1)}%',
                        style: AppFont.sans(
                          fontSize: 12.5, fontWeight: FontWeight.w700,
                          color: AppColors.green)),
                    ]),
                  ],
                  const Gap(10),
                  Row(children: [
                    Expanded(child: _SheetField(unit,
                      label: trGlobal('prod.unit'))),
                    const Gap(10),
                    Expanded(child: _SheetField(hsn,
                      label: trGlobal('create.hsn'),
                      type: TextInputType.number)),
                  ]),
                  const Gap(14),
                  // Inventory section ──────────────────────────────────
                  Row(children: [
                    Icon(Symbols.inventory, size: 18, color: AppColors.t2),
                    const Gap(8),
                    Text('Track stock',
                      style: AppFont.sans(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: AppColors.t1)),
                    const Spacer(),
                    Switch(value: trackStock,
                      onChanged: (v) => ss(() => trackStock = v)),
                  ]),
                  if (trackStock) ...[
                    const Gap(8),
                    Row(children: [
                      Expanded(child: _SheetField(stock,
                        label: 'Stock on hand',
                        type: TextInputType.number)),
                      const Gap(10),
                      Expanded(child: _SheetField(lowAt,
                        label: 'Low-stock alert at',
                        type: TextInputType.number)),
                    ]),
                  ],
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
                          final priceVal = double.tryParse(price.text) ?? 0;
                          final costVal  = double.tryParse(cost.text)  ?? 0;
                          final stockVal = trackStock
                              ? (double.tryParse(stock.text) ?? 0) : -1.0;
                          final lowAtVal = trackStock
                              ? (double.tryParse(lowAt.text) ?? 0) : 0.0;
                          if (isEdit) {
                            existing.name = name.text.trim();
                            existing.price = priceVal;
                            existing.cost = costVal;
                            existing.hsnCode = hsn.text.trim();
                            existing.unit = unit.text.trim();
                            existing.stock = stockVal;
                            existing.lowStockAt = lowAtVal;
                            await ref.read(productProvider.notifier)
                                .update(existing);
                          } else {
                            await ref.read(productProvider.notifier).add(Product(
                              name: name.text.trim(),
                              price: priceVal,
                              cost: costVal,
                              hsnCode: hsn.text.trim(),
                              unit: unit.text.trim(),
                              stock: stockVal,
                              lowStockAt: lowAtVal));
                          }
                          if (ctx.mounted) {
                            HapticFeedback.mediumImpact();
                            Navigator.pop(ctx);
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(isEdit
                                  ? '${name.text.trim()} updated ✓'
                                  : '${name.text.trim()} added ✓'),
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
              )),
            ),
          );
        },
      ),
    );
  }
}

// ── Helper widgets ───────────────────────────────────────────────────

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? type;
  final ValueChanged<String>? onChanged;
  const _SheetField(this.controller, {
    required this.label, this.type, this.onChanged});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: type,
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
    style: AppFont.sans(fontSize: 13.5));
}

class _MarginChip extends StatelessWidget {
  final double margin;
  const _MarginChip({required this.margin});

  @override
  Widget build(BuildContext context) {
    final positive = margin >= 0;
    final color = positive ? AppColors.green : AppColors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(99)),
      child: Text('${margin.toStringAsFixed(0)}%',
        style: AppFont.sans(
          fontSize: 10.5, fontWeight: FontWeight.w600, color: color)));
  }
}

class _StockBadge extends StatelessWidget {
  final Product p;
  const _StockBadge({required this.p});

  @override
  Widget build(BuildContext context) {
    final Color bg, fg;
    final String label;
    if (p.isOutOfStock) {
      bg = AppColors.red.withOpacity(0.15);
      fg = AppColors.red;
      label = 'Out';
    } else if (p.isLowStock) {
      bg = AppColors.orange.withOpacity(0.15);
      fg = AppColors.orange;
      label = '${p.stock.toStringAsFixed(0)} left';
    } else {
      bg = AppColors.brand.withOpacity(0.10);
      fg = AppColors.brand;
      label = '${p.stock.toStringAsFixed(0)} ${p.unit}';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(label,
        style: AppFont.sans(
          fontSize: 10.5, fontWeight: FontWeight.w600, color: fg)));
  }
}
