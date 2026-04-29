// lib/screens/main/catalog_screen.dart
// User's catalog of saved items. Shown in Create Invoice via "From Catalog".
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:gap/gap.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../theme/app_theme.dart';
import '../../services/gst_classifier.dart';
import '../../i18n/translations.dart';

class CatalogItem {
  final String id;
  final String name;
  final double price;
  final int gstRate;
  final String hsnCode;
  final String unit;

  CatalogItem({
    required this.id,
    required this.name,
    required this.price,
    required this.gstRate,
    this.hsnCode = '',
    this.unit = 'Nos',
  });

  Map<String, dynamic> toMap() => {
        'id': id, 'name': name, 'price': price,
        'gstRate': gstRate, 'hsnCode': hsnCode, 'unit': unit,
      };

  static CatalogItem fromMap(Map m) => CatalogItem(
        id: m['id'] as String,
        name: m['name'] as String,
        price: (m['price'] as num).toDouble(),
        gstRate: m['gstRate'] as int,
        hsnCode: m['hsnCode'] as String? ?? '',
        unit: m['unit'] as String? ?? 'Nos',
      );
}

class CatalogService {
  static const _boxName = 'catalog';

  static Future<List<CatalogItem>> getAll() async {
    final box = await Hive.openBox(_boxName);
    return box.values
        .map((v) => CatalogItem.fromMap(Map.from(v as Map)))
        .toList();
  }

  static Future<void> add(CatalogItem item) async {
    final box = await Hive.openBox(_boxName);
    await box.put(item.id, item.toMap());
  }

  static Future<void> delete(String id) async {
    final box = await Hive.openBox(_boxName);
    await box.delete(id);
  }
}

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  List<CatalogItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await CatalogService.getAll();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.t1),
        title: Text(trGlobal('cat.title'),
            style: GoogleFonts.plusJakartaSans(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: AppColors.t1)),
        actions: [
          IconButton(
            icon: const Icon(Symbols.add, color: AppColors.brand, size: 26),
            onPressed: _addSheet,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _empty()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
                  itemCount: _items.length,
                  itemBuilder: (ctx, i) {
                    final item = _items[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.brandSoft,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Center(
                              child: Icon(Symbols.shopping_basket,
                                  size: 22, color: AppColors.brand)),
                        ),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name,
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.t1)),
                              const Gap(2),
                              Row(children: [
                                Text('₹${item.price.toStringAsFixed(0)}',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12, color: AppColors.t3)),
                                const Gap(8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandSoft,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('${item.gstRate}% GST',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.brand)),
                                ),
                              ]),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Symbols.delete,
                              size: 20, color: AppColors.red),
                          onPressed: () => _confirmDelete(item),
                        ),
                      ]),
                    );
                  },
                ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Symbols.inventory_2, size: 56, color: AppColors.t4),
        const Gap(12),
        Text(trGlobal('cat.empty'),
            style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w800)),
        const Gap(6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            trGlobal('cat.empty_hint'),
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: AppColors.t3, height: 1.4),
          ),
        ),
        const Gap(20),
        ElevatedButton.icon(
          onPressed: _addSheet,
          icon: const Icon(Symbols.add, size: 18),
          label: Text(trGlobal('cat.add_first')),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brand,
            foregroundColor: Colors.white,
          ),
        ),
      ]),
    );
  }

  void _addSheet() {
    final name = TextEditingController();
    final price = TextEditingController();
    final hsn = TextEditingController();
    final unit = TextEditingController(text: 'Nos');
    int detectedGst = 18;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) {
        bool saving = false;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                )),
                const Gap(16),
                Text(trGlobal('cat.add_title'),
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const Gap(4),
                Text(trGlobal('cat.gst_auto_hint'),
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: AppColors.t3)),
                const Gap(16),
                TextField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: trGlobal('cat.item_name'),
                    hintText: trGlobal('cat.item_hint'),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (v) {
                    final r = GstClassifier.classify(v);
                    if (r >= 0) ss(() => detectedGst = r);
                  },
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                ),
                const Gap(10),
                if (name.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.brand.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Symbols.auto_awesome,
                          size: 18, color: AppColors.brand),
                      const Gap(8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$detectedGst% GST',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.brand)),
                            Text(GstClassifier.categoryFor(detectedGst),
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11, color: AppColors.t3)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                const Gap(10),
                Row(children: [
                  Expanded(
                      child: TextField(
                    controller: price,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: trGlobal('cat.price'),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                  )),
                  const Gap(10),
                  Expanded(
                      child: TextField(
                    controller: unit,
                    decoration: InputDecoration(
                      labelText: trGlobal('cat.unit'),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                  )),
                ]),
                const Gap(10),
                TextField(
                  controller: hsn,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: trGlobal('cat.hsn'),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                ),
                const Gap(20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (name.text.trim().isEmpty) return;
                            ss(() => saving = true);
                            try {
                              await CatalogService.add(CatalogItem(
                                id: DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString(),
                                name: name.text.trim(),
                                price: double.tryParse(price.text) ?? 0,
                                gstRate: detectedGst,
                                hsnCode: hsn.text.trim(),
                                unit: unit.text.trim(),
                              ));
                              if (ctx.mounted) Navigator.pop(ctx);
                              await _load();
                            } finally {
                              if (ctx.mounted) ss(() => saving = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(trGlobal('cat.save')),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _confirmDelete(CatalogItem item) {
    HapticFeedback.lightImpact();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(trGlobal('cat.delete_title')),
        content: Text('${item.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(trGlobal('common.cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await CatalogService.delete(item.id);
              await _load();
            },
            child: Text(trGlobal('common.delete'),
                style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}
