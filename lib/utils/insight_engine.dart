// lib/utils/insight_engine.dart
// Generates rotating daily insights from local invoice/customer data.
// Pure Dart, zero dependencies, runs in <1ms on real data.

import 'package:flutter/widgets.dart';
import 'package:billzap/theme/app_icons.dart';

import '../design/money.dart';
import '../i18n/dates.dart';
import '../i18n/translations.dart';
import '../models/models.dart';

enum InsightType {
  weeklyRevenue,        // Mon — last 7 days summary
  topCustomer,          // Tue — top customer this month
  pendingPayments,      // Wed — overdue alert
  bestDay,              // Thu — best sales day analysis
  monthlyGst,           // Fri — GST collected this month
  inactiveCustomer,     // Sat — re-engage old customer
  weekAhead,            // Sun — what's due next 7 days
  // Special insights triggered when conditions are exceptional
  bestWeekEver,         // any day — beat all-time weekly best
  firstInvoice,         // any day — only show on day 0
}

class Insight {
  final InsightType type;
  final String title;       // small caps tag, e.g. "INSIGHT"
  final String message;     // main body
  final String? actionLabel;  // optional CTA button text
  final InsightAction? action; // optional CTA action
  final InsightTone tone;

  /// Lucide glyph for the card. Icons are bundled with the app, so they
  /// render identically on every device — unlike emoji, which fall back
  /// to whatever set the OEM ships.
  final IconData icon;

  Insight({
    required this.type,
    required this.title,
    required this.message,
    this.actionLabel,
    this.action,
    this.tone = InsightTone.neutral,
    this.icon = Symbols.lightbulb,
  });
}

enum InsightTone { neutral, positive, warning, celebration }

class InsightAction {
  final String route;          // e.g. '/invoices'
  final Map<String, dynamic>? params;
  final String? customerName;  // for actions that target a customer
  InsightAction({required this.route, this.params, this.customerName});
}

class InsightEngine {
  /// Generates the best insight for today based on current data.
  /// Returns null if there's not enough data to say anything meaningful.
  static Insight? generate({
    required List<Invoice> invoices,
    required List<Customer> customers,
    DateTime? today,
  }) {
    final now = today ?? DateTime.now();

    // Edge case: no data at all
    if (invoices.isEmpty) {
      return Insight(
        type: InsightType.firstInvoice,
        title: trGlobal('ins.start_title').toUpperCase(),
        message: trGlobal('ins.start_msg'),
        icon: Symbols.trending_up,
        tone: InsightTone.neutral,
      );
    }

    // Try special insights first (they only fire when conditions are met)
    final special = _trySpecial(invoices, customers, now);
    if (special != null) return special;

    // Otherwise rotate by day of week
    final weekday = now.weekday; // 1 = Mon, 7 = Sun
    switch (weekday) {
      case 1: return _weeklyRevenue(invoices, now)
                  ?? _topCustomer(invoices, now)
                  ?? _fallback(invoices, now);
      case 2: return _topCustomer(invoices, now)
                  ?? _weeklyRevenue(invoices, now)
                  ?? _fallback(invoices, now);
      case 3: return _pendingPayments(invoices, now)
                  ?? _weeklyRevenue(invoices, now)
                  ?? _fallback(invoices, now);
      case 4: return _bestDay(invoices, now)
                  ?? _weeklyRevenue(invoices, now)
                  ?? _fallback(invoices, now);
      case 5: return _monthlyGst(invoices, now)
                  ?? _weeklyRevenue(invoices, now)
                  ?? _fallback(invoices, now);
      case 6: return _inactiveCustomer(invoices, customers, now)
                  ?? _topCustomer(invoices, now)
                  ?? _fallback(invoices, now);
      case 7: return _weekAhead(invoices, now)
                  ?? _pendingPayments(invoices, now)
                  ?? _fallback(invoices, now);
    }
    return _fallback(invoices, now);
  }

  // ─────────────────────────────────────────────────────────────────
  // SPECIAL INSIGHTS (override day-rotation when conditions met)
  // ─────────────────────────────────────────────────────────────────
  static Insight? _trySpecial(List<Invoice> invs, List<Customer> custs, DateTime now) {
    // Best week ever?
    final thisWeek = invs.where((i) =>
      i.status == InvoiceStatus.paid &&
      i.invoiceDate.isAfter(now.subtract(const Duration(days: 7)))
    ).fold<double>(0, (s, i) => s + i.grandTotal);

    if (thisWeek > 1000) {  // worth comparing only if meaningful
      // Compare to all previous 7-day windows
      double bestPrev = 0;
      for (int weekStart = 7; weekStart <= 365; weekStart += 7) {
        final winStart = now.subtract(Duration(days: weekStart + 7));
        final winEnd = now.subtract(Duration(days: weekStart));
        final wkSum = invs.where((i) =>
          i.status == InvoiceStatus.paid &&
          i.invoiceDate.isAfter(winStart) &&
          i.invoiceDate.isBefore(winEnd)
        ).fold<double>(0, (s, i) => s + i.grandTotal);
        if (wkSum > bestPrev) bestPrev = wkSum;
      }

      if (thisWeek > bestPrev && bestPrev > 0) {
        return Insight(
          type: InsightType.bestWeekEver,
          title: trGlobal('ins.record_title'),
          message: trGlobal('ins.record_msg', {'amount': _inr(thisWeek)}),
          icon: Symbols.check_circle,
          tone: InsightTone.celebration,
        );
      }
    }

    return null;
  }

  // ─────────────────────────────────────────────────────────────────
  // INDIVIDUAL INSIGHT GENERATORS
  // ─────────────────────────────────────────────────────────────────

  // MON — last 7 days revenue
  static Insight? _weeklyRevenue(List<Invoice> invs, DateTime now) {
    final last7 = now.subtract(const Duration(days: 7));
    final prev7 = now.subtract(const Duration(days: 14));

    final thisWeek = invs.where((i) =>
      i.status == InvoiceStatus.paid && i.invoiceDate.isAfter(last7)
    ).fold<double>(0, (s, i) => s + i.grandTotal);

    if (thisWeek == 0) return null;

    final lastWeek = invs.where((i) =>
      i.status == InvoiceStatus.paid &&
      i.invoiceDate.isAfter(prev7) &&
      i.invoiceDate.isBefore(last7)
    ).fold<double>(0, (s, i) => s + i.grandTotal);

    String message;
    InsightTone tone;
    IconData icon;

    if (lastWeek == 0) {
      message = trGlobal('ins.week_first', {'amount': _inr(thisWeek)});
      tone = InsightTone.positive;
      icon = Symbols.trending_up;
    } else {
      final diff = thisWeek - lastWeek;
      final pct = (diff / lastWeek * 100).round();
      if (pct > 10) {
        message = trGlobal('ins.week_up', {'amount': _inr(thisWeek), 'pct': pct});
        tone = InsightTone.celebration;
        icon = Symbols.auto_awesome;
      } else if (pct < -10) {
        message = trGlobal('ins.week_down', {'amount': _inr(thisWeek), 'pct': pct.abs()});
        tone = InsightTone.warning;
        icon = Symbols.bar_chart;
      } else {
        message = trGlobal('ins.week_steady', {'amount': _inr(thisWeek)});
        tone = InsightTone.neutral;
        icon = Symbols.bar_chart;
      }
    }

    return Insight(
      type: InsightType.weeklyRevenue,
      title: trGlobal('ins.week_title').toUpperCase(),
      message: message,
      tone: tone,
      icon: icon,
    );
  }

  // TUE — top customer this month
  static Insight? _topCustomer(List<Invoice> invs, DateTime now) {
    final monthStart = DateTime(now.year, now.month, 1);
    final monthInvs = invs.where((i) =>
      i.status == InvoiceStatus.paid && i.invoiceDate.isAfter(monthStart)
    ).toList();

    if (monthInvs.isEmpty) return null;

    final byCustomer = <String, double>{};
    for (final i in monthInvs) {
      byCustomer[i.customerName] = (byCustomer[i.customerName] ?? 0) + i.grandTotal;
    }

    if (byCustomer.length < 2) return null;  // not interesting if only 1 customer

    final sorted = byCustomer.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;

    return Insight(
      type: InsightType.topCustomer,
      title: trGlobal('ins.top_title').toUpperCase(),
      message: trGlobal('ins.top_msg', {'name': top.key, 'amount': _inr(top.value)}),
      icon: Symbols.person,
      tone: InsightTone.positive,
      actionLabel: trGlobal('ins.send_thanks'),
      action: InsightAction(
        route: '/customers',
        customerName: top.key,
      ),
    );
  }

  // WED — overdue payments
  static Insight? _pendingPayments(List<Invoice> invs, DateTime now) {
    final overdue = invs.where((i) => i.isOverdue).toList();
    if (overdue.isEmpty) {
      // Show "all clear" once a week if user has lots of paid invoices
      final paid = invs.where((i) => i.status == InvoiceStatus.paid).length;
      if (paid >= 3) {
        return Insight(
          type: InsightType.pendingPayments,
          title: trGlobal('ins.clear_title'),
          message: trGlobal('ins.clear_msg'),
          icon: Symbols.check_circle,
          tone: InsightTone.positive,
        );
      }
      return null;
    }

    final total = overdue.fold<double>(0, (s, i) => s + i.grandTotal);

    return Insight(
      type: InsightType.pendingPayments,
      title: trGlobal('ins.overdue_title').toUpperCase(),
      message: trGlobal('ins.overdue_msg', {'n': overdue.length, 'amount': _inr(total)}),
      icon: Symbols.lightbulb,
      tone: InsightTone.warning,
      actionLabel: trGlobal('ins.view_overdue'),
      action: InsightAction(route: '/invoices'),
    );
  }

  // THU — best day of week
  static Insight? _bestDay(List<Invoice> invs, DateTime now) {
    final monthStart = DateTime(now.year, now.month, 1);
    final monthInvs = invs.where((i) =>
      i.status == InvoiceStatus.paid && i.invoiceDate.isAfter(monthStart)
    ).toList();

    if (monthInvs.length < 5) return null;  // need data

    final byWeekday = <int, double>{};
    for (final i in monthInvs) {
      final wd = i.invoiceDate.weekday;
      byWeekday[wd] = (byWeekday[wd] ?? 0) + i.grandTotal;
    }

    if (byWeekday.length < 3) return null;

    final sorted = byWeekday.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final best = sorted.first;

    // 2024-01-01 was a Monday, so day N of that week is weekday N.
    String dayName(int weekday) => uiDate('EEEE', DateTime(2024, 1, weekday));

    return Insight(
      type: InsightType.bestDay,
      title: trGlobal('ins.busy_title').toUpperCase(),
      message: trGlobal('ins.busy_msg', {'day': dayName(best.key), 'amount': _inr(best.value)}),
      icon: Symbols.event,
      tone: InsightTone.positive,
    );
  }

  // FRI — GST collected this month
  static Insight? _monthlyGst(List<Invoice> invs, DateTime now) {
    final monthStart = DateTime(now.year, now.month, 1);
    final paidThisMonth = invs.where((i) =>
      i.status == InvoiceStatus.paid && i.invoiceDate.isAfter(monthStart)
    );

    final gst = paidThisMonth.fold<double>(0, (s, i) => s + i.totalTax);
    if (gst < 100) return null;

    final monthName = uiDate('MMMM', now);

    return Insight(
      type: InsightType.monthlyGst,
      // Named after this country's tax: "GST collected" to a shop in
      // Dubai was a sentence about somebody else's tax.
      title: trGlobal('ins.tax_title').toUpperCase(),
      message: trGlobal('ins.tax_msg', {'amount': _inr(gst), 'month': monthName}),
      icon: Symbols.receipt_long,
      tone: InsightTone.neutral,
      actionLabel: trGlobal('ins.view_report'),
      action: InsightAction(route: '/reports'),
    );
  }

  // SAT — inactive customer (re-engagement)
  static Insight? _inactiveCustomer(List<Invoice> invs, List<Customer> custs, DateTime now) {
    if (custs.length < 2) return null;

    // Find customers who haven't been billed in 21+ days
    final byCustomer = <String, DateTime>{};
    for (final i in invs) {
      final existing = byCustomer[i.customerName];
      if (existing == null || i.invoiceDate.isAfter(existing)) {
        byCustomer[i.customerName] = i.invoiceDate;
      }
    }

    final cutoff = now.subtract(const Duration(days: 21));
    final stale = byCustomer.entries.where((e) => e.value.isBefore(cutoff)).toList();

    if (stale.isEmpty) return null;

    // Pick the one who used to buy most often (highest invoice count historically)
    final invoiceCounts = <String, int>{};
    for (final i in invs) {
      invoiceCounts[i.customerName] = (invoiceCounts[i.customerName] ?? 0) + 1;
    }

    stale.sort((a, b) =>
      (invoiceCounts[b.key] ?? 0).compareTo(invoiceCounts[a.key] ?? 0));
    final top = stale.first;
    final daysSince = now.difference(top.value).inDays;

    return Insight(
      type: InsightType.inactiveCustomer,
      title: trGlobal('ins.follow_title').toUpperCase(),
      message: trGlobal('ins.follow_msg', {'name': top.key, 'n': daysSince}),
      icon: Symbols.lightbulb,
      tone: InsightTone.neutral,
      actionLabel: trGlobal('ins.create_invoice'),
      action: InsightAction(route: '/create', customerName: top.key),
    );
  }

  // SUN — week ahead
  static Insight? _weekAhead(List<Invoice> invs, DateTime now) {
    final next7 = now.add(const Duration(days: 7));
    final dueSoon = invs.where((i) =>
      i.status != InvoiceStatus.paid &&
      i.status != InvoiceStatus.cancelled &&
      i.dueDate.isAfter(now) &&
      i.dueDate.isBefore(next7)
    ).toList();

    if (dueSoon.isEmpty) return null;

    final total = dueSoon.fold<double>(0, (s, i) => s + i.grandTotal);

    return Insight(
      type: InsightType.weekAhead,
      title: trGlobal('ins.ahead_title').toUpperCase(),
      message: trGlobal('ins.ahead_msg', {'n': dueSoon.length, 'amount': _inr(total)}),
      icon: Symbols.lightbulb,
      tone: InsightTone.neutral,
      actionLabel: trGlobal('ins.view_invoices'),
      action: InsightAction(route: '/invoices'),
    );
  }

  // Fallback insight when nothing specific applies
  static Insight _fallback(List<Invoice> invs, DateTime now) {
    final paid = invs.where((i) => i.status == InvoiceStatus.paid).length;
    final total = invs.where((i) => i.status == InvoiceStatus.paid)
        .fold<double>(0, (s, i) => s + i.grandTotal);

    return Insight(
      type: InsightType.weeklyRevenue,
      title: trGlobal('ins.biz_title').toUpperCase(),
      message: paid > 0
          ? trGlobal('ins.biz_msg', {'n': paid, 'amount': _inr(total)})
          : trGlobal('ins.welcome'),
      icon: Symbols.lightbulb,
      tone: InsightTone.positive,
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────
  /// Short money for an insight sentence.
  ///
  /// Delegates to the shared short formatter so the ladder matches the
  /// rest of the app and follows the country: lakh and crore in South
  /// Asia, K/M/B everywhere else. An insight that said "₹12L" to a
  /// shopkeeper in Lagos was telling them nothing.
  static String _inr(double amount) =>
      '$activeCurrencySymbol${formatMoneyShort(amount)}';
}
