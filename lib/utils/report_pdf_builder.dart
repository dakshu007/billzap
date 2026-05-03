// lib/utils/report_pdf_builder.dart
// Builds beautifully branded PDFs for the 4 report types.
// Reuses the same blue (0xFF1557FF) as your invoice PDF for visual consistency.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/models.dart';

class ReportPdfBuilder {
  // Brand colors
  static const _brand = PdfColor.fromInt(0xFF1557FF);
  static const _brandSoft = PdfColor.fromInt(0xFFEEF3FF);
  static const _green = PdfColor.fromInt(0xFF2E7D32);
  static const _greenSoft = PdfColor.fromInt(0xFFE8F5E9);
  static const _red = PdfColor.fromInt(0xFFD32F2F);
  static const _redSoft = PdfColor.fromInt(0xFFFFEBEE);
  static const _orange = PdfColor.fromInt(0xFFE65100);
  static const _orangeSoft = PdfColor.fromInt(0xFFFFF3E0);
  static const _yellow = PdfColor.fromInt(0xFFF57F17);
  static const _yellowSoft = PdfColor.fromInt(0xFFFFFDE7);
  static const _t1 = PdfColor.fromInt(0xFF1A1A1A);
  static const _t2 = PdfColor.fromInt(0xFF555555);
  static const _t3 = PdfColor.fromInt(0xFF888888);
  static const _border = PdfColor.fromInt(0xFFE0E0E0);

  // Helpers
  static String _inr(double v) {
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
    return '${isNeg ? '-' : ''}Rs.$integer.${parts[1]}';
  }

  static String _dt(DateTime d) => DateFormat('dd MMM yyyy').format(d);

  // ═══════════════════════════════════════════════════════════════
  // SHARED COMPONENTS
  // ═══════════════════════════════════════════════════════════════

  static pw.Widget _header(String title, String subtitle, Business? biz) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: const pw.BoxDecoration(
        color: _brand,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                biz?.name ?? 'Your Business',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              if ((biz?.gstin ?? '').isNotEmpty)
                pw.Text(
                  'GSTIN: ${biz!.gstin}',
                  style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(99))),
                child: pw.Text(title.toUpperCase(),
                  style: pw.TextStyle(
                    color: _brand, fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.6)),
              ),
              pw.SizedBox(height: 8),
              pw.Text(subtitle,
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 11)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('BillZap',
                style: pw.TextStyle(
                  color: PdfColors.white, fontSize: 14,
                  fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text('Generated ${_dt(DateTime.now())}',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _statCard(String label, String value, PdfColor color, PdfColor soft) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: soft,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 9, color: color,
              fontWeight: pw.FontWeight.bold, letterSpacing: 0.5)),
          pw.SizedBox(height: 6),
          pw.Text(value,
            style: pw.TextStyle(
              fontSize: 14, color: color, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Text(text,
        style: pw.TextStyle(
          fontSize: 13, color: _t1, fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _table(List<String> headers, List<List<String>> rows,
      {List<int>? rightAlignCols}) {
    rightAlignCols ??= [];
    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: {
        for (int i = 0; i < headers.length; i++) i: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _brandSoft),
          children: [
            for (int i = 0; i < headers.length; i++)
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  headers[i],
                  textAlign: rightAlignCols.contains(i)
                    ? pw.TextAlign.right : pw.TextAlign.left,
                  style: pw.TextStyle(
                    fontSize: 10, color: _brand,
                    fontWeight: pw.FontWeight.bold)),
              ),
          ],
        ),
        // Data rows
        for (int r = 0; r < rows.length; r++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: r % 2 == 0 ? PdfColors.white : const PdfColor.fromInt(0xFFFAFBFC)),
            children: [
              for (int i = 0; i < headers.length; i++)
                pw.Padding(
                  padding: const pw.EdgeInsets.all(7),
                  child: pw.Text(
                    i < rows[r].length ? rows[r][i] : '',
                    textAlign: rightAlignCols.contains(i)
                      ? pw.TextAlign.right : pw.TextAlign.left,
                    style: const pw.TextStyle(fontSize: 9.5, color: _t1)),
                ),
            ],
          ),
      ],
    );
  }

  static pw.Widget _footer() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 24),
      padding: const pw.EdgeInsets.only(top: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _border, width: 0.5))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Generated by BillZap',
            style: const pw.TextStyle(fontSize: 9, color: _t3)),
          pw.Text('Free GST billing for Indian MSMEs',
            style: const pw.TextStyle(fontSize: 9, color: _t3)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 1. MONTHLY REVENUE PDF
  // ═══════════════════════════════════════════════════════════════
  static Future<pw.Document> buildMonthlyRevenue({
    required List<Invoice> invoices,
    required DateTime from,
    required DateTime to,
    required Business? biz,
  }) async {
    final doc = pw.Document();

    final filtered = invoices.where((i) =>
      i.status == InvoiceStatus.paid &&
      !i.invoiceDate.isBefore(from) &&
      !i.invoiceDate.isAfter(to)
    ).toList();

    final totalRevenue = filtered.fold<double>(0, (s, i) => s + i.grandTotal);
    final totalTax = filtered.fold<double>(0, (s, i) => s + i.totalTax);
    final invoiceCount = filtered.length;
    final avg = invoiceCount > 0 ? totalRevenue / invoiceCount : 0;

    // Month-wise
    final byMonth = <String, List<Invoice>>{};
    for (final inv in filtered) {
      final key = DateFormat('yyyy-MM').format(inv.invoiceDate);
      byMonth.putIfAbsent(key, () => []).add(inv);
    }
    final monthRows = byMonth.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Top customers
    final byCustomer = <String, List<Invoice>>{};
    for (final inv in filtered) {
      byCustomer.putIfAbsent(inv.customerName, () => []).add(inv);
    }
    final topCusts = byCustomer.entries.toList()
      ..sort((a, b) {
        final aSum = a.value.fold<double>(0, (s, i) => s + i.grandTotal);
        final bSum = b.value.fold<double>(0, (s, i) => s + i.grandTotal);
        return bSum.compareTo(aSum);
      });

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (_) => [
        _header('Monthly Revenue', '${_dt(from)} — ${_dt(to)}', biz),
        pw.SizedBox(height: 18),
        // Stat row
        pw.Row(children: [
          pw.Expanded(child: _statCard('Total Revenue', _inr(totalRevenue), _brand, _brandSoft)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _statCard('Invoices', '$invoiceCount', _green, _greenSoft)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _statCard('Tax Collected', _inr(totalTax), _orange, _orangeSoft)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _statCard('Avg Invoice', _inr(avg.toDouble()), _yellow, _yellowSoft)),
        ]),
        pw.SizedBox(height: 16),
        _sectionTitle('Month-wise Breakdown'),
        _table(
          ['Month', 'Invoices', 'Subtotal', 'Tax', 'Total'],
          monthRows.map((e) {
            final invs = e.value;
            final dt = DateFormat('yyyy-MM').parse(e.key);
            return [
              DateFormat('MMM yyyy').format(dt),
              '${invs.length}',
              _inr(invs.fold<double>(0, (s, i) => s + i.subtotal)),
              _inr(invs.fold<double>(0, (s, i) => s + i.totalTax)),
              _inr(invs.fold<double>(0, (s, i) => s + i.grandTotal)),
            ];
          }).toList(),
          rightAlignCols: [1, 2, 3, 4],
        ),
        pw.SizedBox(height: 16),
        _sectionTitle('Top Customers (Top 10)'),
        _table(
          ['Rank', 'Customer', 'Invoices', 'Revenue'],
          topCusts.take(10).toList().asMap().entries.map((e) {
            final total = e.value.value.fold<double>(0, (s, i) => s + i.grandTotal);
            return [
              '#${e.key + 1}',
              e.value.key,
              '${e.value.value.length}',
              _inr(total),
            ];
          }).toList(),
          rightAlignCols: [2, 3],
        ),
        _footer(),
      ],
    ));
    return doc;
  }

  // ═══════════════════════════════════════════════════════════════
  // 2. PROFIT & LOSS PDF
  // ═══════════════════════════════════════════════════════════════
  static Future<pw.Document> buildProfitLoss({
    required List<Invoice> invoices,
    required List<Expense> expenses,
    required DateTime from,
    required DateTime to,
    required Business? biz,
  }) async {
    final doc = pw.Document();

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
    final isProfit = profit >= 0;

    // Expense by category
    final byCat = <String, List<Expense>>{};
    for (final e in periodExps) {
      byCat.putIfAbsent(
        e.category.isEmpty ? 'Uncategorized' : e.category, () => []).add(e);
    }
    final sortedCats = byCat.entries.toList()
      ..sort((a, b) {
        final aSum = a.value.fold<double>(0, (s, e) => s + e.amount);
        final bSum = b.value.fold<double>(0, (s, e) => s + e.amount);
        return bSum.compareTo(aSum);
      });

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (_) => [
        _header('Profit & Loss', '${_dt(from)} — ${_dt(to)}', biz),
        pw.SizedBox(height: 18),
        // Hero P&L card
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: isProfit ? _greenSoft : _redSoft,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            border: pw.Border.all(
              color: isProfit ? _green : _red, width: 1)),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(isProfit ? 'NET PROFIT' : 'NET LOSS',
                    style: pw.TextStyle(
                      fontSize: 11, color: isProfit ? _green : _red,
                      fontWeight: pw.FontWeight.bold, letterSpacing: 0.6)),
                  pw.SizedBox(height: 4),
                  pw.Text(_inr(profit.abs()),
                    style: pw.TextStyle(
                      fontSize: 26, color: isProfit ? _green : _red,
                      fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Revenue: ${_inr(revenue)}',
                    style: const pw.TextStyle(fontSize: 11, color: _t2)),
                  pw.SizedBox(height: 4),
                  pw.Text('Expenses: ${_inr(expTotal)}',
                    style: const pw.TextStyle(fontSize: 11, color: _t2)),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        // Stat cards
        pw.Row(children: [
          pw.Expanded(child: _statCard(
            'Total Revenue', _inr(revenue), _green, _greenSoft)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _statCard(
            'Total Expenses', _inr(expTotal), _red, _redSoft)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _statCard(
            'Paid Invoices', '${paidInvs.length}', _brand, _brandSoft)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _statCard(
            'Expense Records', '${periodExps.length}', _orange, _orangeSoft)),
        ]),
        pw.SizedBox(height: 16),
        _sectionTitle('Expense Breakdown by Category'),
        if (sortedCats.isEmpty)
          pw.Text('No expenses recorded in this period.',
            style: const pw.TextStyle(color: _t3, fontSize: 11))
        else
          _table(
            ['Category', 'Count', 'Amount', '% of Expenses'],
            sortedCats.map((e) {
              final sum = e.value.fold<double>(0, (s, x) => s + x.amount);
              final pct = expTotal > 0 ? (sum / expTotal * 100) : 0;
              return [
                e.key, '${e.value.length}', _inr(sum),
                '${pct.toStringAsFixed(1)}%',
              ];
            }).toList(),
            rightAlignCols: [1, 2, 3],
          ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: _yellowSoft,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6))),
          child: pw.Text(
            'Note: This P&L uses cash basis accounting — only PAID invoices count as revenue. '
            'Pending invoices are not included until marked paid.',
            style: const pw.TextStyle(fontSize: 9, color: _t2)),
        ),
        _footer(),
      ],
    ));
    return doc;
  }

  // ═══════════════════════════════════════════════════════════════
  // 3. GST SUMMARY PDF
  // ═══════════════════════════════════════════════════════════════
  static Future<pw.Document> buildGstSummary({
    required List<Invoice> invoices,
    required DateTime from,
    required DateTime to,
    required Business? biz,
  }) async {
    final doc = pw.Document();

    final filtered = invoices.where((i) =>
      i.status == InvoiceStatus.paid &&
      !i.invoiceDate.isBefore(from) &&
      !i.invoiceDate.isAfter(to)
    ).toList();

    final totalCgst = filtered.fold<double>(0, (s, i) => s + i.totalCgst);
    final totalSgst = filtered.fold<double>(0, (s, i) => s + i.totalSgst);
    final totalIgst = filtered.fold<double>(0, (s, i) => s + i.totalIgst);
    final totalGst = totalCgst + totalSgst + totalIgst;
    final totalTaxable = filtered.fold<double>(0, (s, i) => s + i.subtotal);

    // Month-wise GST
    final byMonth = <String, List<Invoice>>{};
    for (final inv in filtered) {
      final key = DateFormat('yyyy-MM').format(inv.invoiceDate);
      byMonth.putIfAbsent(key, () => []).add(inv);
    }
    final monthEntries = byMonth.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (_) => [
        _header('GST Summary', '${_dt(from)} — ${_dt(to)}', biz),
        pw.SizedBox(height: 18),
        // Stat cards
        pw.Row(children: [
          pw.Expanded(child: _statCard('Total Taxable', _inr(totalTaxable), _t2, _border)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _statCard('Total GST', _inr(totalGst), _brand, _brandSoft)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _statCard('CGST + SGST', _inr(totalCgst + totalSgst), _orange, _orangeSoft)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _statCard('IGST', _inr(totalIgst), _green, _greenSoft)),
        ]),
        pw.SizedBox(height: 16),
        _sectionTitle('Month-wise GST Breakdown (for GSTR-1 filing)'),
        _table(
          ['Month', 'Invoices', 'Taxable', 'CGST', 'SGST', 'IGST', 'Total Tax'],
          monthEntries.map((e) {
            final invs = e.value;
            final dt = DateFormat('yyyy-MM').parse(e.key);
            final taxable = invs.fold<double>(0, (s, i) => s + i.subtotal);
            final c = invs.fold<double>(0, (s, i) => s + i.totalCgst);
            final s = invs.fold<double>(0, (sum, i) => sum + i.totalSgst);
            final ig = invs.fold<double>(0, (sum, i) => sum + i.totalIgst);
            return [
              DateFormat('MMM yyyy').format(dt),
              '${invs.length}',
              _inr(taxable),
              _inr(c),
              _inr(s),
              _inr(ig),
              _inr(c + s + ig),
            ];
          }).toList(),
          rightAlignCols: [1, 2, 3, 4, 5, 6],
        ),
        pw.SizedBox(height: 14),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _yellowSoft,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6))),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('GST FILING REMINDER',
                style: pw.TextStyle(
                  fontSize: 10, color: _yellow,
                  fontWeight: pw.FontWeight.bold, letterSpacing: 0.6)),
              pw.SizedBox(height: 4),
              pw.Text(
                'GSTR-1 due monthly by 11th. GSTR-3B due monthly by 20th. '
                'Use this summary as supporting data — verify with your accountant before filing.',
                style: const pw.TextStyle(fontSize: 10, color: _t2)),
            ],
          ),
        ),
        _footer(),
      ],
    ));
    return doc;
  }

  // ═══════════════════════════════════════════════════════════════
  // 4. INVOICE STATUS PDF
  // ═══════════════════════════════════════════════════════════════
  static Future<pw.Document> buildInvoiceStatus({
    required List<Invoice> invoices,
    required DateTime from,
    required DateTime to,
    required Business? biz,
  }) async {
    final doc = pw.Document();

    final filtered = invoices.where((i) =>
      !i.invoiceDate.isBefore(from) && !i.invoiceDate.isAfter(to)
    ).toList();

    int paidCount = 0, pendingCount = 0, overdueCount = 0,
        cancelledCount = 0, draftCount = 0;
    double paidAmt = 0, pendingAmt = 0, overdueAmt = 0,
        cancelledAmt = 0, draftAmt = 0;

    for (final inv in filtered) {
      if (inv.status == InvoiceStatus.paid) {
        paidCount++; paidAmt += inv.grandTotal;
      } else if (inv.status == InvoiceStatus.cancelled) {
        cancelledCount++; cancelledAmt += inv.grandTotal;
      } else if (inv.status == InvoiceStatus.draft) {
        draftCount++; draftAmt += inv.grandTotal;
      } else if (inv.isOverdue) {
        overdueCount++; overdueAmt += inv.grandTotal;
      } else {
        pendingCount++; pendingAmt += inv.grandTotal;
      }
    }

    // Aging
    final outstanding = filtered.where((i) =>
      i.status != InvoiceStatus.paid &&
      i.status != InvoiceStatus.cancelled &&
      i.status != InvoiceStatus.draft
    ).toList();

    final now = DateTime.now();
    final agingBuckets = <String, List<Invoice>>{
      '0-30 days': [],
      '31-60 days': [],
      '61-90 days': [],
      '90+ days': [],
    };
    for (final inv in outstanding) {
      final daysOverdue = now.difference(inv.dueDate).inDays;
      if (daysOverdue <= 30) agingBuckets['0-30 days']!.add(inv);
      else if (daysOverdue <= 60) agingBuckets['31-60 days']!.add(inv);
      else if (daysOverdue <= 90) agingBuckets['61-90 days']!.add(inv);
      else agingBuckets['90+ days']!.add(inv);
    }

    // Sort outstanding by oldest due first
    outstanding.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (_) => [
        _header('Invoice Status', '${_dt(from)} — ${_dt(to)}', biz),
        pw.SizedBox(height: 18),
        // Status summary cards
        pw.Row(children: [
          pw.Expanded(child: _statCard('Paid', '$paidCount', _green, _greenSoft)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _statCard('Pending', '$pendingCount', _orange, _orangeSoft)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _statCard('Overdue', '$overdueCount', _red, _redSoft)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _statCard('Total', '${filtered.length}', _brand, _brandSoft)),
        ]),
        pw.SizedBox(height: 16),
        _sectionTitle('Status Summary'),
        _table(
          ['Status', 'Count', 'Amount'],
          [
            ['Paid', '$paidCount', _inr(paidAmt)],
            ['Pending', '$pendingCount', _inr(pendingAmt)],
            ['Overdue', '$overdueCount', _inr(overdueAmt)],
            ['Cancelled', '$cancelledCount', _inr(cancelledAmt)],
            ['Draft', '$draftCount', _inr(draftAmt)],
          ],
          rightAlignCols: [1, 2],
        ),
        pw.SizedBox(height: 16),
        _sectionTitle('Aging Analysis (Outstanding Invoices)'),
        _table(
          ['Age', 'Count', 'Outstanding Amount'],
          agingBuckets.entries.map((e) {
            final amt = e.value.fold<double>(0, (s, i) => s + i.grandTotal);
            return [e.key, '${e.value.length}', _inr(amt)];
          }).toList(),
          rightAlignCols: [1, 2],
        ),
        if (outstanding.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          _sectionTitle('Outstanding Invoices (Detail)'),
          _table(
            ['Invoice', 'Customer', 'Due Date', 'Days Overdue', 'Amount'],
            outstanding.take(50).map((inv) {
              final daysOverdue = now.difference(inv.dueDate).inDays;
              return [
                inv.invoiceNumber,
                inv.customerName,
                _dt(inv.dueDate),
                daysOverdue > 0 ? '$daysOverdue' : '-',
                _inr(inv.grandTotal),
              ];
            }).toList(),
            rightAlignCols: [3, 4],
          ),
          if (outstanding.length > 50)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 8),
              child: pw.Text(
                'Showing first 50 of ${outstanding.length} outstanding invoices. '
                'Export CSV for full list.',
                style: const pw.TextStyle(fontSize: 9, color: _t3, fontStyle: pw.FontStyle.italic)),
            ),
        ],
        _footer(),
      ],
    ));
    return doc;
  }
}
