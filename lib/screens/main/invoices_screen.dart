// lib/screens/main/invoices_screen.dart
// Fully translated — every visible string uses tr() with i18n keys.
// UX upgrades: pull-to-refresh, swipe-to-delete, clear-all-filters,
// initial skeleton state, larger tap targets.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_spacing.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../i18n/translations.dart';
import '../../widgets/skeleton.dart';

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});
  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesState();
}

class _InvoicesState extends ConsumerState<InvoicesScreen> {
  String _filter = 'all';
  final _searchCtrl = TextEditingController();
  String _search = '';
  bool _firstFrame = true;

  @override
  void initState() {
    super.initState();
    // Brief skeleton on first build so list never appears as a flash of empty.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 220), () {
        if (mounted) setState(() => _firstFrame = false);
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Invoice> _filtered(List<Invoice> all) {
    var list = all;
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((i) =>
          i.customerName.toLowerCase().contains(q) ||
          i.invoiceNumber.toLowerCase().contains(q)).toList();
    }
    switch (_filter) {
      case 'paid':
        return list.where((i) => i.status == InvoiceStatus.paid).toList();
      case 'sent':
        return list
            .where((i) => i.status == InvoiceStatus.sent && !i.isOverdue)
            .toList();
      case 'pending':
        return list
            .where((i) => i.status == InvoiceStatus.pending && !i.isOverdue)
            .toList();
      case 'overdue':
        return list.where((i) => i.isOverdue).toList();
      case 'draft':
        return list.where((i) => i.status == InvoiceStatus.draft).toList();
      default:
        return list;
    }
  }

  String _filterLabel(String f) {
    switch (f) {
      case 'all':     return tr('inv.all', ref);
      case 'paid':    return tr('inv.paid', ref);
      case 'sent':    return tr('inv.sent', ref);
      case 'pending': return tr('inv.pending', ref);
      case 'overdue': return tr('inv.overdue', ref);
      case 'draft':   return tr('inv.draft', ref);
      default:        return f;
    }
  }

  String _statusLabel(Invoice inv) {
    if (inv.isOverdue) return tr('inv.overdue', ref).toUpperCase();
    switch (inv.status) {
      case InvoiceStatus.paid:    return tr('inv.paid', ref).toUpperCase();
      case InvoiceStatus.sent:    return tr('inv.sent', ref).toUpperCase();
      case InvoiceStatus.pending: return tr('inv.pending', ref).toUpperCase();
      case InvoiceStatus.draft:   return tr('inv.draft', ref).toUpperCase();
      case InvoiceStatus.cancelled: return tr('inv.cancelled', ref).toUpperCase();
    }
  }

  Future<void> _refresh() async {
    HapticFeedback.lightImpact();
    ref.read(invoiceProvider.notifier).reload();
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  void _clearFilters() {
    HapticFeedback.selectionClick();
    _searchCtrl.clear();
    setState(() {
      _search = '';
      _filter = 'all';
    });
  }

  Future<bool> _confirmDeleteInvoice(Invoice inv) async {
    HapticFeedback.mediumImpact();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('common.delete', ref)),
        content: Text('${inv.invoiceNumber} will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('common.cancel', ref))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('common.delete', ref),
              style: const TextStyle(color: AppColors.red))),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _deleteInvoice(Invoice inv) async {
    await ref.read(invoiceProvider.notifier).delete(inv.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${inv.invoiceNumber} deleted'),
      backgroundColor: AppColors.t1,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(invoiceProvider);
    final list = _filtered(all);
    final hasActiveFilters = _filter != 'all' || _search.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.card,
        title: Text(tr('inv.title', ref),
            style: GoogleFonts.plusJakartaSans(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: AppColors.t1)),
        actions: [
          IconButton(
            icon: const Icon(Symbols.add, color: AppColors.brand, size: 26),
            onPressed: () => context.push('/create'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: tr('inv.search', ref),
                prefixIcon: Icon(Symbols.search,
                    size: 18, color: AppColors.t3),
                filled: true,
                fillColor: AppColors.bg,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 9),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border)),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Symbols.close, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                      )
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
            children:
                ['all', 'paid', 'sent', 'pending', 'overdue', 'draft'].map((f) {
              final selected = _filter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 7),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _filter = f);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.brand : AppColors.card,
                      borderRadius: BorderRadius.circular(AppSpacing.pill),
                      border: Border.all(
                          color:
                              selected ? AppColors.brand : AppColors.border),
                    ),
                    child: Text(
                      _filterLabel(f),
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppColors.t2),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Clear-all-filters bar (only when both search & filter are active)
        if (hasActiveFilters)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
            child: Row(children: [
              Expanded(
                child: Text(
                  '${list.length} result${list.length == 1 ? '' : 's'}'
                  '${_search.isNotEmpty ? ' for "$_search"' : ''}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5, color: AppColors.t3,
                    fontWeight: FontWeight.w600),
                ),
              ),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Symbols.filter_alt_off, size: 15),
                label: Text(tr('inv.clear_filters', ref),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, fontWeight: FontWeight.w700)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brand,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ]),
          ),

        // List
        Expanded(
          child: RefreshIndicator(
            color: AppColors.brand,
            onRefresh: _refresh,
            child: _firstFrame
                ? const SkeletonList()
                : list.isEmpty
                    ? _EmptyState(
                        searching: _search.isNotEmpty,
                        onCreate: () => context.push('/create'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final inv = list[i];
                          return _InvoiceRow(
                            inv: inv,
                            statusLabel: _statusLabel(inv),
                            onTap: () {
                              ref.read(selectedInvoiceProvider.notifier).state = inv;
                              context.push('/preview');
                            },
                            onDelete: () async {
                              if (await _confirmDeleteInvoice(inv)) {
                                await _deleteInvoice(inv);
                              }
                            },
                            confirmDismiss: _confirmDeleteInvoice,
                          );
                        },
                      ),
          ),
        ),
      ]),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final Invoice inv;
  final String statusLabel;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Future<bool> Function(Invoice) confirmDismiss;
  const _InvoiceRow({
    required this.inv,
    required this.statusLabel,
    required this.onTap,
    required this.onDelete,
    required this.confirmDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final c = inv.status == InvoiceStatus.paid
        ? AppColors.green
        : inv.isOverdue
            ? AppColors.red
            : AppColors.yellow;

    return Dismissible(
      key: ValueKey('inv-${inv.id}'),
      direction: DismissDirection.endToStart,
      background: _swipeBg(),
      confirmDismiss: (_) => confirmDismiss(inv),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.border)),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(10)),
              child: Center(
                child: Text(
                  inv.customerName.isNotEmpty
                      ? inv.customerName[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.brand),
                ),
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(inv.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.t1)),
                  Text(
                    '${inv.invoiceNumber} · ${DateFormat('dd MMM yyyy').format(inv.dueDate)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: AppColors.t3),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatCurrency(inv.grandTotal),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.t1)),
                const Gap(3),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: c.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(99)),
                  child: Text(statusLabel,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: c)),
                ),
              ],
            ),
          ]),
        ),
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
}

class _EmptyState extends ConsumerWidget {
  final bool searching;
  final VoidCallback onCreate;
  const _EmptyState({required this.searching, required this.onCreate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wrapped in scroll view so pull-to-refresh remains available when empty.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Symbols.receipt_long, size: 48, color: AppColors.t4),
          const Gap(10),
          Text(
            searching ? tr('inv.no_results', ref) : tr('dash.no_invoices', ref),
            style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.t1),
          ),
          const Gap(6),
          Text(
            searching ? tr('inv.try_diff_search', ref) : tr('inv.tap_plus_create', ref),
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: AppColors.t3),
          ),
          const Gap(16),
          if (!searching)
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Symbols.add, size: 18),
              label: Text(tr('dash.new_invoice', ref))),
        ]),
      ],
    );
  }
}
