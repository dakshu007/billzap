// ── PATCH: Replace the _AboutPanel class in your settings_screen.dart with this ──
// Adds a "Language" option at the top of the About tab

class _AboutPanel extends ConsumerWidget {
  const _AboutPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = currentLanguage(ref.watch(languageProvider));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Language picker tile ──
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const LanguagePickerScreen(),
                ));
              },
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.brand, Color(0xFF4070FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Symbols.translate,
                        color: Colors.white, size: 20),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('set.language', ref),
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.t1)),
                        const Gap(2),
                        Text(currentLang.name,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12, color: AppColors.t3)),
                      ],
                    ),
                  ),
                  const Icon(Symbols.chevron_right,
                      color: AppColors.t3, size: 22),
                ]),
              ),
            ),
          ),
        ),

        // ── About card ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: [
            const Icon(Symbols.bolt, size: 48, color: AppColors.brand),
            const Gap(8),
            Text('BillZap',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.t1)),
            Text(tr('splash.tagline', ref),
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: AppColors.t3)),
            const Gap(16),
            const Divider(),
            const Gap(12),
            _InfoRow(Symbols.check_circle, tr('set.version', ref), '1.3.0',
                AppColors.green),
            _InfoRow(Symbols.wifi_off, tr('set.offline', ref),
                tr('set.no_internet', ref), AppColors.brand),
            _InfoRow(Symbols.lock, tr('set.privacy', ref),
                tr('set.data_on_device', ref), AppColors.purple),
            _InfoRow(Symbols.currency_rupee, tr('set.price', ref),
                tr('set.always_free', ref), AppColors.green),
            const Gap(16),
            Text('© 2026 BillZap Technologies',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: AppColors.t4)),
          ]),
        ),
      ]),
    );
  }
}
