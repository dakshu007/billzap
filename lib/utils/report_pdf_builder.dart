// lib/utils/report_pdf_builder.dart
//
// The four exported reports: Monthly Revenue, Profit & Loss, GST Summary
// and Invoice Status.
//
// These are the only artefacts of the app that leave the phone and land
// in someone else's inbox — an accountant's, a bank's, a buyer's — so
// they are held to the same standard as the invoice itself.
//
// Three things the previous version got wrong, all visible the moment
// you opened one:
//
//   • It printed "Rs." because it used a built-in PDF font. Those are
//     Latin-1 only and carry no rupee glyph. Every em dash came out as a
//     tofu box for the same reason. Inter is embedded here, so ₹ is ₹.
//   • Its header pill used a 99pt corner radius on a ~16pt-tall box. At
//     a radius past half the height the corner arcs self-intersect and
//     the pdf package draws a bowtie across the page. Radii are clamped.
//   • It was blue, from a brand the app no longer has.
//
// The layout follows the app: ink type, jade for the one figure that
// matters, hairlines instead of a full table grid, and tabular figures
// down every money column.

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/models.dart';

class ReportPdfBuilder {
  // ── Print palette ───────────────────────────────────────────────
  // Deliberately not the screen tokens. Screen colour is emitted light;
  // print colour is reflected ink, and the jade that reads as precise on
  // an OLED goes muddy on office paper. These are the print values.
  static const _ink = PdfColor.fromInt(0xFF12161C);
  static const _inkSoft = PdfColor.fromInt(0xFF5A6472);
  static const _inkFaint = PdfColor.fromInt(0xFF98A1AE);
  static const _rule = PdfColor.fromInt(0xFFE2E6EC);
  static const _ruleSoft = PdfColor.fromInt(0xFFF1F3F6);
  static const _jade = PdfColor.fromInt(0xFF0A7F58);
  static const _jadeWash = PdfColor.fromInt(0xFFEDF7F2);
  static const _coral = PdfColor.fromInt(0xFFB3322C);
  static const _amber = PdfColor.fromInt(0xFF8A6212);
  static const _amberWash = PdfColor.fromInt(0xFFFCF6E8);
  static const _paper = PdfColor.fromInt(0xFFFFFFFF);

  // Inter carries U+20B9 and has tabular figures, so money columns line
  // up in print the same way they do on screen. Cached across builds —
  // a report is often exported several times in a row.
  static pw.Font? _regular;
  static pw.Font? _bold;

  static Future<pw.ThemeData> _theme() async {
    _regular ??= pw.Font.ttf(
        await rootBundle.load('assets/fonts/Inter-Regular.ttf'));
    _bold ??= pw.Font.ttf(
        await rootBundle.load('assets/fonts/Inter-SemiBold.ttf'));
    return pw.ThemeData.withFont(base: _regular!, bold: _bold!);
  }

  // ── Money ───────────────────────────────────────────────────────
  // Indian grouping: the last three digits, then pairs. 12,34,567.00,
  // never 1,234,567.00 — an accountant reads the wrong number off the
  // western grouping at a glance.
  static String _inr(double v, {bool symbol = true}) {
    final neg = v < 0;
    final parts = v.abs().toStringAsFixed(2).split('.');
    var integer = parts[0];
    if (integer.length > 3) {
      final last3 = integer.substring(integer.length - 3);
      final rest = integer.substring(0, integer.length - 3);
      final groups = <String>[];
      for (var i = rest.length; i > 0; i -= 2) {
        groups.insert(0, rest.substring(i < 2 ? 0 : i - 2, i));
      }
      integer = '${groups.join(',')},$last3';
    }
    return '${neg ? '-' : ''}${symbol ? '₹' : ''}$integer.${parts[1]}';
  }

  static String _dt(DateTime d) => DateFormat('d MMM yyyy').format(d);

  static String _period(DateTime from, DateTime to) =>
      '${_dt(from)} – ${_dt(to)}';

  // ═══════════════════════════════════════════════════════════════
  // SHARED PIECES
  // ═══════════════════════════════════════════════════════════════

  /// The masthead. Typography, not a coloured slab: the business name is
  /// the largest thing on the page because it is whose document this is,
  /// and a jade rule underneath does the work the blue block was doing.
  static pw.Widget _masthead(String title, DateTime from, DateTime to,
      Business? biz) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(title.toUpperCase(),
                      style: pw.TextStyle(
                          fontSize: 8,
                          color: _jade,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1.4)),
                  pw.SizedBox(height: 7),
                  pw.Text(biz?.name.isNotEmpty == true
                          ? biz!.name
                          : 'Your business',
                      style: pw.TextStyle(
                          fontSize: 22,
                          color: _ink,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: -0.4)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                      [
                        if ((biz?.gstin ?? '').isNotEmpty) 'GSTIN ${biz!.gstin}',
                        if ((biz?.city ?? '').isNotEmpty) biz!.city,
                      ].join('  ·  '),
                      style: const pw.TextStyle(fontSize: 9, color: _inkFaint)),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('BillZap',
                    style: pw.TextStyle(
                        fontSize: 12,
                        color: _ink,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: -0.2)),
                pw.SizedBox(height: 3),
                pw.Text('Generated ${_dt(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 8, color: _inkFaint)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 14),
        // A short jade rule, then a hairline across — the accent earns
        // its place by marking where the document starts, not by filling
        // a fifth of the page.
        pw.Row(children: [
          pw.Container(width: 46, height: 2.5, color: _jade),
          pw.Expanded(child: pw.Container(height: 0.6, color: _rule)),
        ]),
        pw.SizedBox(height: 10),
        pw.Text('Reporting period  ·  ${_period(from, to)}',
            style: const pw.TextStyle(fontSize: 9.5, color: _inkSoft)),
      ],
    );
  }

  /// One figure in the summary strip. Bordered, not filled: four filled
  /// pastel boxes in a row read as a dashboard screenshot rather than a
  /// document, and they photocopy badly.
  static pw.Widget _stat(String label, String value, {bool accent = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(11, 10, 11, 11),
      decoration: pw.BoxDecoration(
        color: accent ? _jadeWash : _paper,
        border: pw.Border.all(color: accent ? _jade : _rule, width: 0.7),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label.toUpperCase(),
              style: pw.TextStyle(
                  fontSize: 7,
                  color: accent ? _jade : _inkFaint,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 0.9)),
          pw.SizedBox(height: 6),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 13,
                  color: accent ? _jade : _ink,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: -0.3)),
        ],
      ),
    );
  }

  /// The summary strip. Fixed height rather than `stretch`, because a
  /// MultiPage lays its children out against an unbounded height and a
  /// stretched cross axis resolves to infinity there — the page then
  /// refuses to build at all.
  static pw.Widget _statRow(List<pw.Widget> cards) {
    final out = <pw.Widget>[];
    for (var i = 0; i < cards.length; i++) {
      if (i > 0) out.add(pw.SizedBox(width: 7));
      out.add(pw.Expanded(child: cards[i]));
    }
    return pw.SizedBox(
      height: 54,
      child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: out),
    );
  }

  static pw.Widget _section(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 20, bottom: 8),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 11,
                color: _ink,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: -0.1)),
      );

  /// A table without a grid.
  ///
  /// Ruling every cell puts more ink into the lines than the figures. A
  /// tinted header band, a rule under it, and hairlines between rows is
  /// enough structure to read a column down — and it stays legible on a
  /// fax, which is still how some of these get filed.
  static pw.Widget _table(
    List<String> headers,
    List<List<String>> rows, {
    List<int> numeric = const [],
    List<double>? widths,
    bool emphasiseLast = false,
  }) {
    pw.TextAlign align(int i) =>
        numeric.contains(i) ? pw.TextAlign.right : pw.TextAlign.left;

    final columnWidths = <int, pw.TableColumnWidth>{
      for (var i = 0; i < headers.length; i++)
        i: pw.FlexColumnWidth(widths != null && i < widths.length
            ? widths[i]
            : (i == 0 ? 1.6 : 1.0)),
    };

    return pw.Table(
      columnWidths: columnWidths,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: _ruleSoft,
            border: pw.Border(bottom: pw.BorderSide(color: _rule, width: 0.8)),
          ),
          children: [
            for (var i = 0; i < headers.length; i++)
              pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(9, 7, 9, 7),
                child: pw.Text(headers[i].toUpperCase(),
                    textAlign: align(i),
                    style: pw.TextStyle(
                        fontSize: 7,
                        color: _inkSoft,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.7)),
              ),
          ],
        ),
        for (var r = 0; r < rows.length; r++)
          pw.TableRow(
            decoration: const pw.BoxDecoration(
              border:
                  pw.Border(bottom: pw.BorderSide(color: _ruleSoft, width: 0.6)),
            ),
            children: [
              for (var i = 0; i < headers.length; i++)
                pw.Padding(
                  padding: const pw.EdgeInsets.fromLTRB(9, 7, 9, 7),
                  child: pw.Text(
                    i < rows[r].length ? rows[r][i] : '',
                    textAlign: align(i),
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: _ink,
                      fontWeight: (emphasiseLast && i == headers.length - 1) ||
                              i == 0
                          ? pw.FontWeight.bold
                          : pw.FontWeight.normal,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  /// A note. A left keyline rather than a filled yellow box — the reader
  /// should be able to skip it, and a highlighter block insists.
  static pw.Widget _note(String title, String body, {bool amber = true}) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 14),
      padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: pw.BoxDecoration(
        color: amber ? _amberWash : _jadeWash,
        border: pw.Border(
            left: pw.BorderSide(color: amber ? _amber : _jade, width: 2.5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            pw.Text(title.toUpperCase(),
                style: pw.TextStyle(
                    fontSize: 7,
                    color: amber ? _amber : _jade,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.9)),
            pw.SizedBox(height: 4),
          ],
          pw.Text(body,
              style: const pw.TextStyle(
                  fontSize: 8.5, color: _inkSoft, lineSpacing: 2)),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context ctx) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 18),
        padding: const pw.EdgeInsets.only(top: 9),
        decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: _rule, width: 0.6))),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Generated by BillZap',
                style: const pw.TextStyle(fontSize: 7.5, color: _inkFaint)),
            pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 7.5, color: _inkFaint)),
          ],
        ),
      );

  /// Every report is the same page: A4, generous margins, Inter, the
  /// masthead at the top and the rule-and-page-number at the bottom.
  static Future<pw.Document> _page({
    required String title,
    required DateTime from,
    required DateTime to,
    required Business? biz,
    required List<pw.Widget> body,
  }) async {
    final doc = pw.Document(theme: await _theme());
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(38, 38, 38, 30),
      footer: _footer,
      build: (_) => [
        _masthead(title, from, to, biz),
        pw.SizedBox(height: 20),
        ...body,
      ],
    ));
    return doc;
  }

  /// A label and its figure on one line, label quiet, figure in ink.
  static pw.Widget _kv(String label, String value) => pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text('$label  ',
              style: const pw.TextStyle(fontSize: 9, color: _inkSoft)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 9.5,
                  color: _ink,
                  fontWeight: pw.FontWeight.bold)),
        ],
      );

  static pw.Widget _empty(String text) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 6),
        child: pw.Text(text,
            style: const pw.TextStyle(fontSize: 9, color: _inkFaint)),
      );

  // ═══════════════════════════════════════════════════════════════
  // 1. MONTHLY REVENUE PDF
  // ═══════════════════════════════════════════════════════════════
  static Future<pw.Document> buildMonthlyRevenue({
    required List<Invoice> invoices,
    required DateTime from,
    required DateTime to,
    required Business? biz,
  }) async {
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

    return _page(
      title: 'Monthly Revenue',
      from: from,
      to: to,
      biz: biz,
      body: [
        _statRow([
          _stat('Total revenue', _inr(totalRevenue), accent: true),
          _stat('Invoices', '$invoiceCount'),
          _stat('Tax collected', _inr(totalTax)),
          _stat('Average invoice', _inr(avg.toDouble())),
        ]),
        _section('Month by month'),
        if (monthRows.isEmpty)
          _empty('No paid invoices in this period.')
        else
          _table(
            ['Month', 'Invoices', 'Taxable', 'Tax', 'Total'],
            monthRows.map((e) {
              final invs = e.value;
              final dt = DateFormat('yyyy-MM').parse(e.key);
              return [
                DateFormat('MMM yyyy').format(dt),
                '${invs.length}',
                _inr(invs.fold<double>(0, (s, i) => s + i.subtotal),
                    symbol: false),
                _inr(invs.fold<double>(0, (s, i) => s + i.totalTax),
                    symbol: false),
                _inr(invs.fold<double>(0, (s, i) => s + i.grandTotal)),
              ];
            }).toList(),
            numeric: const [1, 2, 3, 4],
            widths: const [1.4, 0.9, 1.2, 1.0, 1.3],
            emphasiseLast: true,
          ),
        _section('Your biggest customers'),
        if (topCusts.isEmpty)
          _empty('No customers billed in this period.')
        else
          _table(
            ['#', 'Customer', 'Invoices', 'Revenue'],
            topCusts.take(10).toList().asMap().entries.map((e) {
              final total =
                  e.value.value.fold<double>(0, (s, i) => s + i.grandTotal);
              return [
                '${e.key + 1}',
                e.value.key,
                '${e.value.value.length}',
                _inr(total),
              ];
            }).toList(),
            numeric: const [2, 3],
            widths: const [0.4, 3.0, 1.0, 1.4],
            emphasiseLast: true,
          ),
      ],
    );
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

    return _page(
      title: 'Profit & Loss',
      from: from,
      to: to,
      biz: biz,
      body: [
        // The one number the reader opened this for. It gets the width
        // of the page and the only large type on it.
        pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: pw.BoxDecoration(
            color: isProfit ? _jadeWash : _paper,
            border: pw.Border.all(
                color: isProfit ? _jade : _coral, width: 0.9),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(isProfit ? 'NET PROFIT' : 'NET LOSS',
                      style: pw.TextStyle(
                          fontSize: 8,
                          color: isProfit ? _jade : _coral,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1.2)),
                  pw.SizedBox(height: 6),
                  pw.Text(_inr(profit.abs()),
                      style: pw.TextStyle(
                          fontSize: 28,
                          color: isProfit ? _jade : _coral,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: -0.9)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _kv('Revenue', _inr(revenue)),
                  pw.SizedBox(height: 5),
                  _kv('Less expenses', _inr(expTotal)),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        _statRow([
          _stat('Total revenue', _inr(revenue)),
          _stat('Total expenses', _inr(expTotal)),
          _stat('Paid invoices', '${paidInvs.length}'),
          _stat('Expense records', '${periodExps.length}'),
        ]),
        _section('Where the money went'),
        if (sortedCats.isEmpty)
          _empty('No expenses recorded in this period.')
        else
          _table(
            ['Category', 'Entries', 'Amount', 'Share'],
            sortedCats.map((e) {
              final sum = e.value.fold<double>(0, (s, x) => s + x.amount);
              final pct = expTotal > 0 ? (sum / expTotal * 100) : 0;
              return [
                e.key,
                '${e.value.length}',
                _inr(sum),
                '${pct.toStringAsFixed(1)}%',
              ];
            }).toList(),
            numeric: const [1, 2, 3],
            widths: const [2.4, 0.9, 1.4, 0.9],
          ),
        _note(
          'How this is calculated',
          'Cash basis: only invoices you have marked paid count as '
          'revenue. Invoices still pending are excluded until they are '
          'settled, so this figure tracks money actually received.',
        ),
      ],
    );
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

    return _page(
      title: 'GST Summary',
      from: from,
      to: to,
      biz: biz,
      body: [
        _statRow([
          _stat('Taxable value', _inr(totalTaxable)),
          _stat('Total GST', _inr(totalGst), accent: true),
          _stat('CGST + SGST', _inr(totalCgst + totalSgst)),
          _stat('IGST', _inr(totalIgst)),
        ]),
        _section('Month by month, for GSTR-1'),
        if (monthEntries.isEmpty)
          _empty('No paid invoices in this period.')
        else
          _table(
            ['Month', 'Inv', 'Taxable', 'CGST', 'SGST', 'IGST', 'Total tax'],
            monthEntries.map((e) {
              final invs = e.value;
              final dt = DateFormat('yyyy-MM').parse(e.key);
              final taxable = invs.fold<double>(0, (s, i) => s + i.subtotal);
              final c = invs.fold<double>(0, (s, i) => s + i.totalCgst);
              final sg = invs.fold<double>(0, (sum, i) => sum + i.totalSgst);
              final ig = invs.fold<double>(0, (sum, i) => sum + i.totalIgst);
              return [
                DateFormat('MMM yyyy').format(dt),
                '${invs.length}',
                _inr(taxable, symbol: false),
                _inr(c, symbol: false),
                _inr(sg, symbol: false),
                _inr(ig, symbol: false),
                _inr(c + sg + ig),
              ];
            }).toList(),
            numeric: const [1, 2, 3, 4, 5, 6],
            widths: const [1.2, 0.5, 1.2, 1.0, 1.0, 1.0, 1.3],
            emphasiseLast: true,
          ),
        _note(
          'Before you file',
          'GSTR-1 is due by the 11th of each month, GSTR-3B by the 20th. '
          'Treat this as supporting data and check it against your books '
          'with your accountant before filing.',
        ),
      ],
    );
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

    final outstandingTotal =
        outstanding.fold<double>(0, (s, i) => s + i.grandTotal);

    return _page(
      title: 'Invoice Status',
      from: from,
      to: to,
      biz: biz,
      body: [
        _statRow([
          _stat('Still owed', _inr(outstandingTotal),
              accent: outstandingTotal > 0),
          _stat('Paid', '$paidCount'),
          _stat('Pending', '$pendingCount'),
          _stat('Overdue', '$overdueCount'),
        ]),
        _section('By status'),
        _table(
          ['Status', 'Count', 'Amount'],
          [
            ['Paid', '$paidCount', _inr(paidAmt)],
            ['Pending', '$pendingCount', _inr(pendingAmt)],
            ['Overdue', '$overdueCount', _inr(overdueAmt)],
            ['Cancelled', '$cancelledCount', _inr(cancelledAmt)],
            ['Draft', '$draftCount', _inr(draftAmt)],
          ],
          numeric: const [1, 2],
          widths: const [2.0, 1.0, 1.6],
          emphasiseLast: true,
        ),
        _section('How long it has been owed'),
        _table(
          ['Age', 'Invoices', 'Outstanding'],
          agingBuckets.entries.map((e) {
            final amt = e.value.fold<double>(0, (s, i) => s + i.grandTotal);
            return [e.key, '${e.value.length}', _inr(amt)];
          }).toList(),
          numeric: const [1, 2],
          widths: const [2.0, 1.0, 1.6],
          emphasiseLast: true,
        ),
        if (outstanding.isNotEmpty) ...[
          _section('Who to chase, oldest first'),
          _table(
            ['Invoice', 'Customer', 'Due', 'Days late', 'Amount'],
            outstanding.take(50).map((inv) {
              final late = now.difference(inv.dueDate).inDays;
              return [
                inv.invoiceNumber,
                inv.customerName,
                _dt(inv.dueDate),
                late > 0 ? '$late' : '\u2014',
                _inr(inv.grandTotal),
              ];
            }).toList(),
            numeric: const [3, 4],
            widths: const [1.3, 2.2, 1.2, 0.9, 1.4],
            emphasiseLast: true,
          ),
          if (outstanding.length > 50)
            _note(
              '',
              'Showing the 50 oldest of ${outstanding.length} outstanding '
              'invoices. Export the CSV for the full list.',
            ),
        ],
      ],
    );
  }
}
