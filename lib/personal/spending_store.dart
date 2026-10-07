// lib/personal/spending_store.dart — My Money's storage and provider.
//
// Its own Hive box, separate from the shop's data, opened in main()
// before the first frame like 'settings'.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/models.dart' show genId;
import 'spending.dart';

const kSpendingBox = 'spending';
const _kSpends = 'spends';
const _kRecurring = 'recurring';
const _kBudget = 'budget';

class SpendingState {
  final List<Spend> spends; // newest first
  final List<RecurringSpend> recurring;
  final double budget;
  const SpendingState(this.spends, this.recurring, this.budget);
}

class SpendingNotifier extends Notifier<SpendingState> {
  Box? get _box => Hive.isBoxOpen(kSpendingBox) ? Hive.box(kSpendingBox) : null;

  @override
  SpendingState build() {
    final loaded = _load();
    // Rent day has come since the app was last opened: add it now.
    final due = dueRecurring(loaded.recurring, DateTime.now(), genId);
    if (due.isEmpty) return loaded;
    final posted = monthKey(DateTime.now());
    final ids = due.map((d) => d.recurringId).toSet();
    final next = SpendingState(
      _sorted([...due, ...loaded.spends]),
      [
        for (final r in loaded.recurring)
          ids.contains(r.id) ? r.withPosted(posted) : r,
      ],
      loaded.budget,
    );
    _save(next);
    return next;
  }

  SpendingState _load() {
    final b = _box;
    if (b == null) return const SpendingState([], [], 0);
    List<T> list<T>(String key, T Function(Map<String, dynamic>) f) {
      try {
        final raw = b.get(key);
        if (raw is! String) return <T>[];
        return (jsonDecode(raw) as List)
            .map((m) => f(Map<String, dynamic>.from(m as Map)))
            .toList();
      } catch (_) {
        return <T>[];
      }
    }

    return SpendingState(
      _sorted(list(_kSpends, Spend.fromMap)),
      list(_kRecurring, RecurringSpend.fromMap),
      (b.get(_kBudget) as num?)?.toDouble() ?? 0,
    );
  }

  List<Spend> _sorted(List<Spend> s) =>
      [...s]..sort((a, b) => b.date.compareTo(a.date));

  void _save(SpendingState s) {
    final b = _box;
    if (b == null) return;
    b.put(_kSpends, jsonEncode(s.spends.map((e) => e.toMap()).toList()));
    b.put(_kRecurring, jsonEncode(s.recurring.map((e) => e.toMap()).toList()));
    b.put(_kBudget, s.budget);
  }

  void _set(SpendingState s) {
    state = s;
    _save(s);
  }

  /// Adds (or replaces, by id) a spend.
  void put(Spend s) {
    final rest = state.spends.where((e) => e.id != s.id);
    _set(SpendingState(_sorted([s, ...rest]), state.recurring, state.budget));
  }

  void remove(String id) => _set(SpendingState(
      state.spends.where((e) => e.id != id).toList(),
      state.recurring,
      state.budget));

  void setBudget(double budget) =>
      _set(SpendingState(state.spends, state.recurring, budget < 0 ? 0 : budget));

  /// Adds a repeating expense. If its day has already passed this month
  /// it is added for this month straight away — the person is setting
  /// it up because it is due.
  void addRecurring(RecurringSpend r) {
    final now = DateTime.now();
    final due = dueRecurring([r], now, genId);
    _set(SpendingState(
      _sorted([...due, ...state.spends]),
      [
        ...state.recurring,
        due.isEmpty ? r : r.withPosted(monthKey(now)),
      ],
      state.budget,
    ));
  }

  void removeRecurring(String id) => _set(SpendingState(
      state.spends,
      state.recurring.where((r) => r.id != id).toList(),
      state.budget));
}

final spendingProvider =
    NotifierProvider<SpendingNotifier, SpendingState>(SpendingNotifier.new);
