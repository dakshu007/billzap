// Renders each report to a real PDF on disk so the layout can be looked
// at, rather than assumed. Not a CI assertion — a proofing harness.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:billzap/models/models.dart';
import 'package:billzap/utils/report_pdf_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final biz = Business(
    name: 'Daksha Stores',
    gstin: '33RAAAA1234B1Z5',
    phone: '8778481650',
    email: 'daksheshbabu@gmail.com',
    address: '7 377 T.Manihatty village and post',
    city: 'Coimbatore',
    state: 'Tamil Nadu',
    stateCode: '33',
    pincode: '643214',
  );

  Invoice inv(String no, String cust, double rate, DateTime date,
      InvoiceStatus st, {DateTime? due}) {
    return Invoice(
      invoiceNumber: no,
      customerName: cust,
      invoiceDate: date,
      dueDate: due ?? date.add(const Duration(days: 30)),
      status: st,
      lineItems: [
        InvoiceItem(name: 'Goods', quantity: 1, rate: rate, gstRate: 18),
      ],
    );
  }

  final now = DateTime(2026, 9, 16);
  final invoices = [
    inv('INV-1001', 'Kumar', 360, DateTime(2026, 9, 2), InvoiceStatus.paid),
    inv('INV-1002', 'Meenakshi Stores', 41200, DateTime(2026, 8, 14),
        InvoiceStatus.paid),
    inv('INV-1003', 'Sundaram Traders', 128000, DateTime(2026, 7, 22),
        InvoiceStatus.paid),
    inv('INV-1004', 'Selvam & Sons', 76500, DateTime(2026, 8, 1),
        InvoiceStatus.sent, due: DateTime(2026, 8, 20)),
    inv('INV-1005', 'Anand Textiles', 19800, DateTime(2026, 6, 9),
        InvoiceStatus.sent, due: DateTime(2026, 6, 30)),
    inv('INV-1006', 'Priya Agencies', 8400, DateTime(2026, 9, 10),
        InvoiceStatus.sent, due: DateTime(2026, 10, 10)),
  ];

  final expenses = [
    Expense(title: 'Shop rent', amount: 18000, category: 'Rent', date: DateTime(2026, 9, 1)),
    Expense(title: 'Staff salary', amount: 32000, category: 'Salary', date: DateTime(2026, 9, 1)),
    Expense(title: 'Electricity', amount: 4250, category: 'Utilities', date: DateTime(2026, 8, 28)),
    Expense(title: 'Transport', amount: 2800, category: 'Travel', date: DateTime(2026, 8, 12)),
  ];

  final from = DateTime(2026, 6, 1);
  final to = DateTime(2026, 9, 30);

  Future<void> write(String name, Future<dynamic> Function() build) async {
    final doc = await build();
    final bytes = await doc.save();
    final f = File('/tmp/pdftest/$name.pdf')..writeAsBytesSync(bytes);
    // ignore: avoid_print
    print('wrote ${f.path} (${bytes.length} bytes)');
  }

  test('renders all four reports', () async {
    await write('revenue', () => ReportPdfBuilder.buildMonthlyRevenue(
        invoices: invoices, from: from, to: to, biz: biz));
    await write('pl', () => ReportPdfBuilder.buildProfitLoss(
        invoices: invoices, expenses: expenses, from: from, to: to, biz: biz));
    await write('gst', () => ReportPdfBuilder.buildGstSummary(
        invoices: invoices, from: from, to: to, biz: biz));
    await write('status', () => ReportPdfBuilder.buildInvoiceStatus(
        invoices: invoices, from: from, to: to, biz: biz));
    expect(now.year, 2026);
  });
}
