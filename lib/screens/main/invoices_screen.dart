// lib/screens/main/invoices_screen.dart
//
// The invoice ledger.
//
// The list itself is the feature, so the chrome above it stays thin: a
// title, a search well, a filter rail, and a running total for whatever
// the current filter selects. That last part matters — filtering to
// "Overdue" and immediately seeing what that is worth is the question
// the owner is actually asking.
//
// Behaviour carried over unchanged: search, status filters,
// pull-to-refresh, swipe-to-delete with confirmation, and the
// first-frame skeleton.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:billzap/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../design/components.dart';
import '../../design/money.dart';
import '../../design/motion.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../i18n/translations.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/platform.dart';
import '../../widgets/skeleton.dart';
import 'dashboard_screen.dart' show statusOf;

enum _Filter { all, paid, sent, pending, overdue, draft }

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});
  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesState();
}

class _InvoicesState extends ConsumerState<InvoicesScreen> {
  _Filter _filter = _Filter.all;
  final _searchCtrl = TextEditingController();
  String _search = '';
  bool _firstFrame = true;

  @override
  void initState() {
    super.initState();
    // A brief skeleton so the list never flashes as empty before Hive
    // hands back the rows.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _firstFrame = false);
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matchesFilter(Invoice i) {
    switch (_filter) {
      case _Filter.all:
        return true;
      case _Filter.paid:
        return i.status == InvoiceStatus.paid;
      case _Filter.sent:
        return i.status == InvoiceStatus.sent && !i.isOverdue;
      case _Filter.pending:
        return i.status == InvoiceStatus.pending && !i.isOverdue;
      case _Filter.overdue:
        return i.isOverdue;
      case _Filter.draft:
        return i.status == InvoiceStatus.draft;
    }
  }

  List<Invoice> _visible(List<Invoice> all) {
    final q = _search.trim().toLowerCase();
    return all.where((i) {
      if (!_matchesFilter(i)) return false;
      if (q.isEmpty) return true;
      return i.customerName.toLowerCase().contains(q) ||
          i.invoiceNumber.toLowerCase().contains(q);
    }).toList();
  }

  String _filterLabel(_Filter f) {
    switch (f) {
      case _Filter.all:
        return tr('inv.all', ref);
      case _Filter.paid:
        return tr('inv.paid', ref);
      case _Filter.sent:
        return tr('inv.sent', ref);
      case _Filter.pending:
        return tr('inv.pending', ref);
      case _Filter.overdue:
        return tr('inv.overdue', ref);
      case _Filter.draft:
        return tr('inv.draft', ref);
    }
  }

  Future<void> _refresh() async {
    HapticFeedback.lightImpact();
    ref.read(invoiceProvider.notifier).reload();
    await Future<void>.delayed(const Duration(milliseconds: 260));
  }

  Future<bool> _confirmDelete(Invoice inv) async {
    return confirm(context,
        title: 'Delete this invoice?',
        message: '${inv.invoiceNumber} will be removed for good. '
            'This cannot be undone.',
        icon: Symbols.delete,
        destructive: true,
        confirmLabel: tr('common.delete', ref),
        cancelLabel: tr('common.cancel', ref));
  }

  Future<void> _delete(Invoice inv) async {
    await ref.read(invoiceProvider.notifier).delete(inv.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${inv.invoiceNumber} deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(invoiceProvider);
    final list = _visible(all);
    final total = list.fold<double>(0, (s, i) => s + i.grandTotal);
    final filtering = _filter != _Filter.all || _search.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColor.canvas,
      body: DesktopMaxWidth(
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            ScreenTitle(
              tr('inv.title', ref),
              eyebrow: '${all.length} total',
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.gutter, AppSpace.lg, AppSpace.gutter, AppSpace.lg),
              // No "+" here: the dock's create button now rides on every
              // tab, and two jade plus-buttons 60pt apart on the same
              // screen just makes a person wonder which one is different.
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
              child: AppSearchField(
                controller: _searchCtrl,
                hint: tr('inv.search', ref),
                hasValue: _search.isNotEmpty,
                onChanged: (v) => setState(() => _search = v),
                onClear: () {
                  _searchCtrl.clear();
                  setState(() => _search = '');
                },
              ),
            ),
            const SizedBox(height: AppSpace.md),

            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
                itemCount: _Filter.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpace.sm),
                itemBuilder: (_, i) {
                  final f = _Filter.values[i];
                  return AppChip(
                    _filterLabel(f),
                    selected: _filter == f,
                    count: f == _Filter.all
                        ? null
                        : all.where((inv) {
                            final saved = _filter;
                            _filter = f;
                            final m = _matchesFilter(inv);
                            _filter = saved;
                            return m;
                          }).length,
                    onTap: () => setState(() => _filter = f),
                  );
                },
              ),
            ),

            // What the current filter is worth. The reason anyone filters
            // an invoice list is to find out this number.
            if (filtering)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpace.gutter, AppSpace.md, AppSpace.gutter, 0),
                child: AppWell(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.lg, vertical: AppSpace.md),
                  child: Row(children: [
                    Text(
                      '${list.length} ${list.length == 1 ? "bill" : "bills"}',
                      style: AppFont.style(AppType.labelM,
                          color: AppColor.textSecondary),
                    ),
                    const Spacer(),
                    Money(total,
                        style: AppType.amountS, animate: true, round: true),
                  ]),
                ),
              ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: AppColor.primary,
                backgroundColor: AppColor.surface,
                child: _firstFrame
                    ? const SkeletonList()
                    : list.isEmpty
                        ? _Empty(
                            searching: _search.isNotEmpty,
                            onCreate: () => context.push('/create'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                                AppSpace.gutter,
                                AppSpace.md,
                                AppSpace.gutter,
                                AppSpace.navClearance),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: list.length,
                            itemBuilder: (_, i) => Entrance(
                              index: i,
                              child: _InvoiceRow(
                                invoice: list[i],
                                onTap: () {
                                  ref
                                      .read(selectedInvoiceProvider.notifier)
                                      .select(list[i]);
                                  context.push('/preview');
                                },
                                confirmDismiss: _confirmDelete,
                                onDelete: () => _delete(list[i]),
                              ),
                            ),
                          ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _InvoiceRow extends ConsumerWidget {
  final Invoice invoice;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Future<bool> Function(Invoice) confirmDismiss;

  const _InvoiceRow({
    required this.invoice,
    required this.onTap,
    required this.onDelete,
    required this.confirmDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (label, tone) = statusOf(invoice, ref);
    final due = invoice.isOverdue
        ? 'Due ${DateFormat('d MMM').format(invoice.dueDate)}'
        : DateFormat('d MMM yyyy').format(invoice.invoiceDate);

    return Dismissible(
      key: ValueKey('inv-${invoice.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => confirmDismiss(invoice),
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: AppSpace.sm),
        decoration: BoxDecoration(
          color: AppColor.overdue,
          borderRadius: AppRadius.all(AppRadius.lg),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Symbols.delete, color: Colors.white, size: 19),
          const SizedBox(width: AppSpace.sm),
          Text('Delete',
              style: AppFont.style(AppType.labelM, color: Colors.white)),
        ]),
      ),
      child: AppListRow(
        onTap: onTap,
        leading: AppAvatar(label: invoice.customerName, tone: tone),
        title: invoice.customerName,
        subtitle: '${invoice.invoiceNumber} · $due',
        amount: invoice.grandTotal,
        badge: StatusPill(label, tone: tone),
      ),
    );
  }
}

class _Empty extends ConsumerWidget {
  final bool searching;
  final VoidCallback onCreate;
  const _Empty({required this.searching, required this.onCreate});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
            top: AppSpace.xxxl, bottom: AppSpace.navClearance),
        children: [
          AppEmptyState(
            icon: searching ? Symbols.search : Symbols.receipt_long,
            tone: searching ? AppColor.textTertiary : AppColor.primary,
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
