// lib/screens/onboarding/onboarding_screen.dart
// First-launch onboarding: language → business profile → home
// Saves to Hive 'settings' box so it doesn't show again

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:billzap/theme/app_icons.dart';
import 'package:gap/gap.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../../theme/app_theme.dart';
import '../../i18n/translations.dart';
import '../../widgets/language_picker.dart';
import '../../widgets/country_picker.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../tax/countries.dart';
import '../../tax/profiles.dart';
import '../../tax/regions.dart';
import '../../tax/tax_profile.dart';

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
  /// Backs the region box for countries with no region list.
  final _stateCtl = TextEditingController();
  // Where the shop trades. India by default, which is what every
  // install had before this question existed.
  String _country = 'IN';

  bool _saving = false;

  @override
  void dispose() {
    _pc.dispose();
    _nameCtl.dispose();
    _phoneCtl.dispose();
    _gstinCtl.dispose();
    _addrCtl.dispose();
    _cityCtl.dispose();
    _stateCtl.dispose();
    super.dispose();
  }

  void _nextStep() {
    HapticFeedback.lightImpact();
    if (_step < 3) {
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

  // Asked before the profile step because the answer changes what that
  // step should say: GSTIN in India, TRN in the UAE, VAT number in
  // Saudi, nothing at all where no profile exists.
  Widget _countryStep() {
    final country = countryFor(_country);
    final profile = resolveProfile(countryCode: _country);
    // Same three states as Settings. A rate pre-filled from the table is
    // neither "built in" nor "nothing" and must not be shown as either.
    final (noticeKey, noticeIcon) = switch (profile.confidence) {
      TaxConfidence.verified => ('onboard.country_known', Symbols.verified),
      TaxConfidence.unconfirmed => ('set.tax_unconfirmed', Symbols.help),
      TaxConfidence.selfDeclared => ('onboard.country_custom', Symbols.tune),
    };
    final known = profile.confidence == TaxConfidence.verified;
    // The middle state is the only one that asks the shopkeeper to go
    // and check something, so it is the only one tinted as a warning.
    final needsConfirming = profile.confidence == TaxConfidence.unconfirmed;
    final flag = countryFlag(_country);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(12),
          Text(trGlobal('onboard.country_title'),
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700, height: 1.2)),
          const Gap(8),
          Text(trGlobal('onboard.country_sub'),
              style: TextStyle(fontSize: 14.5, color: AppColors.t3)),
          const Gap(22),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              final picked = await pickCountry(context, selected: _country);
              if (picked != null) {
                setState(() {
                  _country = picked.code;
                  // A Tamil Nadu address on a Japanese bill is the bug
                  // this whole change is about.
                  _state = '';
                  _stateCtl.clear();
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  // The flag, so the shopkeeper can confirm the choice
                  // at a glance rather than by reading.
                  Container(
                    width: 44, height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.inset,
                      borderRadius: BorderRadius.circular(14)),
                    child: flag.isEmpty
                        ? Icon(Symbols.public,
                            color: AppColors.t3, size: 22)
                        : Text(flag, style: const TextStyle(fontSize: 23)),
                  ),
                  const Gap(13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(country?.name ?? 'Select a country',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFont.sans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.t1)),
                        const Gap(3),
                        Text(
                          country == null
                              ? ''
                              : '${country.currencySymbol.trim()} '
                                  '${country.currencyCode} · '
                                  '${profile.taxName}'
                                  '${profile.defaultRate > 0 ? " ${profile.defaultRate}%" : ""}',
                          style: AppFont.sans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.t3),
                        ),
                      ],
                    ),
                  ),
                  Icon(Symbols.chevron_right, color: AppColors.t3, size: 22),
                ],
              ),
            ),
          ),
          const Gap(16),
          // Say plainly which of the two states this country is in. A
          // shopkeeper deserves to know whether the app knows their tax
          // law or is about to ask them for it.
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: known
                  ? AppColors.brandSofter
                  : needsConfirming
                      ? AppColors.orangeSoft
                      : AppColors.inset,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(noticeIcon,
                    size: 18,
                    color: known
                        ? AppColors.brand
                        : needsConfirming
                            ? AppColors.orange
                            : AppColors.t3),
                const Gap(10),
                Expanded(
                  child: Text(
                    trGlobal(noticeKey),
                    style: AppFont.sans(
                        fontSize: 13,
                        height: 1.45,
                        fontWeight:
                            needsConfirming ? FontWeight.w600 : FontWeight.w400,
                        color:
                            needsConfirming ? AppColors.orange : AppColors.t2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
      await settings.put('business_country', _country);

      // Also write a real Business, because that — not these loose
      // keys — is what taxProfileProvider reads. Without it the country
      // chosen here would be remembered and never used.
      final existing = ref.read(businessProvider.notifier);
      await existing.save((ref.read(businessProvider) ?? Business()).copyWith(
        name: _nameCtl.text.trim(),
        phone: _phoneCtl.text.trim(),
        gstin: _gstinCtl.text.trim().toUpperCase(),
        address: _addrCtl.text.trim(),
        city: _cityCtl.text.trim(),
        state: _state,
        countryCode: _country,
        customCurrencySymbol:
            countryFor(_country)?.currencySymbol ?? r'$',
      ));
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
                  Row(children: List.generate(4, (i) => AnimatedContainer(
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
                        style: AppFont.sans(
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
                  _countryStep(),
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
                        style: AppFont.sans(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _saving
                      ? null
                      : (_step == 3 ? _finish : _nextStep),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: AppColors.onBrand,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(_step == 3
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
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(Symbols.bolt,
                color: AppColors.onBrand, size: 40, weight: 700),
          ),
          const Gap(28),
          Text(trGlobal('onboard.welcome'),
              style: AppFont.sans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.t1,
                  height: 1.2)),
          const Gap(8),
          Text(trGlobal('onboard.welcome_sub'),
              style: AppFont.sans(
                  fontSize: 15, color: AppColors.t3, height: 1.5)),
          const Gap(28),
          // Language picker mini-section
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
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
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.brandSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Symbols.translate,
                          color: AppColors.brand, size: 20),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(trGlobal('set.language'),
                              style: AppFont.sans(
                                  fontSize: 14, fontWeight: FontWeight.w700)),
                          const Gap(2),
                          Text(
                            currentLanguage(ref.watch(languageProvider)).name,
                            style: AppFont.sans(
                                fontSize: 12, color: AppColors.t3),
                          ),
                        ],
                      ),
                    ),
                    Icon(Symbols.chevron_right,
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
              style: AppFont.sans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.t1)),
          const Gap(6),
          Text(trGlobal('onboard.profile_sub'),
              style: AppFont.sans(
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
              style: AppFont.sans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.t2)),
          const Gap(6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            // A country with no region list gets a plain box. A
            // DropdownButton whose value is not among its items throws,
            // so the value is only passed through when it is one of
            // them — changing country clears it.
            child: _states.isEmpty
                ? TextField(
                    controller: _stateCtl,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Region or province',
                      hintStyle:
                          AppFont.sans(fontSize: 14, color: AppColors.t3),
                    ),
                    style: AppFont.sans(fontSize: 14, color: AppColors.t1),
                    onChanged: (v) => _state = v,
                  )
                : DropdownButton<String>(
                    value: _states.contains(_state) ? _state : null,
                    hint: Text('Select',
                        style:
                            AppFont.sans(fontSize: 14, color: AppColors.t3)),
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    icon: Icon(Symbols.expand_more, color: AppColors.t3),
                    style: AppFont.sans(fontSize: 14, color: AppColors.t1),
                    items: _states
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s)))
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
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.brand.withOpacity(0.2)),
            ),
            child: Row(children: [
              Icon(Symbols.info, color: AppColors.brand, size: 18),
              const Gap(10),
              Expanded(
                child: Text(trGlobal('onboard.edit_later_hint'),
                    style: AppFont.sans(
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
            child: Icon(Symbols.check_circle,
                color: AppColors.green, size: 56),
          ),
          const Gap(28),
          Text(trGlobal('onboard.done_title'),
              style: AppFont.sans(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.t1,
                  height: 1.2),
              textAlign: TextAlign.center),
          const Gap(10),
          Text(trGlobal('onboard.done_sub'),
              style: AppFont.sans(
                  fontSize: 14, color: AppColors.t3, height: 1.5),
              textAlign: TextAlign.center),
          const Gap(28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
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
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.brand, size: 18),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppFont.sans(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              Text(sub,
                  style: AppFont.sans(
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
              style: AppFont.sans(
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
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: AppColors.brand, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 14),
            ),
            style: AppFont.sans(fontSize: 14),
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
              style: AppFont.sans(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  /// The regions of whichever country was picked on the step before.
  ///
  /// This used to be a third hardcoded list of Indian states — 31 of
  /// them, disagreeing with the 20 in models.dart and the 37 that are
  /// actually GST jurisdictions. Three lists that could each be wrong
  /// in a different way, on a field that decides the tax split.
  ///
  /// Now there is one source per country: kStates in India, because its
  /// entries carry the GST code, and regions.dart everywhere else.
  List<String> get _states => _country.toUpperCase() == 'IN'
      ? kStates.map((s) => s.split(' (').first).toList()
      : (regionsFor(_country) ?? const <String>[]);
}
