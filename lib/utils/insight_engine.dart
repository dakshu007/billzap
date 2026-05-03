// lib/utils/insight_engine.dart
// Generates rotating daily insights from local invoice/customer data.
// Pure Dart, zero dependencies, runs in <1ms on real data.

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
  final String emoji;

  Insight({
    required this.type,
    required this.title,
    required this.message,
    this.actionLabel,
    this.action,
    this.tone = InsightTone.neutral,
    this.emoji = '💡',
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
        title: 'GET STARTED',
        message: 'Create your first GST invoice in seconds. Tap the + button or use Voice Bill.',
        emoji: '🚀',
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
          title: 'NEW RECORD 🎉',
          message: 'You earned ${_inr(thisWeek)} this week — your best week yet!',
          emoji: '🏆',
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
    String emoji;

    if (lastWeek == 0) {
      message = 'You earned ${_inr(thisWeek)} this week. Keep it up!';
      tone = InsightTone.positive;
      emoji = '📈';
    } else {
      final diff = thisWeek - lastWeek;
      final pct = (diff / lastWeek * 100).round();
      if (pct > 10) {
        message = '${_inr(thisWeek)} this week — up $pct% from last week 📈';
        tone = InsightTone.celebration;
        emoji = '🎉';
      } else if (pct < -10) {
        message = '${_inr(thisWeek)} this week — down ${pct.abs()}% from last week. Push harder!';
        tone = InsightTone.warning;
        emoji = '💪';
      } else {
        message = '${_inr(thisWeek)} earned this week — steady performance';
        tone = InsightTone.neutral;
        emoji = '📊';
      }
    }

    return Insight(
      type: InsightType.weeklyRevenue,
      title: 'THIS WEEK',
      message: message,
      tone: tone,
      emoji: emoji,
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
      title: 'TOP CUSTOMER',
      message: '${top.key} is your top customer this month — ${_inr(top.value)} across multiple invoices.',
      emoji: '⭐',
      tone: InsightTone.positive,
      actionLabel: 'Send thanks',
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
          title: 'ALL CLEAR ✓',
          message: 'No overdue invoices. Great cash flow!',
          emoji: '💚',
          tone: InsightTone.positive,
        );
      }
      return null;
    }

    final total = overdue.fold<double>(0, (s, i) => s + i.grandTotal);

    return Insight(
      type: InsightType.pendingPayments,
      title: 'OVERDUE',
      message: '${overdue.length} invoice${overdue.length > 1 ? 's' : ''} overdue worth ${_inr(total)}. Time to follow up.',
      emoji: '⏰',
      tone: InsightTone.warning,
      actionLabel: 'View overdue',
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

    const dayNames = {
      1: 'Monday', 2: 'Tuesday', 3: 'Wednesday', 4: 'Thursday',
      5: 'Friday', 6: 'Saturday', 7: 'Sunday',
    };

    return Insight(
      type: InsightType.bestDay,
      title: 'BUSIEST DAY',
      message: '${dayNames[best.key]} is your best sales day this month — ${_inr(best.value)} earned.',
      emoji: '📆',
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

    final monthName = _monthName(now.month);

    return Insight(
      type: InsightType.monthlyGst,
      title: 'GST COLLECTED',
      message: '${_inr(gst)} GST collected in $monthName so far. File on time to avoid penalties.',
      emoji: '🧾',
      tone: InsightTone.neutral,
      actionLabel: 'View report',
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
      title: 'TIME TO FOLLOW UP',
      message: "You haven't billed ${top.key} in $daysSince days. Reach out?",
      emoji: '👋',
      tone: InsightTone.neutral,
      actionLabel: 'Create invoice',
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
      title: 'WEEK AHEAD',
      message: '${dueSoon.length} invoice${dueSoon.length > 1 ? 's' : ''} worth ${_inr(total)} due this week.',
      emoji: '📅',
      tone: InsightTone.neutral,
      actionLabel: 'View invoices',
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
      title: 'YOUR BUSINESS',
      message: paid > 0
          ? '$paid invoices paid, ${_inr(total)} earned overall. Keep going!'
          : 'Welcome to BillZap! Create your first invoice to see insights here.',
      emoji: '✨',
      tone: InsightTone.positive,
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────
  static String _inr(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)}cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}k';
    } else {
      return '₹${amount.toStringAsFixed(0)}';
    }
  }

  static String _monthName(int m) {
    const names = ['', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
    return names[m];
  }
}
