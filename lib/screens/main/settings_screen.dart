// lib/screens/main/settings_screen.dart
// ✅ Free Forever removed
// ✅ Loading fixed with try/finally
// ✅ Zero Firebase
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<SettingsScreen> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(
      automaticallyImplyLeading: false, backgroundColor: AppColors.card,
      title: Text('Settings', style: GoogleFonts.nunito(
        fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.t1)),
      bottom: PreferredSize(preferredSize: const Size.fromHeight(44),
        child: Row(children: [
          _TabBtn('Business', 0, _tab, (i) => setState(() => _tab = i)),
          _TabBtn('Bank & UPI', 1, _tab, (i) => setState(() => _tab = i)),
          _TabBtn('Invoice', 2, _tab, (i) => setState(() => _tab = i)),
          _TabBtn('About', 3, _tab, (i) => setState(() => _tab = i)),
        ])),
    ),
    body: IndexedStack(index: _tab, children: const [
      _BusinessPanel(),
      _BankPanel(),
      _InvoicePanel(),
      _AboutPanel(),
    ]),
  );
}

class _TabBtn extends StatelessWidget {
  final String label; final int idx, cur; final ValueChanged<int> onTap;
  const _TabBtn(this.label, this.idx, this.cur, this.onTap);
  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(
    onTap: () => onTap(idx),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(
        color: idx == cur ? AppColors.brand : Colors.transparent, width: 2))),
      child: Text(label, textAlign: TextAlign.center, style: GoogleFonts.dmSans(
        fontSize: 12, fontWeight: FontWeight.w700,
        color: idx == cur ? AppColors.brand : AppColors.t3)),
    )));
}

// ─── Business Panel ───────────────────────────────────────────────────────
class _BusinessPanel extends ConsumerStatefulWidget {
  const _BusinessPanel();
  @override
  ConsumerState<_BusinessPanel> createState() => _BusinessPanelState();
}
class _BusinessPanelState extends ConsumerState<_BusinessPanel> {
  final _name = TextEditingController(); final _gstin = TextEditingController();
  final _phone= TextEditingController(); final _email = TextEditingController();
  final _addr = TextEditingController(); final _city  = TextEditingController();
  final _pin  = TextEditingController();
  String _state = 'Tamil Nadu';
  bool _saving = false, _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      final b = ref.read(businessProvider);
      if (b != null) {
        _name.text = b.name; _gstin.text = b.gstin; _phone.text = b.phone;
        _email.text = b.email; _addr.text = b.address; _city.text = b.city;
        _pin.text = b.pincode;
        _state = b.state.isNotEmpty ? b.state : 'Tamil Nadu';
      }
    }
  }

  @override
  void dispose() {
    _name.dispose(); _gstin.dispose(); _phone.dispose(); _email.dispose();
    _addr.dispose(); _city.dispose(); _pin.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Sec('Business Profile'),
      _F('Business Name *', _name, hint: 'e.g. Ravi Electronics'),
      _F('GSTIN', _gstin, hint: '33RAAAA1234B1Z5', caps: true),
      Row(children: [
        Expanded(child: _F('Phone', _phone, hint: '+91 98765 43210', type: TextInputType.phone)),
        const Gap(10),
        Expanded(child: _F('Email', _email, hint: 'you@email.com', type: TextInputType.emailAddress)),
      ]),
      _F('Address', _addr, hint: 'Street, Area'),
      Row(children: [
        Expanded(child: _F('City', _city, hint: 'Coimbatore')),
        const Gap(10),
        Expanded(child: _F('Pincode', _pin, hint: '641001', type: TextInputType.number, max: 6)),
      ]),
      _Label('State'),
      DropdownButtonFormField<String>(
        value: kStates.map((s) => s.split(' (')[0]).contains(_state) ? _state : 'Tamil Nadu',
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13)),
        items: kStates.map((s) {
          final name = s.split(' (')[0];
          return DropdownMenuItem(value: name, child: Text(s, style: GoogleFonts.dmSans(fontSize: 13)));
        }).toList(),
        onChanged: (v) => setState(() => _state = v ?? _state)),
      const Gap(20),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
        child: _saving
          ? const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text('Save Business Profile', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700)))),
    ]),
  );

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Business name is required'), backgroundColor: AppColors.red));
      return;
    }
    setState(() => _saving = true);
    try {
      final existing = ref.read(businessProvider);
      final biz = (existing ?? Business()).copyWith(
        name: _name.text.trim(),
        gstin: _gstin.text.trim().toUpperCase(),
        phone: _phone.text.trim(), email: _email.text.trim(),
        address: _addr.text.trim(), city: _city.text.trim(),
        state: _state, stateCode: kStateMap[_state] ?? '33',
        pincode: _pin.text.trim(),
      );
      await ref.read(businessProvider.notifier).save(biz);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Business profile saved \u2713'), backgroundColor: AppColors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── Bank Panel ───────────────────────────────────────────────────────────
class _BankPanel extends ConsumerStatefulWidget {
  const _BankPanel();
  @override
  ConsumerState<_BankPanel> createState() => _BankPanelState();
}
class _BankPanelState extends ConsumerState<_BankPanel> {
  final _bank = TextEditingController(); final _acc  = TextEditingController();
  final _ifsc = TextEditingController(); final _upi  = TextEditingController();
  bool _saving = false, _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      final b = ref.read(businessProvider);
      if (b != null) {
        _bank.text = b.bankName; _acc.text = b.accountNumber;
        _ifsc.text = b.ifscCode; _upi.text = b.upiId;
      }
    }
  }

  @override
  void dispose() { _bank.dispose(); _acc.dispose(); _ifsc.dispose(); _upi.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Sec('Bank Details'),
      _F('Bank Name', _bank, hint: 'e.g. State Bank of India'),
      Row(children: [
        Expanded(child: _F('Account Number', _acc, type: TextInputType.number)),
        const Gap(10),
        Expanded(child: _F('IFSC Code', _ifsc, hint: 'SBIN0001234', caps: true)),
      ]),
      _Sec('UPI'),
      _F('UPI ID', _upi, hint: 'business@sbi'),
      const Gap(20),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
        child: _saving
          ? const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text('Save Bank Details', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700)))),
    ]),
  );

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final existing = ref.read(businessProvider) ?? Business();
      await ref.read(businessProvider.notifier).save(existing.copyWith(
        bankName: _bank.text.trim(), accountNumber: _acc.text.trim(),
        ifscCode: _ifsc.text.trim().toUpperCase(), upiId: _upi.text.trim()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Bank details saved \u2713'), backgroundColor: AppColors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── Invoice Defaults Panel ───────────────────────────────────────────────
class _InvoicePanel extends ConsumerStatefulWidget {
  const _InvoicePanel();
  @override
  ConsumerState<_InvoicePanel> createState() => _InvoicePanelState();
}
class _InvoicePanelState extends ConsumerState<_InvoicePanel> {
  final _prefix = TextEditingController();
  final _terms  = TextEditingController();
  bool _saving = false, _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      final b = ref.read(businessProvider);
      _prefix.text = b?.invoicePrefix ?? 'INV-';
      _terms.text  = b?.defaultTerms ?? 'Payment due within 30 days.';
    }
  }

  @override
  void dispose() { _prefix.dispose(); _terms.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Sec('Invoice Defaults'),
      _F('Invoice Number Prefix', _prefix, hint: 'INV-'),
      _Label('Default Terms & Conditions'),
      TextField(
        controller: _terms, maxLines: 4,
        decoration: InputDecoration(
          hintText: 'Payment terms...',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
          contentPadding: const EdgeInsets.all(13)),
        style: GoogleFonts.dmSans(fontSize: 13.5)),
      const Gap(20),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
        child: _saving
          ? const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text('Save Defaults', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700)))),
    ]),
  );

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final existing = ref.read(businessProvider) ?? Business();
      await ref.read(businessProvider.notifier).save(existing.copyWith(
        invoicePrefix: _prefix.text.trim().isEmpty ? 'INV-' : _prefix.text.trim(),
        defaultTerms: _terms.text.trim()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Defaults saved \u2713'), backgroundColor: AppColors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── About Panel ──────────────────────────────────────────────────────────
class _AboutPanel extends StatelessWidget {
  const _AboutPanel();
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(14),
    child: Column(children: [
      const Gap(20),
      ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.asset('assets/icon.png',
          width: 90, height: 90, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 90, height: 90,
            decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(22)),
            child: const Center(child: Text('⚡', style: TextStyle(fontSize: 42)))))),
      const Gap(16),
      Text('BillZap', style: GoogleFonts.nunito(
        fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.t1)),
      Text('v1.3.0 \u00b7 GST Billing for India', style: GoogleFonts.dmSans(
        fontSize: 13, color: AppColors.t3)),
      const Gap(20),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.greenSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.green.withOpacity(0.25))),
        child: Column(children: [
          Text('\u2705 100% Offline \u2014 No Internet Needed', style: GoogleFonts.dmSans(
            fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.green)),
          const Gap(5),
          Text('All your data lives on your device.\nNo cloud, no servers, no privacy concerns.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 12.5, color: AppColors.t2)),
        ])),
      const Gap(14),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.card,
          borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Features', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800)),
          const Gap(10),
          ...['GST Invoice (CGST / SGST / IGST)',
              'PDF generation & WhatsApp share',
              'Customer & Product catalog',
              'Expense tracker & P&L report',
              'Business analytics & reports',
              'Fully offline — works anywhere',
              'Free forever — no subscriptions'].map((f) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.green),
              const Gap(8),
              Text(f, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.t2)),
            ]))),
        ])),
      const Gap(20),
      Text('Made with \u2764\ufe0f in Coimbatore, Tamil Nadu \ud83c\uddee\ud83c\uddf3',
        style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.t3)),
      const Gap(4),
      Text('\u00a9 2026 BillZap Technologies', style: GoogleFonts.dmSans(
        fontSize: 12, color: AppColors.t4)),
      const Gap(20),
    ]));
}

// ─── Shared helpers ───────────────────────────────────────────────────────
Widget _Sec(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Text(t, style: GoogleFonts.nunito(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.t1)));

Widget _Label(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 5),
  child: Text(t, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.t3)));

Widget _F(String label, TextEditingController ctrl,
    {String? hint, TextInputType? type, bool caps = false, int? max}) =>
  Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Label(label),
      TextField(controller: ctrl, keyboardType: type, maxLength: max,
        textCapitalization: caps ? TextCapitalization.characters : TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: hint, counterText: '',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.brand, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13)),
        style: GoogleFonts.dmSans(fontSize: 13.5, color: AppColors.t1)),
    ]));
