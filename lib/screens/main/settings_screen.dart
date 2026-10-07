// lib/screens/main/settings_screen.dart
// Fully translated + Language picker tile in About panel
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/app_lock_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:billzap/theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_spacing.dart';
import '../../app_version.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import '../../design/motion.dart';
import '../../design/palette_scope.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../i18n/translations.dart';
import '../../utils/business_logo.dart';
import '../../utils/validators.dart';
import '../../utils/platform.dart';
import '../../widgets/language_picker.dart';
import '../../widgets/logo_thumb.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/country_picker.dart';
import '../../tax/countries.dart';
import '../../tax/regions.dart';
import '../../tax/tax_profile.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<SettingsScreen> {
  int _tab = 0;

  /// Horizontal offset the incoming panel travels from, signed by the
  /// direction of travel so forward and backward feel different.
  double _slideFrom = 0.06;

  void _selectTab(int i) {
    if (i == _tab) return;
    HapticFeedback.selectionClick();
    setState(() {
      _slideFrom = i > _tab ? 0.06 : -0.06;
      _tab = i;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: DesktopMaxWidth(maxWidth: 820, child: SafeArea(
        bottom: false,
        child: Column(children: [
        ScreenTitle(
          tr('set.title', ref),
          // Top corner, on every tab, so the language can be found by
          // someone who cannot yet read the tab names.
          trailing: const LanguagePill(),
          padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter, AppSpace.lg, AppSpace.gutter, AppSpace.lg),
        ),
        // (App Lock lives in the About tab — it groups with the rest of
        //  the security/info settings and keeps this header clean.)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter, 0, AppSpace.gutter, AppSpace.lg),
          child: SegmentedTabs(
            index: _tab,
            onSelect: _selectTab,
            labels: [
              tr('set.business', ref),
              (ref.watch(businessProvider)?.countryCode ?? 'IN') == 'IN'
                  ? tr('set.bank', ref)
                  : tr('dc.bank_short', ref),
              tr('set.invoice', ref),
              tr('set.about', ref),
            ],
          )),
        Expanded(
          child: AnimatedSwitcher(
            duration: AppMotion.base,
            switchInCurve: AppMotion.enter,
            switchOutCurve: AppMotion.exit,
            layoutBuilder: (current, previous) =>
                Stack(alignment: Alignment.topCenter, children: [
                  ...previous,
                  if (current != null) current,
                ]),
            transitionBuilder: (child, anim) {
              final incoming = child.key == ValueKey<int>(_tab);
              // Both halves travel the same way: the outgoing panel exits
              // opposite to the direction of travel, the incoming one
              // arrives from it.
              final dx = (incoming ? 1.0 : -1.0) * _slideFrom;
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(dx, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(_tab),
              child: const [
                _BusinessPanel(),
                _BankPanel(),
                _InvoicePanel(),
                _AboutPanel(),
              ][_tab],
            ),
          )),
      ]))),
    );
  }
}

class _BusinessPanel extends ConsumerStatefulWidget {
  const _BusinessPanel();
  @override
  ConsumerState<_BusinessPanel> createState() => _BusinessPanelState();
}

class _BusinessPanelState extends ConsumerState<_BusinessPanel> {
  late final TextEditingController _name, _gstin, _phone, _email, _addr, _city, _pin;
  /// Backs the region field for the four countries with no region list,
  /// where it is a plain box rather than a picker.
  late final TextEditingController _stateCtrl;
  String _state = 'Tamil Nadu';
  /// Empty until the shopkeeper changes it, which means "same as the
  /// country the shop bills under".
  String _addrCountry = '';
  bool _saving = false;
  String? _gstinErr, _phoneErr, _emailErr, _pinErr;

  @override
  void initState() {
    super.initState();
    final b = ref.read(businessProvider);
    _name  = TextEditingController(text: b?.name ?? '');
    _gstin = TextEditingController(text: b?.gstin ?? '');
    _phone = TextEditingController(text: b?.phone ?? '');
    _email = TextEditingController(text: b?.email ?? '');
    _addr  = TextEditingController(text: b?.address ?? '');
    _city  = TextEditingController(text: b?.city ?? '');
    _pin   = TextEditingController(text: b?.pincode ?? '');
    _state = b?.state ?? 'Tamil Nadu';
    _stateCtrl = TextEditingController(text: _state);
    _addrCountry = b?.addressCountryCode ?? '';
    _gstinErr = Validators.gstin(_gstin.text);
    _phoneErr = Validators.phone(_phone.text);
    _emailErr = Validators.email(_email.text);
    _pinErr   = Validators.pincode(_pin.text);
  }

  @override
  void dispose() {
    _name.dispose(); _gstin.dispose(); _phone.dispose(); _email.dispose();
    _addr.dispose(); _city.dispose(); _pin.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The address country, which is NOT necessarily the country the
    // shop bills under: a trader registered in Singapore may have the
    // premises in Malaysia. It defaults to the trading country and is
    // changeable here.
    final biz = ref.watch(businessProvider);
    final addrCountry = (_addrCountry.isNotEmpty
            ? _addrCountry
            : (biz?.effectiveAddressCountry ?? 'IN'))
        .toUpperCase();
    final isIndia = addrCountry == 'IN';
    // India keeps its coded list; everyone else gets their own regions
    // or, for the four single-settlement jurisdictions, nothing — and
    // the field below becomes free text.
    final regionOptions =
        isIndia ? kStates : (regionsFor(addrCountry) ?? const <String>[]);
    final regionNames =
        regionOptions.map((s) => s.split(' (')[0]).toList();
    // Only fall back to Tamil Nadu in India. Elsewhere an unrecognised
    // value means the shopkeeper has not picked yet, and showing them
    // an Indian state would be the bug this is fixing.
    final currentState = regionNames.contains(_state)
        ? _state
        : (isIndia ? 'Tamil Nadu' : '');
    final regionLabel = _regionLabelFor(addrCountry);

    // What the page is *about*, at the top: the identity every invoice
    // this shop sends will carry. A form with no subject is just nine
    // grey boxes.
    final filled = [
      _name.text.trim().isNotEmpty,
      _gstin.text.trim().isNotEmpty,
      _phone.text.trim().isNotEmpty,
      _email.text.trim().isNotEmpty,
      _addr.text.trim().isNotEmpty,
      _city.text.trim().isNotEmpty,
      _pin.text.trim().isNotEmpty,
    ];
    final done = filled.where((x) => x).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH, 4, AppSpacing.screenH, AppSpacing.bottomNavSafe),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Country & tax first: it decides the currency, the tax and the
          // names of half the fields below it. It used to be in the
          // About tab, where nobody setting up a shop would look.
          const _CountryTile(),

          _IdentityCard(
            name: _name.text.trim(),
            gstin: _gstin.text.trim(),
            city: _city.text.trim(),
            done: done,
            total: filled.length,
            logo: logoBytes(biz?.logoBase64 ?? ''),
          ),
          const Gap(AppSpace.lg),

          FieldGroup(
            title: tr('set.business_profile', ref),
            subtitle: tr('set.profile_sub', ref),
            icon: Symbols.storefront,
            children: [
              const _LogoField(),
              AppField(
                label: tr('set.business_name', ref),
                controller: _name,
                icon: Symbols.storefront,
                hint: tr('set.biz_name_hint', ref),
                onChanged: (_) => setState(() {}),
              ),
              AppField(
                label: tr('cust.gstin', ref),
                controller: _gstin,
                icon: Symbols.verified,
                // An Indian GSTIN as the example only in India. It sat
                // under "EIN" for a US shop, which reads as a bug.
                hint: isIndia ? '33RAAAA1234B1Z5' : null,
                caps: true,
                errorText: _gstinErr,
                helper: tr('set.taxid_helper', ref),
                onChanged: (v) =>
                    setState(() => _gstinErr = Validators.gstin(v)),
              ),
            ],
          ),

          FieldGroup(
            title: tr('set.reach_title', ref),
            subtitle: tr('set.reach_sub', ref),
            icon: Symbols.phone,
            tone: AppColor.info,
            children: [
              AppField(
                label: tr('cust.phone', ref),
                controller: _phone,
                icon: Symbols.phone,
                hint: isIndia ? '+91 98765 43210' : null,
                keyboardType: TextInputType.phone,
                errorText: _phoneErr,
                onChanged: (v) =>
                    setState(() => _phoneErr = Validators.phone(v)),
              ),
              AppField(
                label: tr('cust.email', ref),
                controller: _email,
                icon: Symbols.mail,
                hint: 'you@email.com',
                keyboardType: TextInputType.emailAddress,
                errorText: _emailErr,
                onChanged: (v) =>
                    setState(() => _emailErr = Validators.email(v)),
              ),
            ],
          ),

          FieldGroup(
            title: tr('set.trade_from', ref),
            subtitle: isIndia
                ? tr('set.trade_from_in', ref)
                : tr('set.trade_from_sub', ref),
            icon: Symbols.location_on,
            tone: AppColor.pending,
            children: [
              // Country first, because everything under it depends on
              // the answer — the region list, its name, and whether a
              // GST code applies at all.
              _AddressCountryTile(
                code: addrCountry,
                onChanged: (c) => setState(() {
                  _addrCountry = c;
                  // The old region belongs to the old country, so it
                  // cannot carry over. Clearing is honest; keeping it
                  // would print a Tamil Nadu address on a Japanese
                  // bill.
                  _state = '';
                  _stateCtrl.clear();
                }),
              ),
              AppField(
                label: tr('cust.address', ref),
                controller: _addr,
                icon: Symbols.location_on,
                hint: tr('set.street_hint', ref),
                maxLines: 2,
                validatable: false,
                onChanged: (_) => setState(() {}),
              ),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  flex: 3,
                  child: AppField(
                    label: tr('set.city', ref),
                    controller: _city,
                    hint: isIndia ? 'Coimbatore' : null,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const Gap(AppSpace.md),
                Expanded(
                  flex: 2,
                  child: AppField(
                    // "Pincode" is India's word, and six digits India's
                    // length. A UK postcode has letters and a space.
                    label: isIndia
                        ? tr('set.pincode', ref)
                        : tr('set.postal_code', ref),
                    controller: _pin,
                    hint: isIndia ? '641001' : null,
                    keyboardType: isIndia
                        ? TextInputType.number
                        : TextInputType.text,
                    maxLength: isIndia ? 6 : 10,
                    errorText: _pinErr,
                    onChanged: (v) =>
                        setState(() => _pinErr = Validators.pincode(v)),
                  ),
                ),
              ]),
              // A country with no region list gets a plain box rather
              // than a picker of somebody else's regions.
              if (regionOptions.isEmpty)
                AppField(
                  label: regionLabel,
                  controller: _stateCtrl,
                  icon: Symbols.location_city,
                  hint: tr('set.region_hint', ref),
                  validatable: false,
                  onChanged: (v) => setState(() => _state = v),
                )
              else
                _StatePicker(
                  value: currentState,
                  options: regionOptions,
                  label: regionLabel,
                  onChanged: (v) => setState(() => _state = v),
                ),
            ],
          ),
          const Gap(AppSpace.xl),
          // Save lives at the end of the form, not pinned above the
          // dock: the shell paints a 184pt scrim over the whole PageView
          // so the dock's chrome reads as floating, and anything a tab
          // pins inside that band comes out washed to near-white.
          AppButton(
            label: tr('set.save_business', ref),
            icon: Symbols.check,
            busy: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(trGlobal('cust.required')),
        backgroundColor: AppColors.red));
      return;
    }
    if (_gstinErr != null || _phoneErr != null ||
        _emailErr != null || _pinErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(trGlobal('set.fix_fields')),
        backgroundColor: AppColors.red));
      return;
    }
    setState(() => _saving = true);
    try {
      final b = (ref.read(businessProvider) ?? Business()).copyWith(
        name: _name.text.trim(), gstin: _gstin.text.trim().toUpperCase(),
        phone: _phone.text.trim(), email: _email.text.trim(),
        address: _addr.text.trim(), city: _city.text.trim(),
        state: _state,
        // The GST code only means something in India. Saving '33' for a
        // Japanese prefecture would put Tamil Nadu's code on the bill.
        stateCode: kStateMap[_state] ?? '',
        addressCountryCode: _addrCountry,
        pincode: _pin.text.trim());
      await ref.read(businessProvider.notifier).save(b);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(trGlobal('common.saved')),
        backgroundColor: AppColors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(trGlobal('common.error_detail', {'e': e})), backgroundColor: AppColors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _BankPanel extends ConsumerStatefulWidget {
  const _BankPanel();
  @override
  ConsumerState<_BankPanel> createState() => _BankPanelState();
}

class _BankPanelState extends ConsumerState<_BankPanel> {
  late final TextEditingController _bank, _acc, _ifsc, _upi;
  bool _saving = false;
  String? _ifscErr, _upiErr;

  @override
  void initState() {
    super.initState();
    final b = ref.read(businessProvider);
    _bank = TextEditingController(text: b?.bankName ?? '');
    _acc  = TextEditingController(text: b?.accountNumber ?? '');
    _ifsc = TextEditingController(text: b?.ifscCode ?? '');
    _upi  = TextEditingController(text: b?.upiId ?? '');
    _ifscErr = Validators.ifsc(_ifsc.text);
    _upiErr  = Validators.upi(_upi.text);
  }

  @override
  void dispose() {
    _bank.dispose(); _acc.dispose(); _ifsc.dispose(); _upi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // IFSC, and the Indian examples, only for a shop that trades in
    // India. Elsewhere the same field holds a SWIFT or routing code.
    final isIndia = (ref.watch(businessProvider)?.countryCode ?? 'IN') == 'IN';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH, 4, AppSpacing.screenH, AppSpacing.bottomNavSafe),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FieldGroup(
          title: tr('set.bank_details', ref),
          subtitle: tr('set.bank_sub', ref),
          icon: Symbols.account_balance,
          tone: AppColor.info,
          children: [
            AppField(
              label: tr('set.bank_name', ref),
              controller: _bank,
              icon: Symbols.account_balance,
              hint: isIndia ? 'State Bank of India' : null,
              onChanged: (_) => setState(() {}),
            ),
            AppField(
              label: tr('set.account_number', ref),
              controller: _acc,
              hint: '1234567890',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            AppField(
              label: isIndia ? tr('set.ifsc', ref) : tr('set.bank_code', ref),
              controller: _ifsc,
              hint: isIndia ? 'SBIN0001234' : null,
              caps: true,
              errorText: _ifscErr,
              onChanged: (v) => setState(() => _ifscErr = Validators.ifsc(v)),
            ),
          ],
        ),
        // UPI only moves rupees between Indian accounts, so a shop
        // trading anywhere else is not asked for an ID it cannot use.
        if (isIndia)
        FieldGroup(
          title: tr('set.upi_title', ref),
          subtitle: tr('set.upi_sub', ref),
          icon: Symbols.qr_code_2,
          children: [
            AppField(
              label: tr('set.upi_id', ref),
              controller: _upi,
              icon: Symbols.qr_code_2,
              hint: 'business@upi',
              errorText: _upiErr,
              helper: tr('set.upi_helper', ref),
              onChanged: (v) => setState(() => _upiErr = Validators.upi(v)),
            ),
          ],
        ),
        const Gap(AppSpace.md),
        AppButton(
          label: tr('set.save_bank', ref),
          icon: Symbols.check,
          busy: _saving,
          onPressed: _saving ? null : _save,
        ),
      ]));
  }

  Future<void> _save() async {
    if (_ifscErr != null || _upiErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(trGlobal('set.fix_fields')),
        backgroundColor: AppColors.red));
      return;
    }
    setState(() => _saving = true);
    try {
      final b = (ref.read(businessProvider) ?? Business()).copyWith(
        bankName: _bank.text.trim(), accountNumber: _acc.text.trim(),
        ifscCode: _ifsc.text.trim().toUpperCase(), upiId: _upi.text.trim());
      await ref.read(businessProvider.notifier).save(b);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(trGlobal('common.saved')),
        backgroundColor: AppColors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(trGlobal('common.error_detail', {'e': e})), backgroundColor: AppColors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _InvoicePanel extends ConsumerStatefulWidget {
  const _InvoicePanel();
  @override
  ConsumerState<_InvoicePanel> createState() => _InvoicePanelState();
}

class _InvoicePanelState extends ConsumerState<_InvoicePanel> {
  late final TextEditingController _prefix, _terms;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final b = ref.read(businessProvider);
    _prefix = TextEditingController(text: b?.invoicePrefix ?? 'INV-');
    _terms  = TextEditingController(text: b?.defaultTerms ?? '');
  }

  @override
  void dispose() {
    _prefix.dispose(); _terms.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH, 4, AppSpacing.screenH, AppSpacing.bottomNavSafe),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FieldGroup(
          title: tr('set.invoice_settings', ref),
          subtitle: tr('set.invoice_sub', ref),
          icon: Symbols.receipt_long,
          children: [
            AppField(
              label: tr('set.invoice_prefix', ref),
              controller: _prefix,
              icon: Symbols.receipt_long,
              hint: 'INV-',
              helper: tr('set.prefix_helper', ref),
              onChanged: (_) => setState(() {}),
            ),
            AppField(
              label: tr('set.default_terms', ref),
              controller: _terms,
              hint: tr('set.terms_hint', ref),
              maxLines: 3,
              validatable: false,
            ),
          ],
        ),
        const Gap(AppSpace.md),
        AppButton(
          label: tr('set.save_settings', ref),
          icon: Symbols.check,
          busy: _saving,
          onPressed: _saving ? null : _save,
        ),
      ]));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final b = (ref.read(businessProvider) ?? Business()).copyWith(
        invoicePrefix: _prefix.text.trim(),
        defaultTerms: _terms.text.trim());
      await ref.read(businessProvider.notifier).save(b);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(trGlobal('common.saved')),
        backgroundColor: AppColors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(trGlobal('common.error_detail', {'e': e})), backgroundColor: AppColors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── About panel — language + theme + backup + app-lock + website ───
// Stateful so the App Lock tile can refresh after the user enables /
// disables the lock from inside this same panel.
class _AboutPanel extends ConsumerStatefulWidget {
  const _AboutPanel();
  @override
  ConsumerState<_AboutPanel> createState() => _AboutPanelState();
}

class _AboutPanelState extends ConsumerState<_AboutPanel> {
  static const _siteUrl = 'https://billzap.netlify.app/';

  Future<void> _openSite() async {
    HapticFeedback.lightImpact();
    final uri = Uri.parse(_siteUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(trGlobal('set.browser_fail'))));
    }
  }

  Future<void> _shareApp() async {
    HapticFeedback.lightImpact();
    // Friendly WhatsApp-ready message. The Play Store URL is the
    // production listing path — works even before the app is live
    // (returns "not available" gracefully) and updates the moment
    // it's published.
    const playStoreUrl =
        'https://play.google.com/store/apps/details?id=com.billzap.app';
    // It used to say "Free GST billing for India" and "12 Indian
    // languages" to whoever it was sent to, wherever they were.
    final msg = '${trGlobal('share.title')}\n\n'
        '${trGlobal('share.body', {'count': kAppLocales.length})}\n\n'
        '${trGlobal('share.try', {'url': _siteUrl})}\n'
        '${trGlobal('share.download', {'url': playStoreUrl})}\n\n'
        '${trGlobal('wa.sent_via')}';
    await Share.share(msg, subject: trGlobal('share.subject'));
  }

  Future<void> _toggleAppLock() async {
    HapticFeedback.lightImpact();
    if (AppLockService.instance.isEnabled) {
      final ok = await confirm(context,
          title: tr('set.lock_disable_title', ref),
          message: tr('set.lock_disable_msg', ref),
          icon: Symbols.lock_open,
          destructive: true,
          confirmLabel: tr('set.lock_disable_btn', ref),
          cancelLabel: tr('common.cancel', ref));
      if (ok) {
        await AppLockService.instance.disableLock();
        if (mounted) setState(() {});
      }
    } else {
      final result = await context.push('/lock-setup');
      if (result == true && mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH, 4, AppSpacing.screenH, AppSpacing.bottomNavSafe),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // The language used to live here, two taps deep in a tab
        // nobody looks in. It is now the button in the top corner of
        // Settings, on every tab.

        // Country & tax moved to the top of the Business tab, where a
        // shopkeeper setting up looks for it.

        // ═════════════════════════════════════════════════
        // THEME TILE — light / dark / system
        // ═════════════════════════════════════════════════
        _ThemeTile(),

        // ═════════════════════════════════════════════════
        // APP LOCK TILE (moved from header)
        // ═════════════════════════════════════════════════
        _SettingsTile(
          icon: Symbols.lock,
          gradient: const [Color(0xFFEF4444), Color(0xFFF87171)],
          title: tr('set.app_lock', ref),
          subtitle: AppLockService.instance.isEnabled
            ? '${tr('set.lock_enabled', ref)}'
              ' — ${AppLockService.instance.isBiometricEnabled
                ? tr('set.lock_pin_fp', ref)
                : tr('set.lock_pin_only', ref)}'
            : tr('set.lock_hint', ref),
          subtitleColor: AppLockService.instance.isEnabled
              ? AppColors.green : AppColors.t3,
          onTap: _toggleAppLock,
        ),

        // ═════════════════════════════════════════════════
        // BACKUP & EXPORT TILE
        // ═════════════════════════════════════════════════
        _SettingsTile(
          icon: Symbols.shield,
          gradient: const [Color(0xFF2E7D32), Color(0xFF66BB6A)],
          title: tr('set.backup_export', ref),
          subtitle: tr('set.backup_export_sub', ref),
          onTap: () { HapticFeedback.lightImpact(); context.push('/backup'); },
        ),

        // ═════════════════════════════════════════════════
        // VISIT WEBSITE TILE — landing page for support
        // ═════════════════════════════════════════════════
        _SettingsTile(
          icon: Symbols.public,
          gradient: const [Color(0xFF1557FF), Color(0xFF4070FF)],
          title: tr('set.visit_website', ref),
          subtitle: tr('set.visit_website_sub', ref),
          onTap: _openSite,
        ),

        // ═════════════════════════════════════════════════
        // REFER A FRIEND — share via WhatsApp / system share
        // ═════════════════════════════════════════════════
        _SettingsTile(
          icon: Symbols.group_add,
          gradient: const [Color(0xFF7C3AED), Color(0xFFA855F7)],
          title: tr('set.refer_friend', ref),
          subtitle: tr('set.refer_friend_sub', ref),
          onTap: _shareApp,
        ),

        // ─── About BillZap card ───
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.md),
          child: Text(tr('set.about_billzap', ref),
              style: AppFont.style(AppType.titleS,
                  color: AppColor.textPrimary)),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border)),
          child: Column(children: [
            // The actual app icon, on its jade tile — the same mark
            // that sits on the home screen and the splash. A generic
            // bolt glyph stood in here, which is not the logo.
            ClipRRect(
              borderRadius: AppRadius.all(AppRadius.lg),
              child: Image.asset('assets/icon.png',
                  width: 68, height: 68, fit: BoxFit.cover),
            ),
            const Gap(AppSpace.md),
            Text('BillZap', style: AppFont.sans(
              fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.t1)),
            Text(tr('splash.tagline', ref),
              style: AppFont.sans(
                fontSize: 13, color: AppColors.t3)),
            const Gap(16),
            const Divider(),
            const Gap(12),
            _InfoRow(Symbols.check_circle, tr('set.version', ref),
                appVersionLabel, AppColors.green),
            _InfoRow(Symbols.wifi_off, tr('set.offline', ref), tr('set.no_internet', ref), AppColors.brand),
            _InfoRow(Symbols.lock, tr('set.privacy', ref), tr('set.data_on_device', ref), AppColors.purple),
            const Gap(18),
            // Replaces the old "© 2026 BillZap Technologies" line — a
            // clear CTA to the landing page where customers can find
            // support and learn more.
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: _openSite,
              icon: const Icon(Symbols.open_in_new, size: 16),
              label: Text(tr('set.visit_site_btn', ref),
                style: AppFont.sans(
                  fontSize: 13, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brand,
                side: BorderSide(color: AppColors.brand.withOpacity(0.4)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11))),
            )),
            const Gap(6),
            Text('billzap.netlify.app',
              style: AppFont.sans(
                fontSize: 11, color: AppColors.t4)),
          ])),
      ]));
  }
}

// Generic reusable tile used by the About panel (App Lock, Backup,
// Visit Website). Keeps the three look identical and easy to extend.
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String subtitle;
  final Color? subtitleColor;
  final VoidCallback onTap;
  const _SettingsTile({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    // `gradient` survives as the tile's accent source — the redesign uses
    // its first stop as a flat tint instead of painting a gradient.
    final accent = gradient.isEmpty ? AppColors.t2 : gradient.first;
    return AppSurface(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(children: [
        AppAvatar(icon: icon, tone: accent, size: 44),
        const Gap(13),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
              style: AppFont.sans(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: AppColors.t1)),
            const Gap(3),
            Text(subtitle,
              style: AppFont.sans(
                fontSize: 12.5,
                color: subtitleColor ?? AppColors.t3,
                fontWeight: FontWeight.w500)),
          ])),
        const Gap(8),
        Icon(Symbols.chevron_right, color: AppColors.t4, size: 20),
      ]),
    );
  }
}

class _ThemeTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    String label;
    IconData icon;
    switch (mode) {
      case ThemeMode.dark:
        label = tr('set.theme_dark', ref);
        icon = Symbols.dark_mode;
        break;
      case ThemeMode.light:
        label = tr('set.theme_light', ref);
        icon = Symbols.light_mode;
        break;
      case ThemeMode.system:
        label = tr('set.theme_system', ref);
        icon = Symbols.brightness_auto;
        break;
    }

    return AppSurface(
      onTap: () => _pickMode(context, ref, mode),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(children: [
        AppAvatar(icon: icon, size: 44),
        const Gap(13),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('set.theme', ref),
              style: AppFont.sans(
                fontSize: 14.5, fontWeight: FontWeight.w600,
                letterSpacing: -0.2, color: AppColors.t1)),
            const Gap(3),
            Text(label,
              style: AppFont.sans(fontSize: 12.5, color: AppColors.t3)),
          ])),
        const Gap(8),
        Icon(Symbols.chevron_right, color: AppColors.t4, size: 20),
      ]),
    );
  }

  void _pickMode(BuildContext context, WidgetRef ref, ThemeMode current) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(99))),
          const Gap(14),
          Text(tr('set.theme_choose', ref),
            style: AppFont.sans(
              fontSize: 16, fontWeight: FontWeight.w600,
              color: AppColors.t1)),
          const Gap(8),
          _ThemeOption(
            icon: Symbols.brightness_auto, label: tr('set.theme_system', ref),
            sub: tr('set.theme_system_sub', ref),
            selected: current == ThemeMode.system,
            onTap: () { Navigator.pop(ctx); switchThemeMode(ref, ThemeMode.system); }),
          _ThemeOption(
            icon: Symbols.light_mode, label: tr('set.theme_light', ref),
            sub: tr('set.theme_light_sub', ref),
            selected: current == ThemeMode.light,
            onTap: () { Navigator.pop(ctx); switchThemeMode(ref, ThemeMode.light); }),
          _ThemeOption(
            icon: Symbols.dark_mode, label: tr('set.theme_dark', ref),
            sub: tr('set.theme_dark_sub', ref),
            selected: current == ThemeMode.dark,
            onTap: () { Navigator.pop(ctx); switchThemeMode(ref, ThemeMode.dark); }),
        ]),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeOption({
    required this.icon, required this.label, required this.sub,
    required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: selected ? AppColors.brandSoft : AppColors.bg,
              borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 20,
              color: selected ? AppColors.brand : AppColors.t3),
          ),
          const Gap(12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: AppFont.sans(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: AppColors.t1)),
              Text(sub, style: AppFont.sans(
                fontSize: 11.5, color: AppColors.t3)),
            ])),
          if (selected)
            Icon(Symbols.check_circle, color: AppColors.brand, size: 20),
        ]),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _InfoRow(this.icon, this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const Gap(10),
        Text(label, style: AppFont.sans(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.t2)),
        const Spacer(),
        Text(value, style: AppFont.sans(
          fontSize: 13, color: AppColors.t3)),
      ]));
  }
}

/// The header of the business panel: who this profile is, and how much
/// of it is done. It is the only thing on the page that is not an input,
/// which is exactly why the page now reads as being *about* something.
class _IdentityCard extends StatelessWidget {
  final String name, gstin, city;
  final int done, total;
  final Uint8List? logo;

  const _IdentityCard({
    required this.name,
    required this.gstin,
    required this.city,
    required this.done,
    required this.total,
    this.logo,
  });

  @override
  Widget build(BuildContext context) {
    final complete = done >= total;
    final label = name.isEmpty ? trGlobal('set.your_business') : name;

    return AppSurface(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(children: [
        Row(children: [
          if (logo != null)
            LogoThumb(bytes: logo!, size: 54)
          else
            AppAvatar(label: label, tone: AppColor.primary, size: 54),
          const Gap(AppSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFont.style(AppType.titleS,
                        color: name.isEmpty
                            ? AppColor.textTertiary
                            : AppColor.textPrimary)),
                const Gap(3),
                Row(children: [
                  if (gstin.isNotEmpty) ...[
                    Icon(Symbols.verified, size: 13, color: AppColor.primary),
                    const Gap(4),
                    Flexible(
                      child: Text(gstin,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFont.style(AppType.bodyS,
                              color: AppColor.textSecondary)),
                    ),
                  ] else
                    Text(trGlobal('set.no_taxid'),
                        style: AppFont.style(AppType.bodyS,
                            color: AppColor.textTertiary)),
                  if (city.isNotEmpty) ...[
                    Text('  \u00B7  ',
                        style: AppFont.style(AppType.bodyS,
                            color: AppColor.textTertiary)),
                    Text(city,
                        style: AppFont.style(AppType.bodyS,
                            color: AppColor.textTertiary)),
                  ],
                ]),
              ],
            ),
          ),
        ]),
        const Gap(AppSpace.lg),
        // Progress, stated plainly. A percentage is a score; "2 details
        // left" is an instruction.
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: total == 0 ? 0 : done / total),
                duration: AppMotion.slow,
                curve: AppMotion.standard,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  minHeight: 5,
                  backgroundColor: AppColor.sunken,
                  valueColor: AlwaysStoppedAnimation(AppColor.primary),
                ),
              ),
            ),
          ),
          const Gap(AppSpace.md),
          Text(
            complete
                ? trGlobal('set.all_set')
                : trGlobal('set.to_go', {'n': total - done}),
            style: AppFont.style(AppType.labelS,
                color: complete ? AppColor.primary : AppColor.textTertiary),
          ),
        ]),
      ]),
    );
  }
}

/// What a country calls its first-level divisions, for the field label.
///
/// Getting this wrong is not fatal but it reads as foreign: a Canadian
/// expects "Province", a Japanese trader "Prefecture", and most of
/// Europe neither. Only the ones that clearly differ are listed; the
/// rest fall back to "Region", which is understood everywhere and is
/// the honest answer where the local term is not known.
String _regionLabelFor(String code) {
  // Values are translation keys: the word is the country's, the
  // language it is written in is the reader's.
  const labels = {
    'IN': 'state', 'US': 'state', 'AU': 'state', 'BR': 'state',
    'MY': 'state', 'NG': 'state', 'MX': 'state', 'VE': 'state',
    'SD': 'state', 'SS': 'state', 'PW': 'state',
    'CA': 'province', 'ZA': 'province', 'CN': 'province', 'ID': 'province',
    'AR': 'province', 'PH': 'province', 'TR': 'province', 'PK': 'province',
    'KE': 'county', 'IE': 'county', 'NO': 'county',
    'JP': 'prefecture',
    'AE': 'emirate',
    'CH': 'canton',
    'DE': 'state', 'AT': 'state',
    'GB': 'nation', 'NL': 'province', 'BE': 'province',
    'FR': 'region', 'IT': 'region', 'ES': 'community',
    'RU': 'region', 'UA': 'oblast', 'PL': 'voivodeship',
    'SA': 'region', 'TH': 'region', 'VN': 'province', 'KR': 'province',
    'BD': 'division', 'NP': 'province', 'LK': 'province',
  };
  return trGlobal('region.${labels[code.toUpperCase()] ?? 'region'}');
}

/// The country the shop's premises are in.
///
/// Separate from the country it bills under, and sitting above the
/// region field because everything below depends on it: which regions
/// exist, what they are called, and whether a GST code applies.
class _AddressCountryTile extends StatelessWidget {
  const _AddressCountryTile({required this.code, required this.onChanged});

  final String code;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final country = countryFor(code);
    final flag = countryFlag(code);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(trGlobal('set.country_label').toUpperCase(),
            style:
                AppFont.style(AppType.labelS, color: AppColor.textTertiary)),
        const Gap(AppSpace.xs),
        PressScale(
          onTap: () async {
            HapticFeedback.lightImpact();
            final picked = await pickCountry(context, selected: code);
            if (picked != null) onChanged(picked.code);
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: AppColor.sunken,
              borderRadius: AppRadius.all(AppRadius.md),
              border: Border.all(color: AppColor.hairline),
            ),
            child: Row(children: [
              if (flag.isEmpty)
                Icon(Symbols.public, size: 18, color: AppColor.textTertiary)
              else
                Text(flag, style: const TextStyle(fontSize: 19)),
              const Gap(AppSpace.md),
              Expanded(
                child: Text(country == null ? code : countryDisplayName(code),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFont.style(AppType.bodyL,
                        color: AppColor.textPrimary)),
              ),
              Icon(Symbols.expand_more,
                  size: 18, color: AppColor.textTertiary),
            ]),
          ),
        ),
        const Gap(AppSpace.md),
      ],
    );
  }
}

/// Region picker for the business address. A bottom sheet with a search
/// box rather than a dropdown — India alone has 37 GST jurisdictions,
/// and in India this is the field that decides whether a bill charges
/// CGST/SGST or IGST.
///
/// The list comes from the address country, not from India. It used to
/// be kStates unconditionally, so a shop in Japan was asked to pick
/// between Tamil Nadu and West Bengal.
class _StatePicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  /// The regions of the address country, already resolved by the
  /// caller: India's coded states, another country's divisions, or
  /// empty where the country has none.
  final List<String> options;

  /// What this country calls the field. "State" in India and the US,
  /// "Province" in Canada, "Region" in much of Europe.
  final String label;

  const _StatePicker({
    required this.value,
    required this.onChanged,
    required this.options,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    // Only India's entries carry a code, and only India's bill splits
    // on it, so the badge appears only where it means something.
    final code = kStateMap[value] ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style:
                AppFont.style(AppType.labelS, color: AppColor.textTertiary)),
        const Gap(AppSpace.xs),
        PressScale(
          onTap: () => _open(context),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.md, AppSpace.md, AppSpace.md, AppSpace.md),
            decoration: BoxDecoration(
              color: AppColor.sunken,
              borderRadius: AppRadius.all(AppRadius.md),
              border: Border.all(color: AppColor.hairline),
            ),
            child: Row(children: [
              Icon(Symbols.location_city,
                  size: 18, color: AppColor.textTertiary),
              const Gap(AppSpace.md),
              Expanded(
                child: Text(value.isEmpty ? trGlobal('set.select_region', {'label': label}) : value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFont.style(AppType.bodyL,
                        color: value.isEmpty
                            ? AppColor.textTertiary
                            : AppColor.textPrimary)),
              ),
              if (code.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColor.wash(AppColor.primary),
                    borderRadius: AppRadius.all(AppRadius.xs),
                  ),
                  child: Text(code,
                      style: AppFont.style(AppType.labelS,
                          color: AppColor.primary)),
                ),
              const Gap(AppSpace.sm),
              Icon(Symbols.expand_more, size: 18, color: AppColor.textTertiary),
            ]),
          ),
        ),
      ],
    );
  }

  void _open(BuildContext context) {
    final search = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) {
        final q = search.text.trim().toLowerCase();
        final list = options
            .where((s) => q.isEmpty || s.toLowerCase().contains(q))
            .toList();
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.78,
          decoration: BoxDecoration(
            color: AppColor.canvas,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.sheet)),
          ),
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(children: [
            const Gap(AppSpace.md),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColor.hairline,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.gutter,
                  AppSpace.lg, AppSpace.gutter, AppSpace.md),
              child: Row(children: [
                Expanded(
                  child: Text(trGlobal('set.place_of_business'),
                      style: AppFont.style(AppType.titleS,
                          color: AppColor.textPrimary)),
                ),
                AppIconButton(
                    icon: Symbols.close, onTap: () => Navigator.pop(ctx)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.gutter),
              child: AppSearchField(
                controller: search,
                hint: trGlobal('create.search_states'),
                hasValue: q.isNotEmpty,
                onChanged: (_) => ss(() {}),
                onClear: () {
                  search.clear();
                  ss(() {});
                },
              ),
            ),
            const Gap(AppSpace.md),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0,
                    AppSpace.gutter, AppSpace.xxl),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final full = list[i];
                  final n = full.split(' (')[0];
                  final c = kStateMap[n] ?? '';
                  final on = n == value;
                  return AppListRow(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onChanged(n);
                      Navigator.pop(ctx);
                    },
                    leading: AppAvatar(
                      label: c.isEmpty ? n : c,
                      tone: on ? AppColor.primary : AppColor.textTertiary,
                      size: 38,
                    ),
                    title: n,
                    subtitle: c.isEmpty ? null : trGlobal('create.state_code', {'code': c}),
                    trailing: on
                        ? Icon(Symbols.check_circle,
                            size: 20, color: AppColor.primary)
                        : const SizedBox.shrink(),
                  );
                },
              ),
            ),
          ]),
        );
      }),
    );
  }
}


// ─── Country & tax ────────────────────────────────────────────────────
//
// Two rows in one tile: which country, and — unless the profile is
// verified — what the shopkeeper says their tax is called and costs.
//
// The second row is not a degraded state. For most of the world nobody
// has checked the rates, and asking is honest where asserting would not
// be. It is offered for an unconfirmed table rate too, because that is
// exactly the case where somebody most needs to be able to correct us.
class _CountryTile extends ConsumerWidget {
  const _CountryTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biz = ref.watch(businessProvider);
    final profile = ref.watch(taxProfileProvider);
    final country = countryFor(profile.countryCode);
    // Three states. Collapsing the middle one into either neighbour
    // would be a lie: a rate from the table is a real starting point AND
    // an unchecked claim, and the shopkeeper needs to know both.
    final (noticeKey, noticeIcon, noticeTint) = switch (profile.confidence) {
      TaxConfidence.verified =>
        ('set.tax_verified', Symbols.verified, AppColor.primary),
      TaxConfidence.unconfirmed =>
        ('set.tax_unconfirmed', Symbols.help, AppColors.orange),
      TaxConfidence.selfDeclared =>
        ('set.tax_custom', Symbols.tune, AppColors.t3),
    };
    final editable = profile.confidence != TaxConfidence.verified;
    // Only the middle state is a call to action: the app pre-filled a
    // rate it has not checked, and the shopkeeper should confirm it.
    final needsConfirming = profile.confidence == TaxConfidence.unconfirmed;

    Future<void> change() async {
      HapticFeedback.lightImpact();
      final picked = await pickCountry(context, selected: profile.countryCode);
      if (picked == null) return;
      await ref.read(businessProvider.notifier).save(
            (biz ?? Business()).copyWith(
              countryCode: picked.code,
              customCurrencySymbol: picked.currencySymbol,
            ),
          );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border)),
      child: Material(
        color: Colors.transparent,
        child: Column(children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: change,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(children: [
                Container(
                  width: 42, height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColor.wash(AppColor.primary),
                    borderRadius: BorderRadius.circular(11)),
                  // The flag, where the platform can draw it. A globe
                  // says "this is the country setting"; the flag says
                  // which country, which is the thing being checked.
                  child: countryFlag(profile.countryCode).isEmpty
                      ? Icon(Symbols.public,
                          color: AppColor.primary, size: 22)
                      : Text(countryFlag(profile.countryCode),
                          style: const TextStyle(fontSize: 22))),
                const Gap(12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('set.country', ref),
                      style: AppFont.sans(fontSize: 14.5,
                        fontWeight: FontWeight.w600, color: AppColors.t1)),
                    const Gap(2),
                    Text(
                      '${country != null ? countryDisplayName(country.code) : profile.countryName} · '
                      '${profile.currencyCode} · ${profile.taxName}'
                      '${profile.defaultRate > 0 ? " ${profile.defaultRate}%" : ""}',
                      style: AppFont.sans(fontSize: 12, color: AppColors.t3)),
                  ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(20)),
                  child: Text(tr('set.change', ref),
                    style: AppFont.sans(fontSize: 11,
                      fontWeight: FontWeight.w700, color: AppColors.brand))),
                const Gap(4),
                Icon(Symbols.chevron_right, color: AppColors.t3, size: 22),
              ]),
            ),
          ),

          // Say which of the three situations this country is in. A
          // shopkeeper has to know whether the rate on their bill is
          // the app's checked claim, its unchecked guess, or their own.
          //
          // The unconfirmed case gets a tinted well rather than grey
          // body text, because it is the only one that asks the
          // shopkeeper to go and do something. The other two are
          // statements of fact and should stay quiet.
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Container(
              width: double.infinity,
              padding: needsConfirming
                  ? const EdgeInsets.symmetric(horizontal: 10, vertical: 9)
                  : EdgeInsets.zero,
              decoration: needsConfirming
                  ? BoxDecoration(
                      color: AppColors.orangeSoft,
                      borderRadius: BorderRadius.circular(10))
                  : null,
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(noticeIcon, size: 15, color: noticeTint),
                    const Gap(8),
                    Expanded(
                        child: Text(tr(noticeKey, ref),
                            style: AppFont.sans(
                                fontSize: 11.5,
                                height: 1.4,
                                fontWeight: needsConfirming
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: needsConfirming
                                    ? AppColors.orange
                                    : AppColors.t3))),
                  ]),
            ),
          ),

          // Editable for anything not verified — including a table
          // rate, which is precisely the case where a shopkeeper most
          // needs to be able to correct us.
          if (editable) ...[
            Divider(height: 1, color: AppColors.border),
            InkWell(
              onTap: () => _editCustomTax(context, ref, biz, profile),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                child: Row(children: [
                  Icon(Symbols.percent, size: 18, color: AppColors.t3),
                  const Gap(12),
                  Expanded(child: Text(tr('set.tax_edit', ref),
                    style: AppFont.sans(fontSize: 13.5,
                      fontWeight: FontWeight.w600, color: AppColors.t1))),
                  Text('${profile.taxName} ${profile.defaultRate}%',
                    style: AppFont.sans(fontSize: 12.5, color: AppColors.t3)),
                  const Gap(4),
                  Icon(Symbols.chevron_right, color: AppColors.t3, size: 20),
                ]),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

Future<void> _editCustomTax(BuildContext context, WidgetRef ref,
    Business? biz, TaxProfile profile) async {
  final name = TextEditingController(text: profile.taxName);
  final rate = TextEditingController(
      text: profile.defaultRate == 0 ? '' : '${profile.defaultRate}');
  // Declared outside the builder so it survives every rebuild — the
  // same trap that made four other sheets in this app save twice.
  bool saving = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(builder: (ctx, ss) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('set.tax_edit', ref),
              style: AppFont.sans(fontSize: 17,
                fontWeight: FontWeight.w700, color: AppColors.t1)),
            const Gap(6),
            Text(tr('set.tax_custom', ref),
              style: AppFont.sans(fontSize: 12.5, height: 1.45,
                color: AppColors.t3)),
            const Gap(18),
            TextField(
              controller: name,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: tr('set.tax_name', ref),
                hintText: trGlobal('set.tax_name_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12))),
            ),
            const Gap(12),
            TextField(
              controller: rate,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: tr('set.tax_rate', ref),
                suffixText: '%',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12))),
            ),
            const Gap(20),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: saving ? null : () async {
                ss(() => saving = true);
                final parsed = double.tryParse(rate.text.trim()) ?? 0;
                await ref.read(businessProvider.notifier).save(
                  (biz ?? Business()).copyWith(
                    customTaxName: name.text.trim().isEmpty
                        ? 'Tax' : name.text.trim(),
                    // Clamped: a negative rate would subtract tax and a
                    // rate above 100 is a typo, not a jurisdiction.
                    customTaxRate: parsed.clamp(0, 100),
                  ));
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: AppColors.onBrand,
                padding: const EdgeInsets.symmetric(vertical: 14)),
              child: Text(tr('set.save', ref)),
            )),
          ]),
        ),
      );
    }),
  );
}


/// Add, change or remove the shop's logo. Saved the moment it is picked,
/// so the next invoice PDF carries it without a separate save.
class _LogoField extends ConsumerStatefulWidget {
  const _LogoField();

  @override
  ConsumerState<_LogoField> createState() => _LogoFieldState();
}

class _LogoFieldState extends ConsumerState<_LogoField> {
  bool _busy = false;

  Future<void> _pick() async {
    if (_busy) return;
    HapticFeedback.lightImpact();
    setState(() => _busy = true);
    try {
      final logo = await pickBusinessLogo();
      if (logo == null) return;
      final biz = ref.read(businessProvider) ?? Business();
      await ref.read(businessProvider.notifier).save(biz.copyWith(logoBase64: logo));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(trGlobal('logo.saved')),
          backgroundColor: AppColors.green));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(trGlobal('logo.unreadable')),
          backgroundColor: AppColors.red));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    HapticFeedback.lightImpact();
    final biz = ref.read(businessProvider);
    if (biz == null) return;
    await ref.read(businessProvider.notifier).save(biz.copyWith(logoBase64: ''));
  }

  @override
  Widget build(BuildContext context) {
    final bytes = logoBytes(ref.watch(businessProvider)?.logoBase64 ?? '');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Row(children: [
        if (bytes != null)
          LogoThumb(bytes: bytes, size: 56)
        else
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColor.sunken,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColor.hairline),
            ),
            child: Icon(Symbols.image, size: 22, color: AppColor.textTertiary),
          ),
        const Gap(AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(trGlobal('logo.title'),
                  style: AppFont.style(AppType.labelL,
                      color: AppColor.textPrimary)),
              const Gap(2),
              Text(trGlobal('logo.sub'),
                  style: AppFont.style(AppType.bodyS,
                      color: AppColor.textTertiary)),
              const Gap(AppSpace.sm),
              Wrap(spacing: AppSpace.sm, runSpacing: AppSpace.xs, children: [
                AppButton.outline(
                  label: bytes == null
                      ? trGlobal('logo.add')
                      : trGlobal('logo.change'),
                  icon: Symbols.upload_file,
                  compact: true,
                  expand: false,
                  busy: _busy,
                  onPressed: _busy ? null : _pick,
                ),
                if (bytes != null)
                  AppButton.ghost(
                    label: trGlobal('logo.remove'),
                    icon: Symbols.delete,
                    onPressed: _busy ? null : _remove,
                  ),
              ]),
            ],
          ),
        ),
      ]),
    );
  }
}
