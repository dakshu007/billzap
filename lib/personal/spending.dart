// lib/personal/spending.dart — My Money: a person's own spending.
//
// Not the shop's expenses. Those reduce the shop's profit and feed its
// reports; these are a person's coffee, rent and bus fare, kept apart so
// neither muddles the other. Anyone can use this part of the app — a
// student, a bachelor on a first salary, a household — with no shop set
// up at all.
//
// Pure Dart: every number on the My Money screen is computed here and
// tested in test/spending_test.dart. The screen only draws them.

/// What a spend was on. Stored by [id]; the label is translated at
/// display time, so changing the app language relabels history too.
class SpendCategory {
  final String id;
  const SpendCategory(this.id);

  static const food = SpendCategory('food');
  static const groceries = SpendCategory('groceries');
  static const transport = SpendCategory('transport');
  static const rent = SpendCategory('rent');
  static const bills = SpendCategory('bills');
  static const shopping = SpendCategory('shopping');
  static const health = SpendCategory('health');
  static const fun = SpendCategory('fun');
  static const education = SpendCategory('education');
  static const family = SpendCategory('family');
  static const travel = SpendCategory('travel');
  static const care = SpendCategory('care');
  static const subscriptions = SpendCategory('subscriptions');
  static const gifts = SpendCategory('gifts');
  static const other = SpendCategory('other');

  /// In the order the add sheet shows them: the everyday ones first.
  static const all = <SpendCategory>[
    food, groceries, transport, shopping, bills, rent, health, fun,
    subscriptions, education, family, travel, care, gifts, other,
  ];

  static SpendCategory byId(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => other);
}

/// How it was paid. Purely informational; nothing is calculated from it.
const spendMethods = <String>['cash', 'card', 'upi', 'bank', 'wallet'];

class Spend {
  final String id;
  final double amount;
  final String category;
  final String note;
  final DateTime date;
  final String method;

  /// Set when a repeating expense created this entry.
  final String? recurringId;

  const Spend({
    required this.id,
    required this.amount,
    required this.category,
    this.note = '',
    required this.date,
    this.method = 'cash',
    this.recurringId,
  });

  Spend copyWith({
    double? amount,
    String? category,
    String? note,
    DateTime? date,
    String? method,
  }) =>
      Spend(
        id: id,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        note: note ?? this.note,
        date: date ?? this.date,
        method: method ?? this.method,
        recurringId: recurringId,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'category': category,
        'note': note,
        'date': date.toIso8601String(),
        'method': method,
        if (recurringId != null) 'recurringId': recurringId,
      };

  factory Spend.fromMap(Map<String, dynamic> m) => Spend(
        id: m['id'] as String,
        amount: (m['amount'] as num).toDouble(),
        category: (m['category'] as String?) ?? 'other',
        note: (m['note'] as String?) ?? '',
        date: DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now(),
        method: (m['method'] as String?) ?? 'cash',
        recurringId: m['recurringId'] as String?,
      );
}

/// Rent, a phone plan, a gym fee, a loan instalment: an amount that
/// lands on the same day every month and is added by itself.
class RecurringSpend {
  final String id;
  final double amount;
  final String category;
  final String note;

  /// 1–28. Capped at 28 so it falls in every month, February included.
  final int dayOfMonth;

  /// 'yyyy-MM' of the last month it was added for; empty if never.
  final String lastPosted;

  const RecurringSpend({
    required this.id,
    required this.amount,
    required this.category,
    this.note = '',
    required this.dayOfMonth,
    this.lastPosted = '',
  });

  RecurringSpend withPosted(String month) => RecurringSpend(
        id: id,
        amount: amount,
        category: category,
        note: note,
        dayOfMonth: dayOfMonth,
        lastPosted: month,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'category': category,
        'note': note,
        'dayOfMonth': dayOfMonth,
        'lastPosted': lastPosted,
      };

  factory RecurringSpend.fromMap(Map<String, dynamic> m) => RecurringSpend(
        id: m['id'] as String,
        amount: (m['amount'] as num).toDouble(),
        category: (m['category'] as String?) ?? 'other',
        note: (m['note'] as String?) ?? '',
        dayOfMonth: ((m['dayOfMonth'] as num?)?.toInt() ?? 1).clamp(1, 28),
        lastPosted: (m['lastPosted'] as String?) ?? '',
      );
}

String monthKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

int daysInMonth(DateTime d) => DateTime(d.year, d.month + 1, 0).day;

/// The entries a repeating expense owes as of [now]: one for this month
/// if its day has come and it has not been added yet. A month the app
/// was not opened in at all is not back-filled — a person who did not
/// open the app in March does not want three months of rent appearing
/// at once without being asked.
List<Spend> dueRecurring(
  List<RecurringSpend> recurring,
  DateTime now,
  String Function() newId,
) {
  final out = <Spend>[];
  final key = monthKey(now);
  for (final r in recurring) {
    if (r.lastPosted == key) continue;
    if (now.day < r.dayOfMonth) continue;
    out.add(Spend(
      id: newId(),
      amount: r.amount,
      category: r.category,
      note: r.note,
      date: DateTime(now.year, now.month, r.dayOfMonth, 9),
      method: 'bank',
      recurringId: r.id,
    ));
  }
  return out;
}

/// Where the month stands against the budget.
enum BudgetState { none, ok, warning, over }

/// Everything the My Money screen shows, computed for [now].
class SpendingSummary {
  final double monthSpent;
  final double lastMonthSpent;
  final double todaySpent;
  final double weekSpent;
  final double budget;

  /// Days of this month so far, including today.
  final int daysElapsed;
  final int daysInThisMonth;

  /// Days this month with nothing spent, up to and including today.
  final int noSpendDays;

  /// Spend per day for the last seven days, oldest first; [6] is today.
  final List<double> last7;

  /// This month's spend by category id, largest first.
  final List<MapEntry<String, double>> byCategory;

  const SpendingSummary({
    required this.monthSpent,
    required this.lastMonthSpent,
    required this.todaySpent,
    required this.weekSpent,
    required this.budget,
    required this.daysElapsed,
    required this.daysInThisMonth,
    required this.noSpendDays,
    required this.last7,
    required this.byCategory,
  });

  int get daysLeft => daysInThisMonth - daysElapsed + 1;

  double get remaining => budget - monthSpent;

  double get dailyAverage => daysElapsed == 0 ? 0 : monthSpent / daysElapsed;

  /// Month-end total if spending carries on at this month's daily rate.
  double get projected => dailyAverage * daysInThisMonth;

  /// What each remaining day can take, today included, and still end
  /// the month inside the budget — counted from the start of today, so
  /// it does not shrink as today's own spending goes in.
  double get dailyAllowance {
    if (budget <= 0) return 0;
    final per = (remaining + todaySpent) / daysLeft;
    return per < 0 ? 0 : per;
  }

  /// What is left of today's allowance. Never negative.
  double get safeToday {
    final left = dailyAllowance - todaySpent;
    return left < 0 ? 0 : left;
  }

  /// Fraction of the budget used; 0 with no budget.
  double get used => budget <= 0 ? 0 : monthSpent / budget;

  BudgetState get state {
    if (budget <= 0) return BudgetState.none;
    if (monthSpent > budget) return BudgetState.over;
    if (used >= 0.8) return BudgetState.warning;
    return BudgetState.ok;
  }

  /// Change against last month, as a fraction (-0.12 is 12% less).
  /// Null when last month had nothing to compare with.
  double? get vsLastMonth =>
      lastMonthSpent <= 0 ? null : (monthSpent - lastMonthSpent) / lastMonthSpent;
}

SpendingSummary summarize(List<Spend> all, double budget, DateTime now) {
  final today = _day(now);
  final monthStart = DateTime(now.year, now.month);
  final lastMonthStart = DateTime(now.year, now.month - 1);
  final weekStart = today.subtract(const Duration(days: 6));

  double month = 0, lastMonth = 0, todayTotal = 0, week = 0;
  final last7 = List<double>.filled(7, 0);
  final byCat = <String, double>{};
  final spentDays = <int>{};

  for (final s in all) {
    final d = _day(s.date);
    if (d.isAfter(today)) continue; // future-dated: not spent yet
    if (!d.isBefore(monthStart)) {
      month += s.amount;
      byCat[s.category] = (byCat[s.category] ?? 0) + s.amount;
      if (s.amount > 0) spentDays.add(d.day);
    } else if (!d.isBefore(lastMonthStart)) {
      lastMonth += s.amount;
    }
    if (d == today) todayTotal += s.amount;
    if (!d.isBefore(weekStart)) {
      week += s.amount;
      last7[6 - today.difference(d).inDays] += s.amount;
    }
  }

  final cats = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return SpendingSummary(
    monthSpent: month,
    lastMonthSpent: lastMonth,
    todaySpent: todayTotal,
    weekSpent: week,
    budget: budget,
    daysElapsed: now.day,
    daysInThisMonth: daysInMonth(now),
    noSpendDays: now.day - spentDays.length,
    last7: last7,
    byCategory: cats,
  );
}

/// The budget message adding [amount] would trigger, or null if it
/// crosses no line: 'over' when it pushes the month past the budget,
/// 'warning' when it crosses 80%. Said once, at the crossing — not on
/// every later spend, which would turn a warning into noise.
String? crossing(double before, double amount, double budget) {
  if (budget <= 0) return null;
  final after = before + amount;
  if (before <= budget && after > budget) return 'over';
  if (before < budget * 0.8 && after >= budget * 0.8) return 'warning';
  return null;
}
