// lib/screens/main/settings_screen.dart
// Fully translated + Language picker tile in About panel
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../i18n/translations.dart';
import '../../widgets/language_picker.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<SettingsScreen> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.card,
        title: Text(tr('set.title', ref), style: GoogleFonts.plusJakartaSans(
          fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.t1))),
      body: Column(children: [
        Container(
          color: AppColors.card,
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Row(children: [
            _TabBtn(tr('set.business', ref), 0, _tab, (i) => setState(() => _tab = i)),
            const Gap(8),
            _TabBtn(tr('set.bank', ref), 1, _tab, (i) => setState(() => _tab = i)),
            const Gap(8),
            _TabBtn(tr('set.invoice', ref), 2, _tab, (i) => setState(() => _tab = i)),
            const Gap(8),
            _TabBtn(tr('set.about', ref), 3, _tab, (i) => setState(() => _tab = i)),
          ])),
        Expanded(
          child: IndexedStack(index: _tab, children: const [
            _BusinessPanel(),
            _BankPanel(),
            _InvoicePanel(),
            _AboutPanel(),
          ])),
      ]),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final int idx, cur;
  final ValueChanged<int> onTap;
  const _TabBtn(this.label, this.idx, this.cur, this.onTap);
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(
              color: idx == cur ? AppColors.brand : Colors.transparent,
              width: 2))),
          child: Text(label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: idx == cur ? AppColors.brand : AppColors.t3)))));
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
    final dropdownItems = kStates.map((s) {
      final n = s.split(' (')[0];
      return DropdownMenuItem<String>(
        value: n,
        child: Text(s, style: GoogleFonts.plusJakartaSans(fontSize: 13)));
    }).toList();

    final saveBtn = SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15)),
        child: _saving
          ? const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2))
          : Text(tr('set.save_business', ref),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w700))));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Sec(tr('set.business_profile', ref)),
          _F(tr('set.business_name', ref) + ' *', _name, hint: 'e.g. Ravi Electronics'),
          _F(tr('cust.gstin', ref), _gstin, hint: '33RAAAA1234B1Z5', caps: true),
          Row(children: [
            Expanded(child: _F(tr('cust.phone', ref), _phone,
              hint: '+91 98765 43210', type: TextInputType.phone)),
            const Gap(10),
            Expanded(child: _F(tr('cust.email', ref), _email,
              hint: 'you@email.com', type: TextInputType.emailAddress)),
          ]),
          _F(tr('cust.address', ref), _addr, hint: 'Street, Area'),
          Row(children: [
            Expanded(child: _F(tr('set.city', ref), _city, hint: 'Coimbatore')),
            const Gap(10),
            Expanded(child: _F(tr('set.pincode', ref), _pin,
              hint: '641001', type: TextInputType.number, max: 6)),
          ]),
          _Label(tr('set.state', ref)),
          DropdownButtonFormField<String>(
            value: currentState,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 13)),
            items: dropdownItems,
            onChanged: (v) => setState(() => _state = v ?? _state)),
          const Gap(20),
          saveBtn,
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

  @override
  void initState() {
    super.initState();
    final b = ref.read(businessProvider);
    _bank = TextEditingController(text: b?.bankName ?? '');
    _acc  = TextEditingController(text: b?.accountNumber ?? '');
    _ifsc = TextEditingController(text: b?.ifscCode ?? '');
    _upi  = TextEditingController(text: b?.upiId ?? '');
  }

  @override
  void dispose() {
    _bank.dispose(); _acc.dispose(); _ifsc.dispose(); _upi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Sec(tr('set.bank_details', ref)),
        _F(tr('set.bank_name', ref), _bank, hint: 'State Bank of India'),
        _F(tr('set.account_number', ref), _acc, hint: '1234567890', type: TextInputType.number),
        _F(tr('set.ifsc', ref), _ifsc, hint: 'SBIN0001234', caps: true),
        const Gap(8),
        _Sec('UPI'),
        _F(tr('set.upi_id', ref), _upi, hint: 'business@upi'),
        const Gap(20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15)),
            child: _saving
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(tr('set.save_bank', ref),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w700)))),
      ]));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final b = (ref.read(businessProvider) ?? Business()).copyWith(
        bankName: _bank.text.trim(), accountNumber: _acc.text.trim(),
        ifscCode: _ifsc.text.trim().toUpperCase(), upiId: _upi.text.trim());
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
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Sec(tr('set.invoice_settings', ref)),
        _F(tr('set.invoice_prefix', ref), _prefix, hint: 'INV-'),
        _Label(tr('set.default_terms', ref)),
        TextField(
          controller: _terms, maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Payment due within 30 days.',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.brand, width: 1.5)),
            contentPadding: const EdgeInsets.all(13)),
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.t1)),
        const Gap(20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15)),
            child: _saving
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(tr('set.save_settings', ref),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w700)))),
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

// ─── About panel — has the LANGUAGE TILE at the top! ───
class _AboutPanel extends ConsumerWidget {
  const _AboutPanel();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = currentLanguage(ref.watch(languageProvider));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
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
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.brand, Color(0xFF4070FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(11)),
                    child: const Icon(Symbols.translate,
                      color: Colors.white, size: 22)),
                  const Gap(12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('set.language', ref),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.t1)),
                      const Gap(2),
                      Text('${lang.name} • ${lang.englishName}',
                        style: GoogleFonts.plusJakartaSans(
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
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand))),
                  const Gap(4),
                  const Icon(Symbols.chevron_right,
                    color: AppColors.t3, size: 22),
                ]),
              ),
            ),
          ),
        ),

        // ─── About BillZap card ───
        _Sec(tr('set.about_billzap', ref)),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border)),
          child: Column(children: [
            const Icon(Symbols.bolt, size: 48, color: AppColors.brand),
            const Gap(8),
            Text('BillZap', style: GoogleFonts.plusJakartaSans(
              fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.t1)),
            Text(tr('splash.tagline', ref),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: AppColors.t3)),
            const Gap(16),
            const Divider(),
            const Gap(12),
            _InfoRow(Symbols.check_circle, tr('set.version', ref), '1.3.0', AppColors.green),
            _InfoRow(Symbols.wifi_off, tr('set.offline', ref), tr('set.no_internet', ref), AppColors.brand),
            _InfoRow(Symbols.lock, tr('set.privacy', ref), tr('set.data_on_device', ref), AppColors.purple),
            _InfoRow(Symbols.currency_rupee, tr('set.price', ref), tr('set.always_free', ref), AppColors.green),
            const Gap(16),
            Text('© 2026 BillZap Technologies',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.t4)),
          ])),
      ]));
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
        Text(label, style: GoogleFonts.plusJakartaSans(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.t2)),
        const Spacer(),
        Text(value, style: GoogleFonts.plusJakartaSans(
          fontSize: 13, color: AppColors.t3)),
      ]));
  }
}

Widget _Sec(String t) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(t, style: GoogleFonts.plusJakartaSans(
      fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.t1)));
}

Widget _Label(String t) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(t, style: GoogleFonts.plusJakartaSans(
      fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.t3)));
}

Widget _F(String label, TextEditingController ctrl,
    {String? hint, TextInputType? type, bool caps = false, int? max}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Label(label),
      TextField(
        controller: ctrl,
        keyboardType: type,
        maxLength: max,
        textCapitalization: caps
          ? TextCapitalization.characters
          : TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: hint,
          counterText: '',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.brand, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13)),
        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.t1)),
    ]));
}
