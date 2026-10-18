// lib/screens/personal/my_money_screen.dart — My Money.
//
// A person's own spending, for anyone: a student, a bachelor on a first
// salary, a household keeping the month in check. No shop needed.
//
// What it is built around is one question people actually ask —
// "how much can I still spend today?" — answered on the first card,
// worked out from the monthly budget and the days left. Everything
// else (where the money went, the last seven days, the pace for the
// month, the days with no spending at all) supports that answer.
//
// The arithmetic lives in lib/personal/spending.dart and is tested
// there; this file only draws it.

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:billzap/theme/app_icons.dart';

import '../../design/components.dart';
import '../../design/money.dart';
import '../../design/motion.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../i18n/dates.dart';
import '../../i18n/translations.dart';
import '../../models/models.dart' show genId;
import '../../personal/spending.dart';
import '../../personal/spending_store.dart';
import '../../tax/active_profile.dart';
import '../../utils/smart_amount.dart';

IconData spendIcon(String category) => switch (category) {
      'food' => Symbols.utensils,
      'groceries' => Symbols.shopping_basket,
      'transport' => Symbols.car,
      'rent' => Symbols.home,
      'bills' => Symbols.zap,
      'shopping' => Symbols.shopping_bag,
      'health' => Symbols.heart_pulse,
      'fun' => Symbols.film,
      'education' => Symbols.book_open,
      'family' => Symbols.users,
      'travel' => Symbols.plane,
      'care' => Symbols.sparkles,
      'subscriptions' => Symbols.repeat,
      'gifts' => Symbols.gift,
      _ => Symbols.receipt,
    };

/// Each category keeps one colour everywhere it appears, so the
/// breakdown bars, the history icons and the add sheet agree.
Color spendTone(String category) {
  const tones = {
    'food': Color(0xFFE9AE3D),
    'groceries': Color(0xFF2FC08A),
    'transport': Color(0xFF4C8DF6),
    'rent': Color(0xFF9285F0),
    'bills': Color(0xFFEE7070),
    'shopping': Color(0xFFE76FB0),
    'health': Color(0xFFEF5D5D),
    'fun': Color(0xFFB06FE7),
    'education': Color(0xFF3DB5C9),
    'family': Color(0xFFD98B3D),
    'travel': Color(0xFF3D9BE9),
    'care': Color(0xFFE79A6F),
    'subscriptions': Color(0xFF7363E8),
    'gifts': Color(0xFFE0507A),
  };
  return tones[category] ?? const Color(0xFF93A0AE);
}

String spendLabel(String category) => trGlobal('mm.cat_$category');

String _money(double v) => formatActiveMoney(v, decimals: v == v.roundToDouble() ? 0 : 2);

class MyMoneyScreen extends ConsumerWidget {
  const MyMoneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(spendingProvider);
    final now = DateTime.now();
    final sum = summarize(data.spends, data.budget, now);

    return Scaffold(
      backgroundColor: AppColor.canvas,
      appBar: AppBar(
        backgroundColor: AppColor.canvas,
        leadingWidth: 62,
        leading: Center(
          child: AppIconButton(
            icon: Symbols.arrow_back,
            size: 40,
            onTap: () =>
                context.canPop() ? context.pop() : context.go('/home'),
          ),
        ),
        title: Text(trGlobal('mm.title'),
            style: AppFont.style(AppType.titleM, color: AppColor.textPrimary)),
        actions: [
          AppIconButton(
            icon: Symbols.repeat,
            size: 40,
            tooltip: trGlobal('mm.recurring'),
            onTap: () => _showRecurring(context, ref),
          ),
          const Gap(AppSpace.sm),
          AppIconButton(
            icon: Symbols.share,
            size: 40,
            tooltip: trGlobal('mm.export'),
            onTap: () => _export(context, data.spends),
          ),
          const Gap(AppSpace.gutter),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter, AppSpace.sm, AppSpace.gutter, 120),
        children: [
          _BudgetHero(sum: sum, onBudget: () => _editBudget(context, ref, data.budget)),
          if (sum.state == BudgetState.over) ...[
            const Gap(AppSpace.md),
            _Banner(
              icon: Symbols.warning,
              tone: AppColor.overdue,
              title: trGlobal('mm.over_title'),
              text: trGlobal('mm.over_msg', {'amount': _money(-sum.remaining)}),
            ),
          ] else if (sum.state == BudgetState.warning) ...[
            const Gap(AppSpace.md),
            _Banner(
              icon: Symbols.lightbulb,
              tone: AppColor.pending,
              title: trGlobal('mm.warn_title',
                  {'pct': (sum.used * 100).floor()}),
              text: trGlobal('mm.warn_msg', {'amount': _money(sum.remaining)}),
            ),
          ],
          const Gap(AppSpace.md),
          _StatsGrid(sum: sum),
          const Gap(AppSpace.xl),
          SectionHeader(trGlobal('mm.last7')),
          _WeekBars(sum: sum, now: now),
          if (sum.byCategory.isNotEmpty) ...[
            const Gap(AppSpace.xl),
            SectionHeader(trGlobal('mm.where')),
            _Categories(sum: sum),
          ],
          const Gap(AppSpace.xl),
          SectionHeader(trGlobal('mm.history')),
          if (data.spends.isEmpty)
            AppEmptyState(
              icon: Symbols.piggy_bank,
              title: trGlobal('mm.empty_title'),
              message: trGlobal('mm.empty_msg'),
            )
          else
            _History(spends: data.spends, now: now),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
        child: AppButton(
          label: trGlobal('mm.add'),
          icon: Symbols.add,
          onPressed: () => showSpendSheet(context, ref),
        ),
      ),
    );
  }
}

/// The home screen's door into My Money: this month so far, and what
/// is safe to spend today. Shown to everyone, shop or no shop.
class MyMoneyDashCard extends ConsumerWidget {
  final VoidCallback onTap;
  const MyMoneyDashCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(spendingProvider);
    final sum = summarize(data.spends, data.budget, DateTime.now());
    final tone = switch (sum.state) {
      BudgetState.over => AppColor.overdue,
      BudgetState.warning => AppColor.pending,
      _ => AppColor.primary,
    };
    final String line;
    if (data.spends.isEmpty) {
      line = trGlobal('mm.dash_empty');
    } else if (sum.state == BudgetState.over) {
      line = trGlobal('mm.over_by', {'amount': _money(-sum.remaining)});
    } else if (sum.budget > 0) {
      line = trGlobal('mm.dash_safe', {'amount': _money(sum.safeToday)});
    } else {
      line = trGlobal('mm.dash_spent', {'amount': _money(sum.monthSpent)});
    }
    return AppSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.md),
      child: Row(children: [
        SizedBox(
          width: 48,
          height: 48,
          child: CustomPaint(
            painter: _RingPainter(
              value: sum.budget > 0 ? sum.used : 0,
              tone: tone,
              track: AppColor.sunken,
              stroke: 5,
            ),
            child: Center(
              child: Icon(Symbols.account_balance_wallet,
                  size: 20, color: tone),
            ),
          ),
        ),
        const Gap(AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(trGlobal('mm.title'),
                  style: AppFont.style(AppType.labelL,
                      color: AppColor.textPrimary)),
              const Gap(2),
              Text(line,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFont.style(AppType.bodyS,
                      color: sum.state == BudgetState.over
                          ? AppColor.overdue
                          : AppColor.textTertiary)),
            ],
          ),
        ),
        Icon(Symbols.chevron_right, size: 20, color: AppColor.textTertiary),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// The hero: spent / budget, with the ring and today's allowance
// ═════════════════════════════════════════════════════════════════════

class _BudgetHero extends StatelessWidget {
  final SpendingSummary sum;
  final VoidCallback onBudget;
  const _BudgetHero({required this.sum, required this.onBudget});

  @override
  Widget build(BuildContext context) {
    final tone = switch (sum.state) {
      BudgetState.over => AppColor.overdue,
      BudgetState.warning => AppColor.pending,
      _ => AppColor.primary,
    };
    final hasBudget = sum.budget > 0;
    return AppSurface(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(
            width: 92,
            height: 92,
            child: CustomPaint(
              painter: _RingPainter(
                value: hasBudget ? sum.used : 0,
                tone: tone,
                track: AppColor.sunken,
              ),
              child: Center(
                child: hasBudget
                    ? Text('${(sum.used * 100).round()}%',
                        style: AppFont.style(AppType.titleS, color: tone))
                    : Icon(Symbols.piggy_bank,
                        size: 28, color: AppColor.textTertiary),
              ),
            ),
          ),
          const Gap(AppSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trGlobal('mm.spent_month').toUpperCase(),
                    style: AppFont.style(AppType.overline,
                        color: AppColor.textTertiary)),
                const Gap(4),
                MoneyCounter(sum.monthSpent,
                    style: AppType.amountL,
                    color: AppColor.textPrimary,
                    round: false),
                const Gap(4),
                if (hasBudget)
                  Text(
                      sum.state == BudgetState.over
                          ? trGlobal('mm.over_by',
                              {'amount': _money(-sum.remaining)})
                          : trGlobal('mm.left_of', {
                              'left': _money(sum.remaining),
                              'budget': _money(sum.budget),
                            }),
                      style: AppFont.style(AppType.bodyS, color: tone))
                else
                  Text(trGlobal('mm.no_budget'),
                      style: AppFont.style(AppType.bodyS,
                          color: AppColor.textTertiary)),
              ],
            ),
          ),
        ]),
        const Gap(AppSpace.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: AppColor.wash(hasBudget ? tone : AppColor.primary),
            borderRadius: AppRadius.all(AppRadius.md),
          ),
          child: hasBudget
              ? Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(trGlobal('mm.safe_today'),
                            style: AppFont.style(AppType.labelM,
                                color: AppColor.textSecondary)),
                        const Gap(2),
                        Text(_money(sum.safeToday),
                            style: AppFont.style(AppType.amountM, color: tone)),
                        const Gap(2),
                        Text(
                            trGlobal('mm.allowance', {
                              'amount': _money(sum.dailyAllowance),
                              'n': sum.daysLeft,
                            }),
                            style: AppFont.style(AppType.bodyS,
                                color: AppColor.textTertiary)),
                      ],
                    ),
                  ),
                  AppButton.ghost(
                    label: trGlobal('mm.edit_budget'),
                    icon: Symbols.target,
                    onPressed: onBudget,
                  ),
                ])
              : Row(children: [
                  Icon(Symbols.target, color: AppColor.primary, size: 22),
                  const Gap(AppSpace.md),
                  Expanded(
                    child: Text(trGlobal('mm.budget_pitch'),
                        style: AppFont.style(AppType.bodyS,
                            color: AppColor.textSecondary)),
                  ),
                  const Gap(AppSpace.sm),
                  AppButton(
                    label: trGlobal('mm.set_budget'),
                    expand: false,
                    compact: true,
                    onPressed: onBudget,
                  ),
                ]),
        ),
      ]),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color tone, track;
  final double stroke;
  _RingPainter(
      {required this.value,
      required this.tone,
      required this.track,
      this.stroke = 10});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    final base = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(r, 0, math.pi * 2, false, base);
    final sweep = (value.clamp(0.0, 1.0)) * math.pi * 2;
    if (sweep > 0) {
      final arc = Paint()
        ..color = tone
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke;
      canvas.drawArc(r, -math.pi / 2, sweep, false, arc);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.tone != tone || old.track != track;
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color tone;
  final String title, text;
  const _Banner(
      {required this.icon,
      required this.tone,
      required this.title,
      required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          color: AppColor.wash(tone),
          borderRadius: AppRadius.all(AppRadius.md),
          border: Border.all(color: tone.withValues(alpha: 0.35)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: tone, size: 20),
          const Gap(AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppFont.style(AppType.labelL, color: tone)),
                const Gap(2),
                Text(text,
                    style: AppFont.style(AppType.bodyS,
                        color: AppColor.textSecondary)),
              ],
            ),
          ),
        ]),
      );
}

// ═════════════════════════════════════════════════════════════════════
// Stats
// ═════════════════════════════════════════════════════════════════════

class _StatsGrid extends StatelessWidget {
  final SpendingSummary sum;
  const _StatsGrid({required this.sum});

  @override
  Widget build(BuildContext context) {
    final vs = sum.vsLastMonth;
    final tiles = <Widget>[
      _Stat(label: trGlobal('mm.today'), value: _money(sum.todaySpent),
          icon: Symbols.coffee),
      _Stat(label: trGlobal('mm.week'), value: _money(sum.weekSpent),
          icon: Symbols.calendar_today),
      _Stat(label: trGlobal('mm.daily_avg'), value: _money(sum.dailyAverage),
          icon: Symbols.bar_chart),
      _Stat(
        label: trGlobal('mm.pace'),
        value: _money(sum.projected),
        icon: Symbols.trending_up,
        tone: sum.budget > 0 && sum.projected > sum.budget
            ? AppColor.overdue
            : null,
        foot: sum.budget > 0
            ? (sum.projected > sum.budget
                ? trGlobal('mm.pace_over',
                    {'amount': _money(sum.projected - sum.budget)})
                : trGlobal('mm.pace_ok'))
            : null,
      ),
      _Stat(
        label: trGlobal('mm.vs_last'),
        value: vs == null
            ? '—'
            : '${vs > 0 ? '+' : ''}${(vs * 100).round()}%',
        icon: vs != null && vs <= 0 ? Symbols.trending_down : Symbols.trending_up,
        tone: vs == null
            ? null
            : (vs <= 0 ? AppColor.primary : AppColor.overdue),
        foot: vs == null ? trGlobal('mm.vs_none') : _money(sum.lastMonthSpent),
      ),
      _Stat(
        label: trGlobal('mm.no_spend'),
        value: '${sum.noSpendDays}',
        icon: Symbols.flame,
        tone: sum.noSpendDays > 0 ? AppColor.pending : null,
        foot: trGlobal('mm.no_spend_foot'),
      ),
    ];
    return LayoutBuilder(builder: (context, c) {
      final w = (c.maxWidth - AppSpace.sm) / 2;
      return Wrap(
        spacing: AppSpace.sm,
        runSpacing: AppSpace.sm,
        children: [for (final t in tiles) SizedBox(width: w, child: t)],
      );
    });
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final String? foot;
  final IconData icon;
  final Color? tone;
  const _Stat(
      {required this.label,
      required this.value,
      required this.icon,
      this.tone,
      this.foot});

  @override
  Widget build(BuildContext context) => AppSurface(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 15, color: tone ?? AppColor.textTertiary),
            const Gap(6),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFont.style(AppType.labelS,
                      color: AppColor.textTertiary)),
            ),
          ]),
          const Gap(6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(value,
                maxLines: 1,
                style: AppFont.style(AppType.amountS,
                    color: tone ?? AppColor.textPrimary)),
          ),
          if (foot != null) ...[
            const Gap(2),
            Text(foot!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppFont.style(AppType.bodyS,
                    color: AppColor.textQuiet)),
          ],
        ]),
      );
}

// ═════════════════════════════════════════════════════════════════════
// Last seven days
// ═════════════════════════════════════════════════════════════════════

class _WeekBars extends StatelessWidget {
  final SpendingSummary sum;
  final DateTime now;
  const _WeekBars({required this.sum, required this.now});

  @override
  Widget build(BuildContext context) {
    final allowance = sum.dailyAllowance;
    final top = [...sum.last7, allowance].reduce(math.max);
    const barMax = 110.0;
    return AppSurface(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.md, AppSpace.lg, AppSpace.md, AppSpace.md),
      child: Column(children: [
        SizedBox(
          height: barMax + 22,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (sum.last7[i] > 0)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                              formatMoneyShort(sum.last7[i]),
                              style: AppFont.style(AppType.labelS,
                                  color: AppColor.textTertiary)),
                        ),
                      const Gap(4),
                      AnimatedContainer(
                        duration: AppMotion.slow,
                        curve: AppMotion.standard,
                        width: 18,
                        height: top <= 0
                            ? 3
                            : math.max(3.0, barMax * sum.last7[i] / top),
                        decoration: BoxDecoration(
                          color: i == 6
                              ? AppColor.primary
                              : (allowance > 0 && sum.last7[i] > allowance
                                  ? AppColor.overdue.withValues(alpha: 0.75)
                                  : AppColor.primary.withValues(alpha: 0.35)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const Gap(6),
        Row(children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Center(
                child: Text(
                    uiDate('E', now.subtract(Duration(days: 6 - i))),
                    maxLines: 1,
                    style: AppFont.style(AppType.labelS,
                        color: i == 6
                            ? AppColor.textPrimary
                            : AppColor.textTertiary)),
              ),
            ),
        ]),
        if (allowance > 0) ...[
          const Gap(AppSpace.sm),
          Text(trGlobal('mm.bars_note', {'amount': _money(allowance)}),
              textAlign: TextAlign.center,
              style: AppFont.style(AppType.bodyS, color: AppColor.textQuiet)),
        ],
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Where it went
// ═════════════════════════════════════════════════════════════════════

class _Categories extends StatelessWidget {
  final SpendingSummary sum;
  const _Categories({required this.sum});

  @override
  Widget build(BuildContext context) {
    final total = sum.monthSpent <= 0 ? 1 : sum.monthSpent;
    return AppSurface(
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(children: [
        for (final e in sum.byCategory)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              AppAvatar(icon: spendIcon(e.key), tone: spendTone(e.key), size: 36),
              const Gap(AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(spendLabel(e.key),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFont.style(AppType.labelM,
                                color: AppColor.textPrimary)),
                      ),
                      Text(_money(e.value),
                          style: AppFont.style(AppType.labelM,
                              color: AppColor.textPrimary)),
                    ]),
                    const Gap(5),
                    Row(children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: e.value / total,
                            minHeight: 6,
                            backgroundColor: AppColor.sunken,
                            valueColor:
                                AlwaysStoppedAnimation(spendTone(e.key)),
                          ),
                        ),
                      ),
                      const Gap(AppSpace.sm),
                      SizedBox(
                        width: 38,
                        child: Text('${(e.value / total * 100).round()}%',
                            textAlign: TextAlign.end,
                            style: AppFont.style(AppType.labelS,
                                color: AppColor.textTertiary)),
                      ),
                    ]),
                  ],
                ),
              ),
            ]),
          ),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// History
// ═════════════════════════════════════════════════════════════════════

class _History extends ConsumerWidget {
  final List<Spend> spends;
  final DateTime now;
  const _History({required this.spends, required this.now});

  String _dayLabel(DateTime d) {
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return trGlobal('dc.today');
    if (diff == 1) return trGlobal('dc.yesterday');
    return uiDate('EEE, d MMM', d);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The last 60 entries: enough to scroll back a couple of months,
    // without building a thousand rows for someone who logs everything.
    final shown = spends.take(60).toList();
    final children = <Widget>[];
    String? lastDay;
    for (final s in shown) {
      final label = _dayLabel(s.date);
      if (label != lastDay) {
        lastDay = label;
        final dayTotal = spends
            .where((x) =>
                x.date.year == s.date.year &&
                x.date.month == s.date.month &&
                x.date.day == s.date.day)
            .fold<double>(0, (a, x) => a + x.amount);
        children.add(Padding(
          padding: const EdgeInsets.only(top: AppSpace.md, bottom: AppSpace.sm),
          child: Row(children: [
            Expanded(
              child: Text(label.toUpperCase(),
                  style: AppFont.style(AppType.overline,
                      color: AppColor.textTertiary)),
            ),
            Text(_money(dayTotal),
                style: AppFont.style(AppType.labelS,
                    color: AppColor.textTertiary)),
          ]),
        ));
      }
      children.add(Dismissible(
        key: ValueKey('spend-${s.id}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) {
          ref.read(spendingProvider.notifier).remove(s.id);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(trGlobal('mm.deleted')),
            action: SnackBarAction(
              label: trGlobal('mm.undo'),
              onPressed: () => ref.read(spendingProvider.notifier).put(s),
            ),
          ));
        },
        background: Container(
          margin: const EdgeInsets.only(bottom: AppSpace.sm),
          decoration: BoxDecoration(
            color: AppColor.overdue,
            borderRadius: AppRadius.all(AppRadius.lg),
          ),
          alignment: AlignmentDirectional.centerEnd,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
          child: Icon(Symbols.delete, color: AppColor.onPrimary, size: 19),
        ),
        child: AppListRow(
          margin: const EdgeInsets.only(bottom: AppSpace.sm),
          onTap: () => showSpendSheet(context, ref, existing: s),
          leading: AppAvatar(
              icon: spendIcon(s.category), tone: spendTone(s.category), size: 40),
          title: s.note.isNotEmpty ? s.note : spendLabel(s.category),
          subtitle: [
            if (s.note.isNotEmpty) spendLabel(s.category),
            trGlobal('mm.method_${s.method}'),
            if (s.recurringId != null) trGlobal('mm.repeats'),
          ].join(' · '),
          trailing: Text(_money(s.amount),
              style: AppFont.style(AppType.amountS,
                  color: AppColor.textPrimary)),
        ),
      ));
    }
    return Column(children: children);
  }
}

// ═════════════════════════════════════════════════════════════════════
// Add / edit
// ═════════════════════════════════════════════════════════════════════

Future<void> showSpendSheet(BuildContext context, WidgetRef ref,
    {Spend? existing}) {
  HapticFeedback.lightImpact();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SpendSheet(existing: existing),
  );
}

class _SpendSheet extends ConsumerStatefulWidget {
  final Spend? existing;
  const _SpendSheet({this.existing});

  @override
  ConsumerState<_SpendSheet> createState() => _SpendSheetState();
}

class _SpendSheetState extends ConsumerState<_SpendSheet> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late String _category;
  late String _method;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _amount = TextEditingController(
        text: e == null
            ? ''
            : (e.amount == e.amount.roundToDouble()
                ? e.amount.toStringAsFixed(0)
                : e.amount.toString()));
    _note = TextEditingController(text: e?.note ?? '');
    _category = e?.category ?? 'food';
    _method = e?.method ?? 'cash';
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(trGlobal('mm.need_amount')),
          backgroundColor: AppColor.overdue));
      return;
    }
    if (_saving) return;
    _saving = true;
    final notifier = ref.read(spendingProvider.notifier);
    final before = ref.read(spendingProvider);
    final now = DateTime.now();
    final sumBefore = summarize(
        before.spends.where((s) => s.id != widget.existing?.id).toList(),
        before.budget,
        now);
    final counts = _date.year == now.year && _date.month == now.month;
    final spend = Spend(
      id: widget.existing?.id ?? genId(),
      amount: amount,
      category: _category,
      note: _note.text.trim(),
      date: _sameDay(_date, now) ? now : DateTime(_date.year, _date.month, _date.day, 12),
      method: _method,
      recurringId: widget.existing?.recurringId,
    );
    notifier.put(spend);
    HapticFeedback.mediumImpact();
    final line = counts ? crossing(sumBefore.monthSpent, amount, before.budget) : null;
    final messenger = ScaffoldMessenger.of(context);
    if (mounted) Navigator.of(context).pop();
    if (line == 'over') {
      messenger.showSnackBar(SnackBar(
        content: Text(trGlobal('mm.over_msg', {
          'amount': _money(sumBefore.monthSpent + amount - before.budget),
        })),
        backgroundColor: AppColor.overdue,
        duration: const Duration(seconds: 5),
      ));
    } else if (line == 'warning') {
      messenger.showSnackBar(SnackBar(
        content: Text(trGlobal('mm.warn_snack')),
        backgroundColor: AppColor.pending,
      ));
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final methods = [
      for (final m in spendMethods)
        // UPI is offered where it exists.
        if (m != 'upi' || activeProfile.countryCode == 'IN') m,
    ];
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColor.hairline,
                        borderRadius: BorderRadius.circular(99))),
              ),
              const Gap(14),
              Text(
                  widget.existing == null
                      ? trGlobal('mm.add')
                      : trGlobal('mm.edit'),
                  style: AppFont.style(AppType.titleM,
                      color: AppColor.textPrimary)),
              const Gap(AppSpace.md),
              // The amount, big: it is the one thing every entry needs.
              TextField(
                controller: _amount,
                autofocus: widget.existing == null,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [SmartAmountFormatter()],
                style: AppFont.style(AppType.amountHero,
                    color: AppColor.textPrimary),
                decoration: InputDecoration(
                  prefixText: '$activeCurrencySymbol ',
                  prefixStyle: AppFont.style(AppType.amountM,
                      color: AppColor.textTertiary),
                  hintText: '0',
                  border: InputBorder.none,
                  isDense: true,
                ),
                onSubmitted: (_) => _save(),
              ),
              const Gap(AppSpace.md),
              Text(trGlobal('mm.category').toUpperCase(),
                  style: AppFont.style(AppType.overline,
                      color: AppColor.textTertiary)),
              const Gap(AppSpace.sm),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final c in SpendCategory.all)
                  _CatChip(
                    id: c.id,
                    selected: c.id == _category,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _category = c.id);
                    },
                  ),
              ]),
              const Gap(AppSpace.lg),
              AppField(
                label: trGlobal('mm.note'),
                controller: _note,
                icon: Symbols.edit,
                hint: trGlobal('mm.note_hint'),
                validatable: false,
              ),
              const Gap(AppSpace.sm),
              Text(trGlobal('mm.when').toUpperCase(),
                  style: AppFont.style(AppType.overline,
                      color: AppColor.textTertiary)),
              const Gap(AppSpace.sm),
              Wrap(spacing: 8, runSpacing: 8, children: [
                AppChip(trGlobal('dc.today'),
                    selected: _sameDay(_date, now),
                    onTap: () => setState(() => _date = now)),
                AppChip(trGlobal('dc.yesterday'),
                    selected: _sameDay(_date, yesterday),
                    onTap: () => setState(() => _date = yesterday)),
                AppChip(
                    !_sameDay(_date, now) && !_sameDay(_date, yesterday)
                        ? uiDate('d MMM', _date)
                        : trGlobal('dc.pick'),
                    icon: Symbols.calendar_today,
                    selected:
                        !_sameDay(_date, now) && !_sameDay(_date, yesterday),
                    onTap: _pickDate),
              ]),
              const Gap(AppSpace.lg),
              Text(trGlobal('mm.paid_with').toUpperCase(),
                  style: AppFont.style(AppType.overline,
                      color: AppColor.textTertiary)),
              const Gap(AppSpace.sm),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final m in methods)
                  AppChip(trGlobal('mm.method_$m'),
                      selected: m == _method,
                      onTap: () => setState(() => _method = m)),
              ]),
              const Gap(AppSpace.xl),
              AppButton(
                label: trGlobal('common.save'),
                icon: Symbols.check,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String id;
  final bool selected;
  final VoidCallback onTap;
  const _CatChip({required this.id, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tone = spendTone(id);
    return PressScale(
      onTap: onTap,
      scale: 0.95,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? tone.withValues(alpha: 0.18) : AppColor.sunken,
          borderRadius: AppRadius.all(AppRadius.pill),
          border: Border.all(
              color: selected ? tone : AppColor.hairline,
              width: selected ? 1.5 : 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(spendIcon(id), size: 15, color: tone),
          const Gap(6),
          Text(spendLabel(id),
              style: AppFont.style(AppType.labelM,
                  color: selected
                      ? AppColor.textPrimary
                      : AppColor.textSecondary)),
        ]),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Budget
// ═════════════════════════════════════════════════════════════════════

Future<void> _editBudget(BuildContext context, WidgetRef ref, double current) {
  final ctrl = TextEditingController(
      text: current > 0 ? current.toStringAsFixed(0) : '');
  return showAppDialog<void>(
    context: context,
    builder: (ctx) => AppDialog(
      title: trGlobal('mm.budget_title'),
      message: trGlobal('mm.budget_msg'),
      icon: Symbols.target,
      confirmLabel: trGlobal('common.save'),
      cancelLabel: current > 0 ? trGlobal('mm.budget_remove') : trGlobal('common.cancel'),
      onConfirm: () {
        final v = double.tryParse(ctrl.text) ?? 0;
        ref.read(spendingProvider.notifier).setBudget(v);
        Navigator.of(ctx).pop();
      },
      onCancel: () {
        if (current > 0) ref.read(spendingProvider.notifier).setBudget(0);
        Navigator.of(ctx).pop();
      },
      body: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [SmartAmountFormatter()],
        style: AppFont.style(AppType.amountL, color: AppColor.textPrimary),
        decoration: InputDecoration(
          prefixText: '$activeCurrencySymbol ',
          hintText: '0',
          filled: true,
          fillColor: AppColor.sunken,
          border: OutlineInputBorder(
            borderRadius: AppRadius.all(AppRadius.md),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════
// Repeating expenses
// ═════════════════════════════════════════════════════════════════════

Future<void> _showRecurring(BuildContext context, WidgetRef ref) {
  HapticFeedback.lightImpact();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _RecurringSheet(),
  );
}

class _RecurringSheet extends ConsumerStatefulWidget {
  const _RecurringSheet();
  @override
  ConsumerState<_RecurringSheet> createState() => _RecurringSheetState();
}

class _RecurringSheetState extends ConsumerState<_RecurringSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _category = 'rent';
  int _day = 1;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _add() {
    final v = double.tryParse(_amount.text);
    if (v == null || v <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(trGlobal('mm.need_amount')),
          backgroundColor: AppColor.overdue));
      return;
    }
    ref.read(spendingProvider.notifier).addRecurring(RecurringSpend(
          id: genId(),
          amount: v,
          category: _category,
          note: _note.text.trim(),
          dayOfMonth: _day,
        ));
    HapticFeedback.mediumImpact();
    setState(() {
      _amount.clear();
      _note.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(spendingProvider).recurring;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColor.hairline,
                        borderRadius: BorderRadius.circular(99))),
              ),
              const Gap(14),
              Text(trGlobal('mm.recurring'),
                  style: AppFont.style(AppType.titleM,
                      color: AppColor.textPrimary)),
              const Gap(4),
              Text(trGlobal('mm.recurring_sub'),
                  style: AppFont.style(AppType.bodyS,
                      color: AppColor.textTertiary)),
              const Gap(AppSpace.md),
              for (final r in list)
                AppListRow(
                  margin: const EdgeInsets.only(bottom: AppSpace.sm),
                  leading: AppAvatar(
                      icon: spendIcon(r.category),
                      tone: spendTone(r.category),
                      size: 40),
                  title: r.note.isNotEmpty ? r.note : spendLabel(r.category),
                  subtitle: trGlobal('mm.every_month', {'day': r.dayOfMonth}),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(_money(r.amount),
                        style: AppFont.style(AppType.labelM,
                            color: AppColor.textPrimary)),
                    IconButton(
                      icon: Icon(Symbols.delete,
                          size: 18, color: AppColor.overdue),
                      onPressed: () => ref
                          .read(spendingProvider.notifier)
                          .removeRecurring(r.id),
                    ),
                  ]),
                ),
              if (list.isNotEmpty) const Gap(AppSpace.md),
              Text(trGlobal('mm.recurring_new').toUpperCase(),
                  style: AppFont.style(AppType.overline,
                      color: AppColor.textTertiary)),
              const Gap(AppSpace.sm),
              AppField(
                label: trGlobal('inv.amount'),
                controller: _amount,
                icon: Symbols.banknote,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [SmartAmountFormatter()],
                validatable: false,
              ),
              AppField(
                label: trGlobal('mm.note'),
                controller: _note,
                icon: Symbols.edit,
                hint: trGlobal('mm.recurring_hint'),
                validatable: false,
              ),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final c in const ['rent', 'bills', 'subscriptions',
                    'education', 'health', 'family', 'transport', 'other'])
                  _CatChip(
                      id: c,
                      selected: c == _category,
                      onTap: () => setState(() => _category = c)),
              ]),
              const Gap(AppSpace.md),
              Row(children: [
                Expanded(
                  child: Text(trGlobal('mm.on_day', {'day': _day}),
                      style: AppFont.style(AppType.labelL,
                          color: AppColor.textPrimary)),
                ),
                AppIconButton(
                    icon: Symbols.remove,
                    size: 36,
                    onTap: () => setState(() => _day = _day > 1 ? _day - 1 : 28)),
                const Gap(AppSpace.sm),
                AppIconButton(
                    icon: Symbols.add,
                    size: 36,
                    onTap: () => setState(() => _day = _day < 28 ? _day + 1 : 1)),
              ]),
              const Gap(AppSpace.lg),
              AppButton(
                label: trGlobal('mm.recurring_add'),
                icon: Symbols.repeat,
                onPressed: _add,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Export
// ═════════════════════════════════════════════════════════════════════

Future<void> _export(BuildContext context, List<Spend> spends) async {
  final messenger = ScaffoldMessenger.of(context);
  if (spends.isEmpty) {
    messenger.showSnackBar(SnackBar(content: Text(trGlobal('mm.empty_title'))));
    return;
  }
  String esc(String s) =>
      s.contains(RegExp(r'[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
  final b = StringBuffer('Date,Category,Note,Paid with,Amount\n');
  for (final s in spends) {
    final d = s.date;
    b.writeln([
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
      s.category,
      esc(s.note),
      s.method,
      s.amount.toStringAsFixed(2),
    ].join(','));
  }
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/MyMoney_${monthKey(DateTime.now())}.csv');
    await file.writeAsString(b.toString());
    await Share.shareXFiles([XFile(file.path, mimeType: 'text/csv')],
        subject: trGlobal('mm.title'));
  } catch (e) {
    messenger.showSnackBar(SnackBar(
        content: Text(trGlobal('common.error_detail', {'e': e}))));
  }
}
