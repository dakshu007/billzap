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

// ── Backup ───────────────────────────────────────────────────────────
// My Money rides in the same encrypted backup file as the shop's data,
// under its own 'spending' key. A backup made before My Money existed
// simply has no such key, and restoring it leaves My Money as it is.

/// This person's spending, for the backup file. Null when there is none.
Map<String, dynamic>? spendingForBackup() {
  if (!Hive.isBoxOpen(kSpendingBox)) return null;
  final b = Hive.box(kSpendingBox);
  final spends = b.get(_kSpends);
  final recurring = b.get(_kRecurring);
  final budget = (b.get(_kBudget) as num?)?.toDouble() ?? 0;
  if (spends == null && recurring == null && budget == 0) return null;
  return {
    'spends': spends is String ? jsonDecode(spends) : const [],
    'recurring': recurring is String ? jsonDecode(recurring) : const [],
    'budget': budget,
  };
}

/// Puts a backup's spending back, merged by id with what is already
/// here, the backup's copy winning — the same rule the rest of restore
/// follows. Returns how many expenses the backup held.
Future<int> restoreSpendingFromBackup(Object? raw) async {
  if (raw is! Map) return 0;
  final b = Hive.isBoxOpen(kSpendingBox)
      ? Hive.box(kSpendingBox)
      : await Hive.openBox(kSpendingBox);
  List<Map<String, dynamic>> maps(Object? v) => v is List
      ? [for (final m in v) if (m is Map) Map<String, dynamic>.from(m)]
      : const [];
  List<Map<String, dynamic>> stored(String key) {
    final s = b.get(key);
    if (s is! String) return const [];
    try {
      return maps(jsonDecode(s));
    } catch (_) {
      return const [];
    }
  }

  List<Map<String, dynamic>> merge(
      List<Map<String, dynamic>> here, List<Map<String, dynamic>> incoming) {
    final byId = <String, Map<String, dynamic>>{
      for (final m in here)
        if (m['id'] is String) m['id'] as String: m,
    };
    for (final m in incoming) {
      if (m['id'] is String) byId[m['id'] as String] = m;
    }
    return byId.values.toList();
  }

  final spends = maps(raw['spends']);
  // Each entry is read through its model before it is stored, so a
  // damaged entry is dropped rather than breaking My Money on open.
  final goodSpends = <Map<String, dynamic>>[];
  for (final m in merge(stored(_kSpends), spends)) {
    try {
      goodSpends.add(Spend.fromMap(m).toMap());
    } catch (_) {
      // damaged entry: dropped
    }
  }
  final goodRecurring = <Map<String, dynamic>>[];
  for (final m in merge(stored(_kRecurring), maps(raw['recurring']))) {
    try {
      goodRecurring.add(RecurringSpend.fromMap(m).toMap());
    } catch (_) {
      // damaged entry: dropped
    }
  }
  await b.put(_kSpends, jsonEncode(goodSpends));
  await b.put(_kRecurring, jsonEncode(goodRecurring));
  final budget = (raw['budget'] as num?)?.toDouble() ?? 0;
  if (budget > 0) await b.put(_kBudget, budget);
  return spends.length;
}
