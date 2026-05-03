// lib/utils/report_csv_helper.dart
// CSVs specifically for the Reports → Export feature.
// Reuses Indian formatting & UTF-8 BOM from csv_helper.dart patterns.

import 'package:intl/intl.dart';
import '../models/models.dart';

class ReportCsvHelper {
  static const _bom = '\uFEFF';

  static String _esc(String value) {
    final needsQuoting = value.contains(',') || value.contains('"') ||
                         value.contains('\n') || value.contains('\r');
    if (needsQuoting) return '"${value.replaceAll('"', '""')}"';
    return value;
  }

  static String _inrNum(double v) {
    final isNeg = v < 0;
    final abs = v.abs();
    final parts = abs.toStringAsFixed(2).split('.');
    String integer = parts[0];
    if (integer.length > 3) {
      final last3 = integer.substring(integer.length - 3);
      final rest = integer.substring(0, integer.length - 3);
      final groups = <String>[];
      for (var i = rest.length; i > 0; i -= 2) {
        groups.insert(0, rest.substring(i < 2 ? 0 : i - 2, i));
      }
      integer = '${groups.join(',')},$last3';
    }
    return '${isNeg ? '-' : ''}$integer.${parts[1]}';
  }

  static String _dt(DateTime d) => DateFormat('dd-MM-yyyy').format(d);
  static String _row(List<String> cells) => cells.map(_esc).join(',') + '\r\n';

  // ═══════════════════════════════════════════════════════════════
  // 1. MONTHLY REVENUE CSV — month-by-month + top customers
  // ═══════════════════════════════════════════════════════════════
  static String monthlyRevenueToCsv(
      List<Invoice> invoices, DateTime from, DateTime to) {
    final buf = StringBuffer(_bom);

    final filtered = invoices.where((i) =>
      i.status == InvoiceStatus.paid &&
      !i.invoiceDate.isBefore(from) &&
      !i.invoiceDate.isAfter(to)
    ).toList();

    // Title
    buf.write(_row(['Monthly Revenue Report']));
    buf.write(_row(['Period:', '${_dt(from)} to ${_dt(to)}']));
    buf.write(_row(['Generated:', _dt(DateTime.now())]));
    buf.write(_row(['']));

    // Section A: Month-wise breakdown
    buf.write(_row(['MONTH-WISE REVENUE']));
    buf.write(_row(['Month', 'Invoices', 'Subtotal', 'Tax', 'Total']));

    final byMonth = <String, List<Invoice>>{};
    for (final inv in filtered) {
      final key = DateFormat('yyyy-MM').format(inv.invoiceDate);
      byMonth.putIfAbsent(key, () => []).add(inv);
    }
    final sortedKeys = byMonth.keys.toList()..sort();
    double grandTotal = 0;
    for (final key in sortedKeys) {
      final invs = byMonth[key]!;
      final subtotal = invs.fold<double>(0, (s, i) => s + i.subtotal);
      final tax = invs.fold<double>(0, (s, i) => s + i.totalTax);
      final total = invs.fold<double>(0, (s, i) => s + i.grandTotal);
      grandTotal += total;
      final dt = DateFormat('yyyy-MM').parse(key);
      buf.write(_row([
        DateFormat('MMMM yyyy').format(dt),
        '${invs.length}',
        _inrNum(subtotal),
        _inrNum(tax),
        _inrNum(total),
      ]));
    }
    buf.write(_row(['']));
    buf.write(_row(['TOTAL', '${filtered.length}', '', '', _inrNum(grandTotal)]));
    buf.write(_row(['']));

    // Section B: Top customers
    buf.write(_row(['TOP CUSTOMERS']));
    buf.write(_row(['Rank', 'Customer', 'Invoices', 'Revenue']));
    final byCustomer = <String, List<Invoice>>{};
    for (final inv in filtered) {
      byCustomer.putIfAbsent(inv.customerName, () => []).add(inv);
    }
    final sortedCusts = byCustomer.entries.toList()
      ..sort((a, b) {
        final aSum = a.value.fold<double>(0, (s, i) => s + i.grandTotal);
        final bSum = b.value.fold<double>(0, (s, i) => s + i.grandTotal);
        return bSum.compareTo(aSum);
      });
    int rank = 1;
    for (final e in sortedCusts.take(20)) {
      final total = e.value.fold<double>(0, (s, i) => s + i.grandTotal);
      buf.write(_row([
        '$rank', e.key, '${e.value.length}', _inrNum(total),
      ]));
      rank++;
    }

    return buf.toString();
  }

  // ═══════════════════════════════════════════════════════════════
  // 2. PROFIT & LOSS CSV — Revenue − Expenses
  // ═══════════════════════════════════════════════════════════════
  static String profitLossToCsv(
      List<Invoice> invoices, List<Expense> expenses,
      DateTime from, DateTime to) {
    final buf = StringBuffer(_bom);

    final paidInvs = invoices.where((i) =>
      i.status == InvoiceStatus.paid &&
      !i.invoiceDate.isBefore(from) &&
      !i.invoiceDate.isAfter(to)
    ).toList();

    final periodExps = expenses.where((e) =>
      !e.date.isBefore(from) && !e.date.isAfter(to)
    ).toList();

    final revenue = paidInvs.fold<double>(0, (s, i) => s + i.grandTotal);
    final expTotal = periodExps.fold<double>(0, (s, e) => s + e.amount);
    final profit = revenue - expTotal;

    buf.write(_row(['Profit & Loss Statement (Cash Basis)']));
    buf.write(_row(['Period:', '${_dt(from)} to ${_dt(to)}']));
    buf.write(_row(['Generated:', _dt(DateTime.now())]));
    buf.write(_row(['']));

    // Summary
    buf.write(_row(['SUMMARY']));
    buf.write(_row(['Item', 'Amount']));
    buf.write(_row(['Total Revenue (Paid Invoices)', _inrNum(revenue)]));
    buf.write(_row(['Total Expenses', _inrNum(expTotal)]));
    buf.write(_row(['NET PROFIT/LOSS', _inrNum(profit)]));
    buf.write(_row(['']));

    // Revenue breakdown
    buf.write(_row(['REVENUE BY MONTH']));
    buf.write(_row(['Month', 'Invoice Count', 'Revenue']));
    final revByMonth = <String, double>{};
    final cntByMonth = <String, int>{};
    for (final inv in paidInvs) {
      final key = DateFormat('yyyy-MM').format(inv.invoiceDate);
      revByMonth[key] = (revByMonth[key] ?? 0) + inv.grandTotal;
      cntByMonth[key] = (cntByMonth[key] ?? 0) + 1;
    }
    final revKeys = revByMonth.keys.toList()..sort();
    for (final k in revKeys) {
      final dt = DateFormat('yyyy-MM').parse(k);
      buf.write(_row([
        DateFormat('MMMM yyyy').format(dt),
        '${cntByMonth[k]}',
        _inrNum(revByMonth[k]!),
      ]));
    }
    buf.write(_row(['']));

    // Expense breakdown by category
    buf.write(_row(['EXPENSES BY CATEGORY']));
    buf.write(_row(['Category', 'Count', 'Amount']));
    final byCat = <String, List<Expense>>{};
    for (final e in periodExps) {
      byCat.putIfAbsent(e.category.isEmpty ? 'Uncategorized' : e.category, () => []).add(e);
    }
    final sortedCats = byCat.entries.toList()
      ..sort((a, b) {
        final aSum = a.value.fold<double>(0, (s, e) => s + e.amount);
        final bSum = b.value.fold<double>(0, (s, e) => s + e.amount);
        return bSum.compareTo(aSum);
      });
    for (final e in sortedCats) {
      final sum = e.value.fold<double>(0, (s, x) => s + x.amount);
      buf.write(_row([
        e.key, '${e.value.length}', _inrNum(sum),
      ]));
    }
    buf.write(_row(['']));
    buf.write(_row([
      'Note', 'Cash basis: only PAID invoices counted as revenue.'
    ]));

    return buf.toString();
  }

  // ═══════════════════════════════════════════════════════════════
  // 3. INVOICE STATUS CSV — paid/pending/overdue + aging
  // ═══════════════════════════════════════════════════════════════
  static String invoiceStatusToCsv(
      List<Invoice> invoices, DateTime from, DateTime to) {
    final buf = StringBuffer(_bom);

    final filtered = invoices.where((i) =>
      !i.invoiceDate.isBefore(from) && !i.invoiceDate.isAfter(to)
    ).toList();

    buf.write(_row(['Invoice Status Report']));
    buf.write(_row(['Period:', '${_dt(from)} to ${_dt(to)}']));
    buf.write(_row(['Generated:', _dt(DateTime.now())]));
    buf.write(_row(['']));

    // Status counts
    buf.write(_row(['STATUS SUMMARY']));
    buf.write(_row(['Status', 'Count', 'Amount']));

    final byStatus = <String, List<Invoice>>{
      'Paid': [],
      'Pending': [],
      'Overdue': [],
      'Cancelled': [],
      'Draft': [],
    };
    for (final inv in filtered) {
      if (inv.status == InvoiceStatus.paid) byStatus['Paid']!.add(inv);
      else if (inv.status == InvoiceStatus.cancelled) byStatus['Cancelled']!.add(inv);
      else if (inv.status == InvoiceStatus.draft) byStatus['Draft']!.add(inv);
      else if (inv.isOverdue) byStatus['Overdue']!.add(inv);
      else byStatus['Pending']!.add(inv);
    }
    for (final e in byStatus.entries) {
      final amt = e.value.fold<double>(0, (s, i) => s + i.grandTotal);
      buf.write(_row([e.key, '${e.value.length}', _inrNum(amt)]));
    }
    buf.write(_row(['']));

    // Aging analysis (overdue + pending only)
    buf.write(_row(['AGING ANALYSIS (Outstanding Invoices)']));
    buf.write(_row(['Bucket', 'Count', 'Amount']));
    final now = DateTime.now();
    final outstanding = filtered.where((i) =>
      i.status != InvoiceStatus.paid &&
      i.status != InvoiceStatus.cancelled &&
      i.status != InvoiceStatus.draft
    );
    final buckets = <String, List<Invoice>>{
      'Current (0-30 days)': [],
      '31-60 days': [],
      '61-90 days': [],
      '90+ days': [],
    };
    for (final inv in outstanding) {
      final daysOverdue = now.difference(inv.dueDate).inDays;
      if (daysOverdue <= 30) buckets['Current (0-30 days)']!.add(inv);
      else if (daysOverdue <= 60) buckets['31-60 days']!.add(inv);
      else if (daysOverdue <= 90) buckets['61-90 days']!.add(inv);
      else buckets['90+ days']!.add(inv);
    }
    for (final e in buckets.entries) {
      final amt = e.value.fold<double>(0, (s, i) => s + i.grandTotal);
      buf.write(_row([e.key, '${e.value.length}', _inrNum(amt)]));
    }
    buf.write(_row(['']));

    // Detail: outstanding invoices
    buf.write(_row(['OUTSTANDING INVOICES (Detail)']));
    buf.write(_row([
      'Invoice', 'Customer', 'Date', 'Due Date',
      'Days Overdue', 'Amount', 'Status',
    ]));
    final sortedOutstanding = outstanding.toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    for (final inv in sortedOutstanding) {
      final daysOverdue = now.difference(inv.dueDate).inDays;
      String stat;
      if (inv.status == InvoiceStatus.paid) stat = 'Paid';
      else if (inv.isOverdue) stat = 'OVERDUE';
      else stat = 'Pending';
      buf.write(_row([
        inv.invoiceNumber, inv.customerName,
        _dt(inv.invoiceDate), _dt(inv.dueDate),
        daysOverdue > 0 ? '$daysOverdue' : '—',
        _inrNum(inv.grandTotal), stat,
      ]));
    }

    return buf.toString();
  }
}
