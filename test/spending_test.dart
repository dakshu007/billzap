// My Money arithmetic. Every number the screen shows comes from
// lib/personal/spending.dart, so it is pinned here.

import 'package:flutter_test/flutter_test.dart';
import 'package:billzap/i18n/translations.dart';
import 'package:billzap/personal/spending.dart';

Spend _s(double amount, DateTime date, {String cat = 'food', String id = ''}) =>
    Spend(
        id: id.isEmpty ? '${date.toIso8601String()}-$amount' : id,
        amount: amount,
        category: cat,
        date: date);

void main() {
  group('summarize', () {
    // 10 June 2026: 30-day month, day 10.
    final now = DateTime(2026, 6, 10, 18);

    test('month, today, week and last month are kept apart', () {
      final all = [
        _s(100, DateTime(2026, 6, 10, 9)), // today
        _s(50, DateTime(2026, 6, 8)), // this week
        _s(200, DateTime(2026, 6, 1)), // this month, not this week
        _s(400, DateTime(2026, 5, 20)), // last month
        _s(999, DateTime(2026, 4, 30)), // two months ago: ignored
      ];
      final s = summarize(all, 0, now);
      expect(s.monthSpent, 350);
      expect(s.todaySpent, 100);
      expect(s.weekSpent, 150);
      expect(s.lastMonthSpent, 400);
      expect(s.last7, [0, 0, 0, 0, 50, 0, 100]);
    });

    test('a future-dated entry is not spent yet', () {
      final s = summarize([_s(500, DateTime(2026, 6, 12))], 0, now);
      expect(s.monthSpent, 0);
    });

    test('the week reaches back into last month', () {
      final early = DateTime(2026, 6, 2, 12);
      final s = summarize([_s(70, DateTime(2026, 5, 30))], 0, early);
      expect(s.weekSpent, 70);
      expect(s.monthSpent, 0);
      expect(s.lastMonthSpent, 70);
      expect(s.last7[3], 70);
    });

    test('categories are this month only, largest first', () {
      final s = summarize([
        _s(30, DateTime(2026, 6, 2), cat: 'transport'),
        _s(90, DateTime(2026, 6, 3), cat: 'food'),
        _s(20, DateTime(2026, 6, 4), cat: 'transport'),
        _s(500, DateTime(2026, 5, 4), cat: 'rent'),
      ], 0, now);
      expect(s.byCategory.map((e) => e.key), ['food', 'transport']);
      expect(s.byCategory.last.value, 50);
    });

    test('no-spend days count the days of this month with nothing', () {
      final s = summarize([
        _s(10, DateTime(2026, 6, 1)),
        _s(10, DateTime(2026, 6, 1, 20)),
        _s(10, DateTime(2026, 6, 5)),
      ], 0, now);
      expect(s.noSpendDays, 8); // 10 days so far, 2 with spending
    });

    test('pace, average and comparison', () {
      final s = summarize([
        _s(1000, DateTime(2026, 6, 3)),
        _s(2000, DateTime(2026, 5, 3)),
      ], 0, now);
      expect(s.dailyAverage, 100);
      expect(s.projected, 3000);
      expect(s.vsLastMonth, -0.5);
      expect(summarize([], 0, now).vsLastMonth, isNull);
    });
  });

  group('budget', () {
    final now = DateTime(2026, 6, 10, 18); // 21 days left, today included

    test('no budget means no state and no allowance', () {
      final s = summarize([_s(100, now)], 0, now);
      expect(s.state, BudgetState.none);
      expect(s.dailyAllowance, 0);
      expect(s.used, 0);
    });

    test('the daily allowance does not shrink as today is spent', () {
      // 900 spent before today, 3000 budget: 2100 over 21 days = 100/day.
      final before = summarize([_s(900, DateTime(2026, 6, 3))], 3000, now);
      expect(before.daysLeft, 21);
      expect(before.dailyAllowance, 100);
      expect(before.safeToday, 100);
      final after = summarize(
          [_s(900, DateTime(2026, 6, 3)), _s(40, now)], 3000, now);
      expect(after.dailyAllowance, 100);
      expect(after.safeToday, 60);
    });

    test('safe today never goes negative', () {
      final s = summarize([_s(300, now)], 3000, now);
      expect(s.safeToday, 0);
    });

    test('states: ok, warning at 80%, over past the budget', () {
      expect(summarize([_s(500, now)], 1000, now).state, BudgetState.ok);
      expect(summarize([_s(800, now)], 1000, now).state, BudgetState.warning);
      expect(summarize([_s(1000, now)], 1000, now).state, BudgetState.warning);
      final over = summarize([_s(1200, DateTime(2026, 6, 2))], 1000, now);
      expect(over.state, BudgetState.over);
      expect(over.remaining, -200);
      expect(over.dailyAllowance, 0);
    });

    test('the crossing is said once, at the line', () {
      expect(crossing(700, 50, 1000), isNull);
      expect(crossing(700, 150, 1000), 'warning');
      expect(crossing(850, 50, 1000), isNull);
      expect(crossing(950, 100, 1000), 'over');
      expect(crossing(700, 400, 1000), 'over');
      expect(crossing(1100, 10, 1000), isNull);
      expect(crossing(0, 10, 0), isNull);
    });
  });

  group('repeating expenses', () {
    const rent = RecurringSpend(
        id: 'r1', amount: 12000, category: 'rent', note: 'Rent', dayOfMonth: 5);
    var n = 0;
    String id() => 'new${n++}';

    test('not before its day', () {
      expect(dueRecurring([rent], DateTime(2026, 6, 4), id), isEmpty);
    });

    test('on or after its day, once', () {
      final due = dueRecurring([rent], DateTime(2026, 6, 9), id);
      expect(due, hasLength(1));
      expect(due.single.amount, 12000);
      expect(due.single.date, DateTime(2026, 6, 5, 9));
      expect(due.single.recurringId, 'r1');
      final posted = rent.withPosted('2026-06');
      expect(dueRecurring([posted], DateTime(2026, 6, 20), id), isEmpty);
      expect(dueRecurring([posted], DateTime(2026, 7, 5), id), hasLength(1));
    });

    test('day is kept within 1–28 when read back', () {
      final r = RecurringSpend.fromMap(
          {'id': 'x', 'amount': 1, 'category': 'bills', 'dayOfMonth': 31});
      expect(r.dayOfMonth, 28);
    });
  });

  test('a spend survives a round trip', () {
    final s = Spend(
        id: 'a',
        amount: 12.5,
        category: 'groceries',
        note: 'Milk, "fresh"',
        date: DateTime(2026, 6, 1, 8, 30),
        method: 'card',
        recurringId: 'r');
    final back = Spend.fromMap(s.toMap());
    expect(back.amount, 12.5);
    expect(back.category, 'groceries');
    expect(back.note, 'Milk, "fresh"');
    expect(back.date, DateTime(2026, 6, 1, 8, 30));
    expect(back.method, 'card');
    expect(back.recurringId, 'r');
  });

  test('monthKey and daysInMonth', () {
    expect(monthKey(DateTime(2026, 2, 14)), '2026-02');
    expect(daysInMonth(DateTime(2028, 2, 1)), 29);
    expect(daysInMonth(DateTime(2026, 2, 1)), 28);
    expect(daysInMonth(DateTime(2026, 12, 31)), 31);
  });

  test('every category and payment method has an English label', () {
    // The screen builds these keys at runtime ('mm.cat_$id'), which the
    // key test cannot see.
    final en = englishKeys;
    for (final c in SpendCategory.all) {
      expect(en, contains('mm.cat_${c.id}'));
    }
    for (final m in spendMethods) {
      expect(en, contains('mm.method_$m'));
    }
  });
}
