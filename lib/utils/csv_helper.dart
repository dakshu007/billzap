// lib/utils/csv_helper.dart
// Generates Excel-compatible CSVs with UTF-8 BOM (so Hindi/Tamil display correctly).
// Indian number format & DD-MM-YYYY date convention.

import 'package:intl/intl.dart';
import '../models/models.dart';

class CsvHelper {
  static const _bom = '\uFEFF';  // UTF-8 BOM, makes Excel detect UTF-8 properly

  /// Escape a single CSV cell — handles quotes, commas, newlines.
  static String _esc(String value) {
    final needsQuoting = value.contains(',') || value.contains('"') ||
                         value.contains('\n') || value.contains('\r');
    if (needsQuoting) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Indian number format: 1,23,456.78
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

  /// Builds a CSV line from a list of cells.
  static String _row(List<String> cells) =>
      cells.map(_esc).join(',') + '\r\n';

  // ═══════════════════════════════════════════════════════════════
  // 1. ALL INVOICES CSV
  // ═══════════════════════════════════════════════════════════════
  static String invoicesToCsv(List<Invoice> invoices) {
    final buf = StringBuffer(_bom);
    buf.write(_row([
      'Invoice Number', 'Date', 'Due Date', 'Customer', 'Customer Phone',
      'Customer GSTIN', 'Subtotal', 'CGST', 'SGST', 'IGST',
      'Shipping', 'Discount', 'Grand Total', 'Status', 'Place of Supply',
      'Notes',
    ]));

    for (final inv in invoices) {
      String status = inv.status.name;
      if (inv.isOverdue) status = 'overdue';

      buf.write(_row([
        inv.invoiceNumber,
        _dt(inv.invoiceDate),
        _dt(inv.dueDate),
        inv.customerName,
        inv.customerPhone,
        inv.customerGstin,
        _inrNum(inv.subtotal),
        _inrNum(inv.totalCgst),
        _inrNum(inv.totalSgst),
        _inrNum(inv.totalIgst),
        _inrNum(inv.shippingCharge),
        _inrNum(inv.flatDiscount),
        _inrNum(inv.grandTotal),
        status.toUpperCase(),
        inv.placeOfSupply,
        inv.notes,
      ]));
    }
    return buf.toString();
  }

  // ═══════════════════════════════════════════════════════════════
  // 2. GST SUMMARY CSV (month-wise, ready for GSTR-1)
  // ═══════════════════════════════════════════════════════════════
  static String gstSummaryToCsv(List<Invoice> invoices) {
    final buf = StringBuffer(_bom);

    // Group by month
    final byMonth = <String, List<Invoice>>{};
    for (final inv in invoices) {
      if (inv.status != InvoiceStatus.paid) continue;
      final key = DateFormat('yyyy-MM').format(inv.invoiceDate);
      byMonth.putIfAbsent(key, () => []).add(inv);
    }

    // Sort months descending
    final sortedKeys = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));

    buf.write(_row([
      'Month', 'Invoice Count', 'Taxable Value',
      'CGST', 'SGST', 'IGST', 'Total Tax', 'Total Sales (Inc Tax)',
    ]));

    for (final key in sortedKeys) {
      final invs = byMonth[key]!;
      final taxable = invs.fold<double>(0, (s, i) => s + i.subtotal);
      final cgst = invs.fold<double>(0, (s, i) => s + i.totalCgst);
      final sgst = invs.fold<double>(0, (s, i) => s + i.totalSgst);
      final igst = invs.fold<double>(0, (s, i) => s + i.totalIgst);
      final tax = cgst + sgst + igst;
      final total = invs.fold<double>(0, (s, i) => s + i.grandTotal);

      // Display month name
      final parts = key.split('-');
      final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      final monthDisplay = DateFormat('MMMM yyyy').format(dt);

      buf.write(_row([
        monthDisplay,
        '${invs.length}',
        _inrNum(taxable),
        _inrNum(cgst),
        _inrNum(sgst),
        _inrNum(igst),
        _inrNum(tax),
        _inrNum(total),
      ]));
    }
    return buf.toString();
  }

  // ═══════════════════════════════════════════════════════════════
  // 3. CUSTOMERS CSV (with totals)
  // ═══════════════════════════════════════════════════════════════
  static String customersToCsv(List<Customer> customers, List<Invoice> invoices) {
    final buf = StringBuffer(_bom);
    buf.write(_row([
      'Name', 'Phone', 'Email', 'GSTIN', 'Address', 'City', 'State',
      'Total Invoices', 'Total Billed', 'Total Paid', 'Outstanding',
      'Created Date',
    ]));

    for (final c in customers) {
      final myInvs = invoices.where((i) => i.customerName == c.name).toList();
      final billed = myInvs.fold<double>(0, (s, i) => s + i.grandTotal);
      final paid = myInvs
          .where((i) => i.status == InvoiceStatus.paid)
          .fold<double>(0, (s, i) => s + i.grandTotal);

      buf.write(_row([
        c.name, c.phone, c.email, c.gstin,
        c.address, c.city, c.state,
        '${myInvs.length}',
        _inrNum(billed), _inrNum(paid), _inrNum(billed - paid),
        _dt(c.createdAt),
      ]));
    }
    return buf.toString();
  }

  // ═══════════════════════════════════════════════════════════════
  // 4. EXPENSES CSV
  // ═══════════════════════════════════════════════════════════════
  static String expensesToCsv(List<Expense> expenses) {
    final buf = StringBuffer(_bom);
    buf.write(_row([
      'Date', 'Category', 'Title', 'Amount', 'Payment Mode',
    ]));
    for (final e in expenses) {
      buf.write(_row([
        _dt(e.date), e.category, e.title,
        _inrNum(e.amount), e.paymentMode,
      ]));
    }
    return buf.toString();
  }
}
