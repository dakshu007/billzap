// lib/screens/main/settings_screen.dart
// Fully translated + Language picker tile in About panel
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
import '../../design/components.dart';
import '../../design/tokens.dart';
import '../../design/motion.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../i18n/translations.dart';
import '../../utils/validators.dart';
import '../../utils/platform.dart';
import '../../widgets/language_picker.dart';
import '../../providers/theme_provider.dart';

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
              tr('set.bank', ref),
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
  String _state = 'Tamil Nadu';
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
    _gstinErr = Validators.gstin(_gstin.text);
    _phoneErr = Validators.phone(_phone.text);
    _emailErr = Validators.email(_email.text);
    _pinErr   = Validators.pincode(_pin.text);
  }

  @override
  void dispose() {
    _name.dispose(); _gstin.dispose(); _phone.dispose(); _email.dispose();
    _addr.dispose(); _city.dispose(); _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateNames = kStates.map((s) => s.split(' (')[0]).toList();
    final currentState = stateNames.contains(_state) ? _state : 'Tamil Nadu';

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
          _IdentityCard(
            name: _name.text.trim(),
            gstin: _gstin.text.trim(),
            city: _city.text.trim(),
            done: done,
            total: filled.length,
          ),
          const Gap(AppSpace.lg),

          FieldGroup(
            title: tr('set.business_profile', ref),
            subtitle: 'Printed at the top of every bill',
            icon: Symbols.storefront,
            children: [
              AppField(
                label: tr('set.business_name', ref),
                controller: _name,
                icon: Symbols.storefront,
                hint: 'e.g. Ravi Electronics',
                onChanged: (_) => setState(() {}),
              ),
              AppField(
                label: tr('cust.gstin', ref),
                controller: _gstin,
                icon: Symbols.verified,
                hint: '33RAAAA1234B1Z5',
                caps: true,
                errorText: _gstinErr,
                helper: 'Leave blank if you are not registered',
                onChanged: (v) =>
                    setState(() => _gstinErr = Validators.gstin(v)),
              ),
            ],
          ),

          FieldGroup(
            title: 'How customers reach you',
            subtitle: 'Shown on the bill and the WhatsApp message',
            icon: Symbols.phone,
            tone: AppColor.info,
            children: [
              AppField(
                label: tr('cust.phone', ref),
                controller: _phone,
                icon: Symbols.phone,
                hint: '+91 98765 43210',
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
            title: 'Where you trade from',
            subtitle: 'State decides CGST/SGST against IGST',
            icon: Symbols.location_on,
            tone: AppColor.pending,
            children: [
              AppField(
                label: tr('cust.address', ref),
                controller: _addr,
                icon: Symbols.location_on,
                hint: 'Street, area',
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
                    hint: 'Coimbatore',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const Gap(AppSpace.md),
                Expanded(
                  flex: 2,
                  child: AppField(
                    label: tr('set.pincode', ref),
                    controller: _pin,
                    hint: '641001',
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    errorText: _pinErr,
                    onChanged: (v) =>
                        setState(() => _pinErr = Validators.pincode(v)),
                  ),
                ),
              ]),
              _StatePicker(
                value: currentState,
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
        content: Text('Fix the highlighted fields first'),
        backgroundColor: AppColors.red));
      return;
    }
    setState(() => _saving = true);
    try {
      final b = (ref.read(businessProvider) ?? Business()).copyWith(
        name: _name.text.trim(), gstin: _gstin.text.trim().toUpperCase(),
        phone: _phone.text.trim(), email: _email.text.trim(),
        address: _addr.text.trim(), city: _city.text.trim(),
        state: _state, stateCode: kStateMap[_state] ?? '33',
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
        content: Text('Error: $e'), backgroundColor: AppColors.red));
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH, 4, AppSpacing.screenH, AppSpacing.bottomNavSafe),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FieldGroup(
          title: tr('set.bank_details', ref),
          subtitle: 'Printed on the bill so customers can transfer',
          icon: Symbols.account_balance,
          tone: AppColor.info,
          children: [
            AppField(
              label: tr('set.bank_name', ref),
              controller: _bank,
              icon: Symbols.account_balance,
              hint: 'State Bank of India',
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
              label: tr('set.ifsc', ref),
              controller: _ifsc,
              hint: 'SBIN0001234',
              caps: true,
              errorText: _ifscErr,
              onChanged: (v) => setState(() => _ifscErr = Validators.ifsc(v)),
            ),
          ],
        ),
        FieldGroup(
          title: 'UPI',
          subtitle: 'Becomes the QR code on every unpaid bill',
          icon: Symbols.qr_code_2,
          children: [
            AppField(
              label: tr('set.upi_id', ref),
              controller: _upi,
              icon: Symbols.qr_code_2,
              hint: 'business@upi',
              errorText: _upiErr,
              helper: 'Customers scan this to pay you directly',
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
        content: Text('Fix the highlighted fields first'),
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
        content: Text('Error: $e'), backgroundColor: AppColors.red));
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
          subtitle: 'How new bills are numbered and worded',
          icon: Symbols.receipt_long,
          children: [
            AppField(
              label: tr('set.invoice_prefix', ref),
              controller: _prefix,
              icon: Symbols.receipt_long,
              hint: 'INV-',
              helper: 'Your next bill will be numbered from this',
              onChanged: (_) => setState(() {}),
            ),
            AppField(
              label: tr('set.default_terms', ref),
              controller: _terms,
              hint: 'Payment due within 30 days.',
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
        content: Text('Error: $e'), backgroundColor: AppColors.red));
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
        const SnackBar(content: Text('Could not open browser')));
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
    final msg = '''
*BillZap* — Free GST billing for India

I'm using BillZap to send professional GST invoices in seconds.
• 100% offline • No sign-up • Free forever
• UPI QR on every invoice — get paid instantly
• Available in 12 Indian languages
• Voice billing in your language

Try it: $_siteUrl
Download: $playStoreUrl

— Sent via BillZap''';
    await Share.share(msg, subject: 'Try BillZap — Free GST Billing');
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
    final lang = currentLanguage(ref.watch(languageProvider));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH, 4, AppSpacing.screenH, AppSpacing.bottomNavSafe),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ═════════════════════════════════════════════════
        // LANGUAGE TILE — TAP TO CHANGE APP LANGUAGE
        // ═════════════════════════════════════════════════
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border)),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const LanguagePickerScreen()));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(children: [
                  // Washed jade like every other tile on this panel. A
                  // solid ink square here read as a rendering fault
                  // sitting in a column of pastel discs.
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: AppColor.wash(AppColor.primary),
                      borderRadius: BorderRadius.circular(11)),
                    child: Icon(Symbols.translate,
                      color: AppColor.primary, size: 22)),
                  const Gap(12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('set.language', ref),
                        style: AppFont.sans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.t1)),
                      const Gap(2),
                      Text('${lang.name} • ${lang.englishName}',
                        style: AppFont.sans(
                          fontSize: 12,
                          color: AppColors.t3)),
                    ])),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(20)),
                    child: Text(tr('set.change', ref),
                      style: AppFont.sans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand))),
                  const Gap(4),
                  Icon(Symbols.chevron_right,
                    color: AppColors.t3, size: 22),
                ]),
              ),
            ),
          ),
        ),

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
            // The mark is jade — it is the app's own logo, not chrome.
            Icon(Symbols.bolt, size: 48, color: AppColor.primary),
            const Gap(8),
            Text('BillZap', style: AppFont.sans(
              fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.t1)),
            Text(tr('splash.tagline', ref),
              style: AppFont.sans(
                fontSize: 13, color: AppColors.t3)),
            const Gap(16),
            const Divider(),
            const Gap(12),
            _InfoRow(Symbols.check_circle, tr('set.version', ref), '1.0.0', AppColors.green),
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
            onTap: () { ref.read(themeModeProvider.notifier).set(ThemeMode.system); Navigator.pop(ctx); }),
          _ThemeOption(
            icon: Symbols.light_mode, label: tr('set.theme_light', ref),
            sub: tr('set.theme_light_sub', ref),
            selected: current == ThemeMode.light,
            onTap: () { ref.read(themeModeProvider.notifier).set(ThemeMode.light); Navigator.pop(ctx); }),
          _ThemeOption(
            icon: Symbols.dark_mode, label: tr('set.theme_dark', ref),
            sub: tr('set.theme_dark_sub', ref),
            selected: current == ThemeMode.dark,
            onTap: () { ref.read(themeModeProvider.notifier).set(ThemeMode.dark); Navigator.pop(ctx); }),
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

  const _IdentityCard({
    required this.name,
    required this.gstin,
    required this.city,
    required this.done,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final complete = done >= total;
    final label = name.isEmpty ? 'Your business' : name;

    return AppSurface(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(children: [
        Row(children: [
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
                    Text('No GSTIN yet',
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
                ? 'All set'
                : '${total - done} to go',
            style: AppFont.style(AppType.labelS,
                color: complete ? AppColor.primary : AppColor.textTertiary),
          ),
        ]),
      ]),
    );
  }
}

/// State picker. A bottom sheet with a search box rather than a 36-entry
/// dropdown — the list is long enough that scrolling a menu to find
/// "Uttar Pradesh" is genuinely annoying, and this is the field that
/// decides whether a bill charges CGST/SGST or IGST.
class _StatePicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _StatePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final code = kStateMap[value] ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STATE',
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
                child: Text(value,
                    style: AppFont.style(AppType.bodyL,
                        color: AppColor.textPrimary)),
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
        final list = kStates
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
                  child: Text('Place of business',
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
                hint: 'Search states',
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
                    subtitle: c.isEmpty ? null : 'State code $c',
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
