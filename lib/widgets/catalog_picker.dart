// lib/widgets/catalog_picker.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:gap/gap.dart';
import '../theme/app_theme.dart';
import '../screens/main/catalog_screen.dart';
import '../i18n/translations.dart';

class CatalogPicker {
  /// Shows a bottom sheet of catalog items.
  /// Returns the picked item or null if cancelled.
  static Future<CatalogItem?> show(BuildContext context) async {
    final items = await CatalogService.getAll();
    if (!context.mounted) return null;

    return showModalBottomSheet<CatalogItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scroll) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const Gap(12),
              Center(
                  child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              )),
              const Gap(14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(trGlobal('cat.from_catalog'),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    Text('${items.length}',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: AppColors.t3)),
                  ],
                ),
              ),
              const Gap(10),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Symbols.inventory_2,
                                  size: 48, color: AppColors.t4),
                              const Gap(10),
                              Text(trGlobal('cat.empty'),
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                              const Gap(6),
                              Text(
                                trGlobal('cat.empty_hint'),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12, color: AppColors.t3),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scroll,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final item = items[i];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(ctx, item);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: AppColors.border),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppColors.brandSoft,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Center(
                                      child: Icon(Symbols.shopping_basket,
                                          size: 20, color: AppColors.brand),
                                    ),
                                  ),
                                  const Gap(12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name,
                                            style:
                                                GoogleFonts.plusJakartaSans(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    color: AppColors.t1)),
                                        Text(
                                            '₹${item.price.toStringAsFixed(0)} · ${item.gstRate}% GST',
                                            style:
                                                GoogleFonts.plusJakartaSans(
                                                    fontSize: 12,
                                                    color: AppColors.t3)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Symbols.add_circle,
                                      size: 22, color: AppColors.brand),
                                ]),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
