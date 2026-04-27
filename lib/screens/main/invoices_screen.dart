// lib/screens/main/invoices_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../i18n/translations.dart';

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});
  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesState();
}

class _InvoicesState extends ConsumerState<InvoicesScreen> {
  String _filter = 'all';
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<Invoice> _filtered(List<Invoice> all) {
    var list = all;
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((i) =>
        i.customerName.toLowerCase().contains(q) ||
        i.invoiceNumber.toLowerCase().contains(q)).toList();
    }
    switch (_filter) {
      case 'paid':    return list.where((i) => i.status == InvoiceStatus.paid).toList();
      case 'sent':    return list.where((i) => i.status == InvoiceStatus.sent && !i.isOverdue).toList();
      case 'pending': return list.where((i) => i.status == InvoiceStatus.pending && !i.isOverdue).toList();
      case 'overdue': return list.where((i) => i.isOverdue).toList();
      case 'draft':   return list.where((i) => i.status == InvoiceStatus.draft).toList();
      default:        return list;
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(invoiceProvider);
    final list = _filtered(all);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.card,
        title: Text(tr('inv.title', ref), style: GoogleFonts.plusJakartaSans(
          fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.t1)),
        actions: [
          IconButton(
            icon: const Icon(Symbols.add, color: AppColors.brand, size: 26),
            onPressed: () => context.push('/create')),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search invoices or customers...',
                prefixIcon: const Icon(Symbols.search, size: 18, color: AppColors.t3),
                filled: true, fillColor: AppColors.bg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border)),
                suffixIcon: _search.isNotEmpty
                  ? IconButton(icon: const Icon(Symbols.close, size: 16),
                      onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); })
                  : null,
              ),
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
          ),
        ),
      ),
      body: Column(children: [
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Row(
            children: ['all', 'paid', 'sent', 'pending', 'overdue', 'draft'].map((f) =>
              Padding(
                padding: const EdgeInsets.only(right: 7),
                child: GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _filter == f ? AppColors.brand : AppColors.card,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: _filter == f ? AppColors.brand : AppColors.border)),
                    child: Text(f[0].toUpperCase() + f.substring(1),
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600,
                        color: _filter == f ? Colors.white : AppColors.t2)),
                  ),
                ),
              )).toList(),
          ),
        ),

        // List
        Expanded(child: list.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Symbols.receipt_long, size: 48, color: AppColors.t4),
              const Gap(10),
              Text(_search.isNotEmpty ? 'No results found' : 'No invoices',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.t1)),
              const Gap(6),
              Text(_search.isNotEmpty ? 'Try a different search' : 'Tap + to create one',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.t3)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final inv = list[i];
                final c = inv.status == InvoiceStatus.paid ? AppColors.green
                    : inv.isOverdue ? AppColors.red : AppColors.yellow;
                return GestureDetector(
                  onTap: () {
                    ref.read(selectedInvoiceProvider.notifier).state = inv;
                    context.push('/preview');
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.card,
                      borderRadius: BorderRadius.circular(13), border: Border.all(color: AppColors.border)),
                    child: Row(children: [
                      Container(width: 40, height: 40,
                        decoration: BoxDecoration(color: AppColors.brandSoft,
                          borderRadius: BorderRadius.circular(10)),
                        child: Center(child: Text(
                          inv.customerName.isNotEmpty ? inv.customerName[0].toUpperCase() : '?',
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.brand)))),
                      const Gap(12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(inv.customerName, style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.t1)),
                        Text('${inv.invoiceNumber} \u00b7 Due ${DateFormat('dd MMM yyyy').format(inv.dueDate)}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.t3)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(formatCurrency(inv.grandTotal), style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.t1)),
                        const Gap(3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: c.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(99)),
                          child: Text(inv.isOverdue ? 'OVERDUE' : inv.status.name.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w800, color: c))),
                      ]),
                    ]),
                  ),
                );
              }),
        ),
      ]),
    );
  }
}
