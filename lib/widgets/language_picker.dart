// lib/widgets/language_picker.dart
// Pixel-perfect language picker with native scripts displayed
// Use as a full-screen dialog or in settings
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../i18n/translations.dart';
import '../theme/app_theme.dart';

// ── Full-screen language picker ───────────────────────────────
class LanguagePickerScreen extends ConsumerWidget {
  final bool isFirstLaunch;
  const LanguagePickerScreen({super.key, this.isFirstLaunch = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCode = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: isFirstLaunch ? null : AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        title: Text(
          tr('set.language', ref),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.t1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (isFirstLaunch) ...[
              const Gap(40),
              // Brand mark
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.brand, Color(0xFF4070FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brand.withOpacity(0.35),
                      blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: const Icon(Symbols.bolt,
                    color: Colors.white, size: 36, weight: 700),
              ),
              const Gap(20),
              Text('BillZap',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28, fontWeight: FontWeight.w900,
                  color: AppColors.t1, letterSpacing: -0.5)),
              const Gap(6),
              Text(
                tr('set.choose_language', ref),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, color: AppColors.t3),
              ),
              const Gap(28),
            ],

            // Language list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: supportedLanguages.length,
                itemBuilder: (ctx, i) {
                  final lang = supportedLanguages[i];
                  final selected = lang.code == currentCode;
                  return _LangTile(
                    lang: lang,
                    selected: selected,
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await ref.read(languageProvider.notifier).setLanguage(lang.code);
                      if (isFirstLaunch && context.mounted) {
                        // Close picker, app shell will pick up new language
                        Navigator.of(context).pop();
                      }
                    },
                  );
                },
              ),
            ),

            // Continue button (first launch only)
            if (isFirstLaunch)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tr('common.next', ref),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                        const Gap(6),
                        const Icon(Symbols.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Individual language tile ──────────────────────────────────
class _LangTile extends StatelessWidget {
  final AppLanguage lang;
  final bool selected;
  final VoidCallback onTap;

  const _LangTile({
    required this.lang,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected ? AppColors.brandSoft : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.brand : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Native script badge
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: selected
                      ? const LinearGradient(
                          colors: [AppColors.brand, Color(0xFF4070FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight)
                      : null,
                    color: selected ? null : AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: selected ? null : Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      lang.flag,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: selected ? Colors.white : AppColors.t2,
                      ),
                    ),
                  ),
                ),
                const Gap(14),
                // Language names
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: selected ? AppColors.brand : AppColors.t1,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        lang.englishName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: selected
                            ? AppColors.brand.withOpacity(0.8)
                            : AppColors.t3,
                        ),
                      ),
                    ],
                  ),
                ),
                // Check mark
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: selected ? 24 : 20,
                  height: selected ? 24 : 20,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.brand : Colors.transparent,
                    border: Border.all(
                      color: selected ? AppColors.brand : AppColors.border,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: selected
                    ? const Icon(Symbols.check,
                        color: Colors.white, size: 16, weight: 800)
                    : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Compact language pill (for top nav, etc) ──────────────────
class LanguagePill extends ConsumerWidget {
  const LanguagePill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(languageProvider);
    final lang = currentLanguage(code);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const LanguagePickerScreen(),
        ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.brandSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.brand.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Symbols.translate,
                size: 16, color: AppColors.brand),
            const Gap(6),
            Text(
              lang.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.brand,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
