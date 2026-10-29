// test/invoice_terms_test.dart — the shop's default terms reach new bills.
//
// The setting used to be saved and never read, so a shop that changed
// its terms still printed the old text on every bill. A bill already
// issued, though, must reprint exactly as it was handed over.

import 'package:flutter_test/flutter_test.dart';
import 'package:billzap/models/models.dart';

Invoice _newBill(Business? biz) => Invoice(
      invoiceNumber: 'INV-1001',
      customerName: 'Ravi',
      invoiceDate: DateTime(2026, 10, 1),
      dueDate: DateTime(2026, 10, 31),
      lineItems: [InvoiceItem(name: 'Rice', quantity: 1, rate: 100, gstRate: 5)],
      terms: Invoice.termsFor(biz),
    );

void main() {
  test('custom default terms appear on a new invoice', () {
    final biz = Business(name: 'Shop', defaultTerms: 'Payment due on delivery.');
    expect(_newBill(biz).terms, 'Payment due on delivery.');
  });

  test('blank or missing default terms fall back to the standard text', () {
    expect(Invoice.termsFor(Business(name: 'Shop', defaultTerms: '   ')),
        kDefaultInvoiceTerms);
    expect(Invoice.termsFor(null), kDefaultInvoiceTerms);
  });

  test('an existing invoice keeps its own terms after the setting changes', () {
    final biz = Business(name: 'Shop', defaultTerms: 'Net 15.');
    final saved = _newBill(biz).toMap();

    biz.defaultTerms = 'Payment due on delivery.';
    final reloaded = Invoice.fromMap(saved);

    expect(reloaded.terms, 'Net 15.');
    expect(_newBill(biz).terms, 'Payment due on delivery.');
  });
}
