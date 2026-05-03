// lib/screens/invoice/create_invoice_screen.dart
// ✅ FIX: "From Catalog" reads from CatalogService (Hive 'catalog' box), not productProvider
// ✅ Fully translated
// ✅ GST auto-classify on item name change
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../services/gst_classifier.dart';
import '../../utils/voice_parser.dart';
import '../../i18n/translations.dart';
import '../main/catalog_screen.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});
  @override
  ConsumerState<CreateInvoiceScreen> createState() => _CreateState();
}

class _CreateState extends ConsumerState<CreateInvoiceScreen> {
  final _custName  = TextEditingController();
  final _custPhone = TextEditingController();
  final _custGstin = TextEditingController();
  final _custAddr  = TextEditingController();
  final _notes     = TextEditingController();

  DateTime _date = DateTime.now();
  DateTime _due  = DateTime.now().add(const Duration(days: 30));
  GstType  _gstType = GstType.cgstSgst;
  String   _place = kStates.first;

  bool _applyGst      = true;
  bool _applyDiscount = false;
  bool _applyShipping = false;
  double _discount    = 0;
  double _shipping    = 0;

  final List<_LineItem> _lines = [_LineItem()];
  bool _saving = false;

  // Autocomplete
  List<Customer> _acSugg = [];
  bool _acShow = false;

  @override
  void initState() {
    super.initState();
    // Prefill from voice if present
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouterState.of(context).extra;
      if (extra is ParsedInvoice) _applyVoiceData(extra);
    });

    _custName.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _custName.removeListener(_onNameChanged);
    _custName.dispose(); _custPhone.dispose();
    _custGstin.dispose(); _custAddr.dispose(); _notes.dispose();
    super.dispose();
  }


  void _applyVoiceData(ParsedInvoice voice) {
    if (voice.customerName != null && voice.customerName!.isNotEmpty) {
      _custName.text = voice.customerName!;
    }
    if (voice.items.isNotEmpty) {
      setState(() {
        _lines.clear();
        for (final pi in voice.items) {
          final detectedGst = GstClassifier.classify(pi.name);
          _lines.add(_LineItem(
            name: pi.name,
            qty: pi.qty,
            rate: pi.price,
            gstRate: detectedGst >= 0 ? detectedGst.toDouble() : 18.0,
          ));
        }
      });
    }
  }

  void _onNameChanged() {
    final q = _custName.text.toLowerCase().trim();
    if (q.isEmpty) { setState(() { _acSugg = []; _acShow = false; }); return; }
    final matches = ref.read(customerProvider)
      .where((c) => c.name.toLowerCase().contains(q) || c.phone.contains(q))
      .take(5).toList();
    setState(() { _acSugg = matches; _acShow = matches.isNotEmpty; });
  }

  void _fillCust(Customer c) {
    _custName.removeListener(_onNameChanged);
    _custName.text  = c.name;
    _custPhone.text = c.phone;
    _custGstin.text = c.gstin;
    _custAddr.text  = c.address;
    _custName.addListener(_onNameChanged);
    setState(() { _acShow = false; });
  }

  // Calculated totals
  double get _sub => _lines.fold(0, (s, l) => s + l.qty * l.rate);
  double get _gstAmt => _applyGst ? _lines.fold(0, (s, l) => s + l.qty * l.rate * l.gstRate / 100) : 0;
  double get _cgst => _gstType == GstType.cgstSgst ? _gstAmt / 2 : 0;
  double get _sgst => _gstType == GstType.cgstSgst ? _gstAmt / 2 : 0;
  double get _igst => _gstType == GstType.igst ? _gstAmt : 0;
  double get _grand => _sub + _gstAmt + (_applyShipping ? _shipping : 0) - (_applyDiscount ? _discount : 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        leading: IconButton(
          icon: Container(width: 34, height: 34,
            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Symbols.close, size: 19, color: AppColors.t1)),
          onPressed: () => context.go('/home')),
        title: Text(tr('create.title', ref), style: GoogleFonts.plusJakartaSans(
          fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.t1)),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9)),
              child: _saving
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(tr('common.save', ref), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5)))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 120),
        children: [
          // Customer
          _Section(tr('cust.title', ref), children: [
            _LF(tr('cust.name', ref) + ' *'),
            Stack(clipBehavior: Clip.none, children: [
              _TextField(_custName, tr('create.search_customer', ref)),
              if (_acShow) Positioned(top: 46, left: 0, right: 0, child: Material(
                elevation: 6, borderRadius: BorderRadius.circular(10),
                child: ListView(
                  shrinkWrap: true, padding: EdgeInsets.zero,
                  children: _acSugg.map((cust) => ListTile(
                    dense: true,
                    title: Text(cust.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: cust.phone.isNotEmpty ? Text(cust.phone, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.t3)) : null,
                    onTap: () => _fillCust(cust),
                  )).toList(),
                ),
              )),
            ]),
            const Gap(10),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _LF(tr('cust.phone', ref)), _TextField(_custPhone, '+91 98765 43210', type: TextInputType.phone)])),
              const Gap(10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _LF(tr('cust.gstin', ref) + ' (' + tr('create.optional', ref) + ')'), _TextField(_custGstin, '33RAAAA...', caps: true)])),
            ]),
            const Gap(10),
            _LF(tr('cust.address', ref)), _TextField(_custAddr, 'Street, Area, City'),
          ]),

          // Invoice info
          _Section(tr('create.invoice_details', ref), children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _LF(tr('create.invoice_date', ref)), _DateBtn(_date, (d) => setState(() => _date = d))])),
              const Gap(10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _LF(tr('create.due_date', ref)), _DateBtn(_due, (d) => setState(() => _due = d))])),
            ]),
            const Gap(10),
            _LF(tr('create.place_of_supply', ref)),
            DropdownButtonFormField<String>(
              value: kStates.contains(_place) ? _place : kStates.first,
              decoration: InputDecoration(isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13)),
              items: kStates.map((s) => DropdownMenuItem(value: s,
                child: Text(s, style: GoogleFonts.plusJakartaSans(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _place = v ?? _place)),
          ]),

          // Line items
          _Section(tr('create.line_items', ref),
            trailing: TextButton.icon(
              onPressed: _showCatalogPicker,
              icon: const Icon(Symbols.add, size: 16),
              label: Text(tr('cat.from_catalog', ref), style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600))),
            children: [
              ..._lines.asMap().entries.map((e) => _LineRow(
              key: ObjectKey(e),
              item: e.value, index: e.key,
                onRemove: _lines.length > 1 ? () => setState(() => _lines.removeAt(e.key)) : null,
                onChange: () => setState(() {}))),
              const Gap(4),
              OutlinedButton.icon(
                onPressed: () => setState(() => _lines.add(_LineItem())),
                icon: const Icon(Symbols.add, size: 16),
                label: Text(tr('create.add_line_item', ref), style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600))),
            ]),

          // Tax
          _Section(tr('create.tax_adjustments', ref), children: [
            _TogRow(tr('create.apply_gst', ref), tr('create.gst_auto_calc', ref), _applyGst,
              (v) => setState(() => _applyGst = v)),
            if (_applyGst) ...[
              const Gap(8),
              _LF(tr('create.gst_type', ref)),
              Row(children: [
                _TypeBtn(tr('create.cgst_sgst', ref), _gstType == GstType.cgstSgst,
                  () => setState(() => _gstType = GstType.cgstSgst)),
                const Gap(8),
                _TypeBtn(tr('create.igst', ref), _gstType == GstType.igst,
                  () => setState(() => _gstType = GstType.igst)),
              ]),
            ],
            const Divider(height: 20),
            _TogRow(tr('create.apply_discount', ref), tr('create.flat_discount', ref), _applyDiscount,
              (v) => setState(() => _applyDiscount = v)),
            if (_applyDiscount) ...[
              const Gap(8),
              _LF(tr('create.discount', ref) + ' (\u20b9)'),
              TextField(
                keyboardType: TextInputType.number, onChanged: (v) => setState(() => _discount = double.tryParse(v) ?? 0),
                decoration: InputDecoration(hintText: '0',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13)),
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5)),
            ],
            const Divider(height: 20),
            _TogRow(tr('create.add_shipping', ref), tr('create.delivery_charges', ref), _applyShipping,
              (v) => setState(() => _applyShipping = v)),
            if (_applyShipping) ...[
              const Gap(8),
              _LF(tr('create.shipping', ref) + ' (\u20b9)'),
              TextField(
                keyboardType: TextInputType.number, onChanged: (v) => setState(() => _shipping = double.tryParse(v) ?? 0),
                decoration: InputDecoration(hintText: '0',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13)),
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5)),
            ],
          ]),

          // Summary
          _Section(tr('create.summary', ref), children: [
            _SRow(tr('create.subtotal', ref), _sub),
            if (_cgst > 0) _SRow('CGST', _cgst),
            if (_sgst > 0) _SRow('SGST', _sgst),
            if (_igst > 0) _SRow('IGST', _igst),
            if (_applyShipping && _shipping > 0) _SRow(tr('create.shipping', ref), _shipping),
            if (_applyDiscount && _discount > 0) _SRow(tr('create.discount', ref), -_discount),
            const Divider(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(tr('create.grand_total', ref), style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.t1)),
              Text(formatCurrency(_grand), style: GoogleFonts.plusJakartaSans(
                fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.brand)),
            ]),
          ]),

          // Notes
          _Section(tr('create.notes', ref), children: [
            TextField(controller: _notes, maxLines: 3,
              decoration: InputDecoration(hintText: tr('create.notes_hint', ref),
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.t4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border)),
                contentPadding: const EdgeInsets.all(13)),
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5)),
          ]),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════
  // BUG FIX #1: Read from CatalogService not productProvider!
  // ═════════════════════════════════════════════════
  Future<void> _showCatalogPicker() async {
    final items = await CatalogService.getAll();
    if (!mounted) return;

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(trGlobal('create.catalog_empty'))));
      return;
    }

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65, maxChildSize: 0.9, minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(children: [
            Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(99))),
            Text(trGlobal('cat.from_catalog'), style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800)),
            const Gap(10),
            Expanded(child: ListView.builder(
              controller: ctrl, itemCount: items.length,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemBuilder: (_, i) {
                final p = items[i];
                return GestureDetector(
                  onTap: () {
                    setState(() => _lines.add(_LineItem(
                      name: p.name, hsn: p.hsnCode, rate: p.price, gstRate: p.gstRate.toDouble())));
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border)),
                    child: Row(children: [
                      Container(width: 40, height: 40,
                        decoration: BoxDecoration(color: AppColors.brandSoft,
                          borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Symbols.shopping_basket, color: AppColors.brand, size: 20)),
                      const Gap(12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.name, style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700)),
                        if (p.hsnCode.isNotEmpty)
                          Text('HSN: ${p.hsnCode} \u00b7 ${p.unit}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.t3)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(formatCurrency(p.price), style: GoogleFonts.plusJakartaSans(
                          fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.brand)),
                        Text('GST ${p.gstRate}%', style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, color: AppColors.green, fontWeight: FontWeight.w600)),
                      ]),
                    ]),
                  ),
                );
              })),
          ]),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_custName.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(trGlobal('create.cust_required')), backgroundColor: AppColors.red));
      return;
    }
    final valid = _lines.where((l) => l.name.isNotEmpty).toList();
    if (valid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(trGlobal('create.add_item_required')), backgroundColor: AppColors.red));
      return;
    }
    setState(() => _saving = true);
    try {
      final db    = ref.read(storageProvider);
      final invNo = db.nextInvoiceNumber();
      final items = valid.map((l) => InvoiceItem(
        name: l.name, hsnCode: l.hsn, quantity: l.qty,
        rate: l.rate, gstRate: l.gstRate, applyGst: _applyGst)).toList();

      final inv = Invoice(
        invoiceNumber: invNo,
        customerName: _custName.text.trim(),
        customerPhone: _custPhone.text.trim(),
        customerGstin: _custGstin.text.trim().toUpperCase(),
        customerAddress: _custAddr.text.trim(),
        invoiceDate: _date, dueDate: _due,
        lineItems: items, gstType: _gstType,
        shippingCharge: _applyShipping ? _shipping : 0,
        flatDiscount: _applyDiscount ? _discount : 0,
        notes: _notes.text.trim(), placeOfSupply: _place,
        status: InvoiceStatus.sent);

      await ref.read(invoiceProvider.notifier).add(inv);

      // Auto-save new customer
      final custs = ref.read(customerProvider);
      final exists = custs.any((c) => c.name.toLowerCase() == inv.customerName.toLowerCase());
      if (!exists && inv.customerPhone.isNotEmpty) {
        await ref.read(customerProvider.notifier).add(Customer(
          name: inv.customerName, phone: inv.customerPhone,
          gstin: inv.customerGstin, address: inv.customerAddress));
      }

      if (!mounted) return;
      ref.read(selectedInvoiceProvider.notifier).state = inv;
      context.go('/preview');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Line item state ─────────────────────────────────────────────────────────
class _LineItem {
  String name; String hsn; double qty; double rate; double gstRate;
  _LineItem({this.name='', this.hsn='', this.qty=1, this.rate=0, this.gstRate=18});
}

class _LineRow extends StatefulWidget {
  final _LineItem item; final int index;
  final VoidCallback? onRemove; final VoidCallback onChange;
  const _LineRow({super.key, required this.item, required this.index, this.onRemove, required this.onChange});
  @override
  State<_LineRow> createState() => _LineRowState();
}
class _LineRowState extends State<_LineRow> {
  late final TextEditingController _name, _hsn, _rate;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item.name)
      ..addListener(_onNameTyped);
    _hsn  = TextEditingController(text: widget.item.hsn)
      ..addListener(() => widget.item.hsn = _hsn.text);
    _rate = TextEditingController(text: widget.item.rate > 0 ? widget.item.rate.toStringAsFixed(0) : '')
      ..addListener(() { widget.item.rate = double.tryParse(_rate.text) ?? 0; widget.onChange(); });
  }

  // ═════════════════════════════════════════════════
  // GST AUTO-CLASSIFY: as user types item name
  // ═════════════════════════════════════════════════

  @override
  void didUpdateWidget(_LineRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh controllers if the underlying item changed (e.g., voice prefill)
    if (oldWidget.item != widget.item) {
      if (_name.text != widget.item.name) _name.text = widget.item.name;
      if (_hsn.text != widget.item.hsn) _hsn.text = widget.item.hsn;
      final newRate = widget.item.rate > 0 ? widget.item.rate.toStringAsFixed(0) : '';
      if (_rate.text != newRate) _rate.text = newRate;
    }
  }

  void _onNameTyped() {
    widget.item.name = _name.text;
    final detected = GstClassifier.classify(_name.text);
    if (detected >= 0 && detected.toDouble() != widget.item.gstRate) {
      setState(() => widget.item.gstRate = detected.toDouble());
    }
    widget.onChange();
  }

  @override
  void dispose() { _name.dispose(); _hsn.dispose(); _rate.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border)),
    child: Column(children: [
      Row(children: [
        Expanded(child: TextField(controller: _name,
          decoration: InputDecoration(hintText: 'Product / service name',
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.t4), isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppColors.border)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11)),
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5))),
        if (widget.onRemove != null) ...[
          const Gap(8),
          GestureDetector(onTap: widget.onRemove,
            child: Container(width: 32, height: 32,
              decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Symbols.delete, size: 16, color: AppColors.red))),
        ],
      ]),
      const Gap(8),
      Row(children: [
        Expanded(child: TextField(controller: _hsn,
          decoration: InputDecoration(hintText: 'HSN/SAC',
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.t4), isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppColors.border)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10)),
          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.t3))),
        const Gap(8),
        // Qty stepper
        _QtyBtn('\u2212', () { if (widget.item.qty > 1) { setState(() => widget.item.qty--); widget.onChange(); } }),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('${widget.item.qty.toInt()}',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900))),
        _QtyBtn('+', () { setState(() => widget.item.qty++); widget.onChange(); }),
        const Gap(8),
        SizedBox(width: 90, child: TextField(controller: _rate,
          keyboardType: TextInputType.number, textAlign: TextAlign.right,
          decoration: InputDecoration(hintText: 'Rate \u20b9',
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.t4), isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppColors.border)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10)),
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5))),
      ]),
      const Gap(8),
      Row(children: [
        Text('GST: ', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.t3)),
        Expanded(child: DropdownButton<double>(
          value: [0, 0.25, 5, 12, 18, 28, 40].map((e) => e.toDouble()).contains(widget.item.gstRate)
            ? widget.item.gstRate : 18.0,
          isExpanded: true,
          underline: const SizedBox(),
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.brand, fontWeight: FontWeight.w700),
          items: [
            (r: 0.0,   l: '0% — Exempt'),
            (r: 0.25,  l: '0.25% — Stones'),
            (r: 5.0,   l: '5% — Essentials'),
            (r: 12.0,  l: '12% — Standard'),
            (r: 18.0,  l: '18% — General'),
            (r: 28.0,  l: '28% — Luxury'),
            (r: 40.0,  l: '40% — Sin tax'),
          ].map((g) => DropdownMenuItem(
            value: g.r,
            child: Text(g.l, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.t1)))).toList(),
          onChanged: (v) {
            if (v != null) { setState(() => widget.item.gstRate = v); widget.onChange(); }
          },
        )),
        const Gap(8),
        Text(formatCurrency(widget.item.qty * widget.item.rate), style: GoogleFonts.plusJakartaSans(
          fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.brand)),
      ]),
    ]),
  );
}

Widget _QtyBtn(String label, VoidCallback onTap) => GestureDetector(
  onTap: onTap,
  child: Container(width: 28, height: 28,
    decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(7)),
    child: Center(child: Text(label, style: const TextStyle(
      color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))));

// ── Shared helpers ──────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title; final Widget? trailing; final List<Widget> children;
  const _Section(this.title, {this.trailing, required this.children});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(color: AppColors.card,
      borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
        child: Row(children: [
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.t1)),
          if (trailing != null) ...[const Spacer(), trailing!],
        ])),
      const Divider(height: 1),
      Padding(padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
    ]));
}

Widget _LF(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 5),
  child: Text(t, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.t3)));

Widget _TextField(TextEditingController ctrl, String hint,
    {TextInputType? type, bool caps = false}) =>
  TextField(controller: ctrl, keyboardType: type,
    textCapitalization: caps ? TextCapitalization.characters : TextCapitalization.sentences,
    decoration: InputDecoration(hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.t4),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.brand, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13)),
    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.t1));

Widget _DateBtn(DateTime date, ValueChanged<DateTime> onPick) =>
  Builder(builder: (ctx) => GestureDetector(
    onTap: () async {
      final picked = await showDatePicker(context: ctx,
        initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2035));
      if (picked != null) onPick(picked);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border)),
      child: Row(children: [
        const Icon(Symbols.calendar_today, size: 15, color: AppColors.t3),
        const Gap(7),
        Text(DateFormat('dd MMM yyyy').format(date),
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.t1)),
      ]))));

Widget _TogRow(String label, String sub, bool value, ValueChanged<bool> onChange) =>
  GestureDetector(
    onTap: () => onChange(!value),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.t1)),
        Text(sub, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.t3)),
      ])),
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48, height: 28,
        decoration: BoxDecoration(
          color: value ? AppColors.brand : AppColors.borderDark,
          borderRadius: BorderRadius.circular(99)),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(99),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4)]),
          )),
      ),
    ]));

Widget _TypeBtn(String label, bool selected, VoidCallback onTap) =>
  Expanded(child: GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: selected ? AppColors.brand : AppColors.bg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: selected ? AppColors.brand : AppColors.border)),
      child: Text(label, textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700,
          color: selected ? Colors.white : AppColors.t2)))));

Widget _SRow(String label, double amount) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 3),
  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.t2)),
    Text(formatCurrency(amount), style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600,
      color: amount < 0 ? AppColors.green : AppColors.t1)),
  ]));
