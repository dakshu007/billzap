// lib/screens/onboarding/onboarding_screen.dart
// First-launch onboarding: language → business profile → home
// Saves to Hive 'settings' box so it doesn't show again

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:gap/gap.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../theme/app_theme.dart';
import '../../i18n/translations.dart';
import '../../widgets/language_picker.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pc = PageController();
  int _step = 0;

  // Profile fields
  final _nameCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _gstinCtl = TextEditingController();
  final _addrCtl = TextEditingController();
  final _cityCtl = TextEditingController();
  String _state = 'Tamil Nadu';

  bool _saving = false;

  @override
  void dispose() {
    _pc.dispose();
    _nameCtl.dispose();
    _phoneCtl.dispose();
    _gstinCtl.dispose();
    _addrCtl.dispose();
    _cityCtl.dispose();
    super.dispose();
  }

  void _nextStep() {
    HapticFeedback.lightImpact();
    if (_step < 2) {
      setState(() => _step++);
      _pc.animateToPage(_step,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic);
    }
  }

  void _prevStep() {
    if (_step > 0) {
      HapticFeedback.lightImpact();
      setState(() => _step--);
      _pc.animateToPage(_step,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic);
    }
  }

  Future<void> _finish() async {
    if (_nameCtl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(trGlobal('onboard.business_required')),
        backgroundColor: AppColors.red,
      ));
      return;
    }

    setState(() => _saving = true);
    try {
      // Save to settings box (the same box your app uses for business profile)
      final settings = await Hive.openBox('settings');
      await settings.put('business_name', _nameCtl.text.trim());
      await settings.put('business_phone', _phoneCtl.text.trim());
      await settings.put('business_gstin',
          _gstinCtl.text.trim().toUpperCase());
      await settings.put('business_address', _addrCtl.text.trim());
      await settings.put('business_city', _cityCtl.text.trim());
      await settings.put('business_state', _state);
      await settings.put('onboarded', true);

      if (!mounted) return;
      context.go('/home');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _skip() async {
    HapticFeedback.lightImpact();
    final settings = await Hive.openBox('settings');
    await settings.put('onboarded', true);
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Step indicator
                  Row(children: List.generate(3, (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    margin: const EdgeInsets.only(right: 6),
                    width: i == _step ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i <= _step ? AppColors.brand : AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ))),
                  TextButton(
                    onPressed: _skip,
                    child: Text(trGlobal('onboard.skip'),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.t3)),
                  ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pc,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _step = i),
                children: [
                  _welcomeStep(),
                  _profileStep(),
                  _doneStep(),
                ],
              ),
            ),

            // Footer buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Row(children: [
                if (_step > 0)
                  TextButton(
                    onPressed: _prevStep,
                    child: Text(trGlobal('common.back'),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _saving
                      ? null
                      : (_step == 2 ? _finish : _nextStep),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(_step == 2
                              ? trGlobal('onboard.get_started')
                              : trGlobal('common.next')),
                          const Gap(6),
                          const Icon(Symbols.arrow_forward, size: 18),
                        ]),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _welcomeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(24),
          Container(
            width: 72,
            height: 72,
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
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Symbols.bolt,
                color: Colors.white, size: 40, weight: 700),
          ),
          const Gap(28),
          Text(trGlobal('onboard.welcome'),
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.t1,
                  height: 1.2)),
          const Gap(8),
          Text(trGlobal('onboard.welcome_sub'),
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 15, color: AppColors.t3, height: 1.5)),
          const Gap(28),
          // Language picker mini-section
          Container(
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
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.brandSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Symbols.translate,
                          color: AppColors.brand, size: 20),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(trGlobal('set.language'),
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14, fontWeight: FontWeight.w700)),
                          const Gap(2),
                          Text(
                            currentLanguage(ref.watch(languageProvider)).name,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12, color: AppColors.t3),
                          ),
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
          const Gap(20),
          _featureRow(Symbols.bolt, trGlobal('onboard.feat_fast'),
              trGlobal('onboard.feat_fast_sub')),
          _featureRow(Symbols.wifi_off, trGlobal('onboard.feat_offline'),
              trGlobal('onboard.feat_offline_sub')),
          _featureRow(Symbols.lock, trGlobal('onboard.feat_private'),
              trGlobal('onboard.feat_private_sub')),
          _featureRow(Symbols.currency_rupee, trGlobal('onboard.feat_free'),
              trGlobal('onboard.feat_free_sub')),
        ],
      ),
    );
  }

  Widget _profileStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(16),
          Text(trGlobal('onboard.profile_title'),
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.t1)),
          const Gap(6),
          Text(trGlobal('onboard.profile_sub'),
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: AppColors.t3, height: 1.5)),
          const Gap(20),
          _field(trGlobal('onboard.business_name'), _nameCtl,
              hint: 'Ravi Electronics', icon: Symbols.storefront),
          _field(trGlobal('onboard.phone'), _phoneCtl,
              hint: '9876543210',
              icon: Symbols.phone,
              keyboard: TextInputType.phone),
          _field(trGlobal('onboard.gstin_optional'), _gstinCtl,
              hint: '33AAAAA0000A1Z5',
              icon: Symbols.badge,
              caps: true),
          _field(trGlobal('onboard.address'), _addrCtl,
              hint: '123 Main Road',
              icon: Symbols.home),
          _field(trGlobal('onboard.city'), _cityCtl,
              hint: 'Coimbatore',
              icon: Symbols.location_city),
          const Gap(8),
          Text(trGlobal('onboard.state'),
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.t2)),
          const Gap(6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButton<String>(
              value: _state,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              icon: const Icon(Symbols.expand_more, color: AppColors.t3),
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, color: AppColors.t1),
              items: _states
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _state = v);
              },
            ),
          ),
          const Gap(16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.brand.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Symbols.info, color: AppColors.brand, size: 18),
              const Gap(10),
              Expanded(
                child: Text(trGlobal('onboard.edit_later_hint'),
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.brand,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _doneStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Symbols.check_circle,
                color: AppColors.green, size: 56),
          ),
          const Gap(28),
          Text(trGlobal('onboard.done_title'),
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.t1,
                  height: 1.2),
              textAlign: TextAlign.center),
          const Gap(10),
          Text(trGlobal('onboard.done_sub'),
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, color: AppColors.t3, height: 1.5),
              textAlign: TextAlign.center),
          const Gap(28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              _summaryRow(Symbols.storefront,
                  _nameCtl.text.trim().isEmpty ? '—' : _nameCtl.text.trim()),
              if (_phoneCtl.text.trim().isNotEmpty)
                _summaryRow(Symbols.phone, _phoneCtl.text.trim()),
              if (_cityCtl.text.trim().isNotEmpty)
                _summaryRow(Symbols.location_on,
                    '${_cityCtl.text.trim()}, $_state'),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──
  Widget _featureRow(IconData icon, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.brand, size: 18),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              Text(sub,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: AppColors.t3)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctl, {
    String hint = '',
    IconData? icon,
    TextInputType? keyboard,
    bool caps = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.t2)),
          const Gap(6),
          TextField(
            controller: ctl,
            keyboardType: keyboard,
            textCapitalization:
                caps ? TextCapitalization.characters : TextCapitalization.words,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: icon != null
                  ? Icon(icon, size: 18, color: AppColors.t3)
                  : null,
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.brand, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 14),
            ),
            style: GoogleFonts.plusJakartaSans(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.brand),
        const Gap(10),
        Expanded(
          child: Text(text,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  static const _states = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar',
    'Chhattisgarh', 'Goa', 'Gujarat', 'Haryana',
    'Himachal Pradesh', 'Jharkhand', 'Karnataka', 'Kerala',
    'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya',
    'Mizoram', 'Nagaland', 'Odisha', 'Punjab',
    'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana',
    'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
    'Delhi', 'Chandigarh', 'Puducherry',
  ];
}
