// lib/screens/main/invoices_screen.dart
//
// The invoice list. Behaviour is unchanged — search, status filters,
// pull-to-refresh, swipe-to-delete, the first-frame skeleton and the
// clear-all-filters bar all work exactly as before. The presentation now
// uses the shared kit: a rounded search well, ink filter pills, borderless
// list rows and a centred empty state.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:billzap/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_spacing.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../i18n/translations.dart';
import '../../utils/platform.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/ui_kit.dart';

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
              style: TextStyle(color: AppColors.red))),
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
    ));
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(invoiceProvider);
    final list = _filtered(all);
    final hasActiveFilters = _filter != 'all' || _search.isNotEmpty;
    const filters = ['all', 'paid', 'sent', 'pending', 'overdue', 'draft'];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.bg,
        toolbarHeight: 66,
        titleSpacing: AppSpacing.screenH,
        title: Text(tr('inv.title', ref),
            style: AppFont.sans(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
                color: AppColors.t1)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.screenH),
            child: AppIconButton(
              icon: Symbols.add,
              background: AppColors.brand,
              foreground: AppColors.onBrand,
              onTap: () => context.push('/create'),
            ),
          ),
        ],
      ),
      body: DesktopMaxWidth(child: Column(children: [
        // ─── Search ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH, 2, AppSpacing.screenH, 12),
          child: AppSearchField(
            controller: _searchCtrl,
            hint: tr('inv.search', ref),
            icon: Symbols.search,
            onChanged: (v) => setState(() => _search = v),
            trailing: _search.isEmpty
                ? null
                : GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _search = '');
                    },
                    child: Icon(Symbols.close, size: 17, color: AppColors.t3),
                  ),
          ),
        ),

        // ─── Status filters ──────────────────────────────────────────
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            itemCount: filters.length,
            separatorBuilder: (_, __) => const Gap(8),
            itemBuilder: (_, i) => AppPill(
              _filterLabel(filters[i]),
              selected: _filter == filters[i],
              onTap: () => setState(() => _filter = filters[i]),
            ),
          ),
        ),

        // ─── Result count + clear ────────────────────────────────────
        if (hasActiveFilters)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH, 12, AppSpacing.screenH, 0),
            child: Row(children: [
              Expanded(
                child: Text(
                  '${list.length} result${list.length == 1 ? '' : 's'}'
                  '${_search.isNotEmpty ? ' for "$_search"' : ''}',
                  style: AppFont.sans(
                    fontSize: 12.5, color: AppColors.t3,
                    fontWeight: FontWeight.w500),
                ),
              ),
              GestureDetector(
                onTap: _clearFilters,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Symbols.filter_alt_off, size: 15, color: AppColors.t2),
                    const Gap(6),
                    Text(tr('inv.clear_filters', ref),
                      style: AppFont.sans(
                        fontSize: 12.5, fontWeight: FontWeight.w600,
                        color: AppColors.t2)),
                  ]),
                ),
              ),
            ]),
          ),

        // ─── List ────────────────────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            color: AppColors.t1,
            backgroundColor: AppColors.card,
            onRefresh: _refresh,
            child: _firstFrame
                ? const SkeletonList()
                : list.isEmpty
                    ? _EmptyInvoices(
                        searching: _search.isNotEmpty,
                        onCreate: () => context.push('/create'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenH, 14,
                          AppSpacing.screenH, AppSpacing.bottomNavSafe),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final inv = list[i];
                          return _InvoiceRow(
                            inv: inv,
                            statusLabel: _statusLabel(inv),
                            onTap: () {
                              ref.read(selectedInvoiceProvider.notifier).select(inv);
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
      ])),
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
      child: AppListRow(
        onTap: onTap,
        leading: AppBadge(initial: inv.customerName, size: 46),
        title: inv.customerName,
        subtitle: '${inv.invoiceNumber} · '
            '${DateFormat('dd MMM yyyy').format(inv.dueDate)}',
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(formatCurrency(inv.grandTotal),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFont.sans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    color: AppColors.t1)),
            const Gap(5),
            AppPill(statusLabel, dense: true, tone: c),
          ],
        ),
      ),
    );
  }

  Widget _swipeBg() => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Symbols.delete, color: Colors.white, size: 19),
            const Gap(8),
            Text('Delete',
                style: AppFont.sans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5)),
          ],
        ),
      );
}

class _EmptyInvoices extends ConsumerWidget {
  final bool searching;
  final VoidCallback onCreate;
  const _EmptyInvoices({required this.searching, required this.onCreate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wrapped in a scroll view so pull-to-refresh stays available when empty.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 48, bottom: AppSpacing.bottomNavSafe),
      children: [
        AppEmptyState(
          icon: searching ? Symbols.search : Symbols.receipt_long,
          title: searching
              ? tr('inv.no_results', ref)
              : tr('dash.no_invoices', ref),
          message: searching
              ? tr('inv.try_diff_search', ref)
              : tr('inv.tap_plus_create', ref),
          actionLabel: searching ? null : tr('dash.new_invoice', ref),
          onAction: searching ? null : onCreate,
        ),
      ],
    );
  }
}
