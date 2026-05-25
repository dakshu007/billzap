// lib/screens/main/customers_screen.dart
// UX upgrades: pull-to-refresh, swipe-to-delete, initial skeleton,
// success snackbar + haptics, GSTIN validation in add sheet.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_spacing.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../i18n/translations.dart';
import '../../utils/validators.dart';
import '../../widgets/skeleton.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});
  @override
  ConsumerState<CustomersScreen> createState() => _CustomersState();
}

class _CustomersState extends ConsumerState<CustomersScreen> {
  bool _firstFrame = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 220), () {
        if (mounted) setState(() => _firstFrame = false);
      });
    });
  }

  Future<void> _refresh() async {
    HapticFeedback.lightImpact();
    ref.read(customerProvider.notifier).reload();
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  Future<bool> _confirmDelete(Customer c) async {
    HapticFeedback.mediumImpact();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(trGlobal('common.delete')),
        content: Text('${c.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(trGlobal('common.cancel'))),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(trGlobal('common.delete'),
              style: const TextStyle(color: AppColors.red))),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _doDelete(Customer c) async {
    await ref.read(customerProvider.notifier).delete(c.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${c.name} deleted'),
      backgroundColor: AppColors.t1,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final custs = ref.watch(customerProvider);
    final invs  = ref.watch(invoiceProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        leading: IconButton(
          icon: Icon(Symbols.arrow_back, color: AppColors.t1, size: 24),
          tooltip: trGlobal('common.cancel'),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(tr('cust.title', ref), style: GoogleFonts.plusJakartaSans(
          fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.t1)),
        actions: [
          IconButton(
            icon: const Icon(Symbols.person_add, color: AppColors.brand),
            onPressed: () => _addSheet(context, ref)),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.brand,
        onRefresh: _refresh,
        child: _firstFrame
          ? const SkeletonList()
          : custs.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Symbols.group, size: 48, color: AppColors.t4),
                    const Gap(10),
                    Text(tr('cust.no_customers', ref), style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, fontWeight: FontWeight.w800)),
                    const Gap(6),
                    Text(tr('cust.tap_add', ref), style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: AppColors.t3)),
                    const Gap(16),
                    ElevatedButton.icon(
                      onPressed: () => _addSheet(context, ref),
                      icon: const Icon(Symbols.person_add, size: 18),
                      label: Text(tr('cust.add_new', ref))),
                  ]),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppSpacing.listScreen,
                itemCount: custs.length,
                itemBuilder: (ctx, i) {
                  final c   = custs[i];
                  final ci  = invs.where((inv) => inv.customerName == c.name).toList();
                  final tot = ci.fold<double>(0, (s, inv) => s + inv.grandTotal);
                  return Dismissible(
                    key: ValueKey('cust-${c.id}'),
                    direction: DismissDirection.endToStart,
                    background: _swipeBg(),
                    confirmDismiss: (_) => _confirmDelete(c),
                    onDismissed: (_) => _doDelete(c),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.card,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: AppColors.border)),
                      child: Row(children: [
                        Container(width: 42, height: 42,
                          decoration: BoxDecoration(color: AppColors.brandSoft,
                            borderRadius: BorderRadius.circular(11)),
                          child: Center(child: Text(
                            c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17, fontWeight: FontWeight.w900,
                              color: AppColors.brand)))),
                        const Gap(12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(c.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.t1)),
                          if (c.phone.isNotEmpty)
                            Text(c.phone, style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, color: AppColors.t3)),
                          if (c.gstin.isNotEmpty)
                            Text('GSTIN: ${c.gstin}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5, color: AppColors.t4)),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(formatCurrency(tot), style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.t1)),
                          Text('${ci.length} ${tr('cust.inv_short', ref)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5, color: AppColors.t3)),
                          const Gap(4),
                          IconButton(
                            icon: const Icon(Symbols.delete, size: 18, color: AppColors.red),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: tr('common.delete', ref),
                            onPressed: () async {
                              if (await _confirmDelete(c)) {
                                await _doDelete(c);
                              }
                            },
                          ),
                        ]),
                      ]),
                    ),
                  );
                }),
      ),
    );
  }

  Widget _swipeBg() => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: AppColors.red,
      borderRadius: BorderRadius.circular(13),
    ),
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.symmetric(horizontal: 22),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Symbols.delete, color: Colors.white, size: 20),
        SizedBox(width: 6),
        Text('Delete',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13)),
      ],
    ),
  );

  void _addSheet(BuildContext context, WidgetRef ref) {
    final name  = TextEditingController();
    final phone = TextEditingController();
    final gstin = TextEditingController();
    final addr  = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) {
          bool saving = false;
          String? gstinErr;
          String? phoneErr;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(99)))),
                  const Gap(16),
                  Text(trGlobal('cust.add_new'), style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w800)),
                  const Gap(16),
                  TextField(controller: name,
                    decoration: InputDecoration(labelText: trGlobal('cust.name'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10))),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5)),
                  const Gap(10),
                  TextField(controller: phone,
                    keyboardType: TextInputType.phone,
                    onChanged: (v) => ss(() => phoneErr = Validators.phone(v)),
                    decoration: InputDecoration(
                      labelText: trGlobal('cust.phone'),
                      errorText: phoneErr,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10))),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5)),
                  const Gap(10),
                  Row(children: [
                    Expanded(child: TextField(controller: gstin,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (v) => ss(() => gstinErr = Validators.gstin(v)),
                      decoration: InputDecoration(
                        labelText: trGlobal('cust.gstin'),
                        errorText: gstinErr,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10))),
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5))),
                    const Gap(10),
                    Expanded(child: TextField(controller: addr,
                      decoration: InputDecoration(labelText: trGlobal('set.city'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10))),
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5))),
                  ]),
                  const Gap(20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving ? null : () async {
                        if (name.text.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Text(trGlobal('cust.required')),
                            backgroundColor: AppColors.red));
                          return;
                        }
                        if (gstinErr != null || phoneErr != null) return;
                        ss(() => saving = true);
                        try {
                          await ref.read(customerProvider.notifier).add(
                            Customer(
                              name: name.text.trim(),
                              phone: phone.text.trim(),
                              gstin: gstin.text.trim().toUpperCase(),
                              city: addr.text.trim()));
                          if (ctx.mounted) {
                            HapticFeedback.mediumImpact();
                            Navigator.pop(ctx);
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('${name.text.trim()} added ✓'),
                              backgroundColor: AppColors.green));
                          }
                        } finally {
                          if (ctx.mounted) ss(() => saving = false);
                        }
                      },
                      child: saving
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                        : Text(trGlobal('common.save')))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
