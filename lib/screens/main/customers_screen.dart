// lib/screens/main/customers_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final custs = ref.watch(customerProvider);
    final invs  = ref.watch(invoiceProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false, backgroundColor: AppColors.card,
        title: Text('Customers', style: GoogleFonts.nunito(
          fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.t1)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: AppColors.brand),
            onPressed: () => _addSheet(context, ref)),
        ],
      ),
      body: custs.isEmpty
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.group_rounded, size: 48, color: AppColors.t4),
            const Gap(10),
            Text('No customers yet', style: GoogleFonts.nunito(
              fontSize: 16, fontWeight: FontWeight.w800)),
            const Gap(6),
            Text('Add your first customer', style: GoogleFonts.dmSans(
              fontSize: 13, color: AppColors.t3)),
            const Gap(16),
            ElevatedButton.icon(
              onPressed: () => _addSheet(context, ref),
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Add Customer')),
          ]))
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
            itemCount: custs.length,
            itemBuilder: (_, i) {
              final c   = custs[i];
              final ci  = invs.where((inv) => inv.customerName == c.name).toList();
              final tot = ci.fold<double>(0, (s, inv) => s + inv.grandTotal);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.card,
                  borderRadius: BorderRadius.circular(13), border: Border.all(color: AppColors.border)),
                child: Row(children: [
                  Container(width: 42, height: 42,
                    decoration: BoxDecoration(color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(11)),
                    child: Center(child: Text(c.name[0].toUpperCase(),
                      style: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.brand)))),
                  const Gap(12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.name, style: GoogleFonts.dmSans(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.t1)),
                    if (c.phone.isNotEmpty)
                      Text(c.phone, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.t3)),
                    if (c.gstin.isNotEmpty)
                      Text('GSTIN: ${c.gstin}', style: GoogleFonts.dmSans(fontSize: 10.5, color: AppColors.t4)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(formatCurrency(tot), style: GoogleFonts.nunito(
                      fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.t1)),
                    Text('${ci.length} inv', style: GoogleFonts.dmSans(
                      fontSize: 10.5, color: AppColors.t3)),
                    const Gap(2),
                    GestureDetector(
                      onTap: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete customer?'),
                            content: Text('${c.name} will be removed.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete', style: TextStyle(color: AppColors.red))),
                            ],
                          ),
                        );
                        if (ok == true) ref.read(customerProvider.notifier).delete(c.id);
                      },
                      child: const Icon(Icons.delete_rounded, size: 16, color: AppColors.red)),
                  ]),
                ]),
              );
            }),
    );
  }

  void _addSheet(BuildContext context, WidgetRef ref) {
    final name  = TextEditingController();
    final phone = TextEditingController();
    final gstin = TextEditingController();
    final addr  = TextEditingController();
    bool saving = false;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(99)))),
            const Gap(16),
            Text('Add Customer', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800)),
            const Gap(16),
            _TFSheet('Name *', name), const Gap(10),
            _TFSheet('Phone', phone, type: TextInputType.phone), const Gap(10),
            Row(children: [
              Expanded(child: _TFSheet('GSTIN', gstin, caps: true)),
              const Gap(10),
              Expanded(child: _TFSheet('City', addr)),
            ]),
            const Gap(20),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: saving ? null : () async {
                if (name.text.trim().isEmpty) return;
                ss(() => saving = true);
                try {
                  await ref.read(customerProvider.notifier).add(Customer(
                    name: name.text.trim(), phone: phone.text.trim(),
                    gstin: gstin.text.trim().toUpperCase(), city: addr.text.trim()));
                  if (ctx.mounted) Navigator.pop(ctx);
                } finally {
                  if (ctx.mounted) ss(() => saving = false);
                }
              },
              child: saving
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save Customer'))),
          ]),
        ),
      )),
    );
  }
}

Widget _TFSheet(String label, TextEditingController ctrl,
  {TextInputType? type, bool caps = false}) =>
  TextField(
    controller: ctrl, keyboardType: type,
    textCapitalization: caps ? TextCapitalization.characters : TextCapitalization.sentences,
    decoration: InputDecoration(labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
    style: GoogleFonts.dmSans(fontSize: 13.5),
  );
