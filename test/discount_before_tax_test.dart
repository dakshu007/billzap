// test/discount_before_tax_test.dart — a discount on the bill lowers the
// GST, and old invoices keep the totals they were issued with.
//
// Section 15(3)(a) of the CGST Act: a discount given before or at the
// time of supply and shown on the invoice is not part of the value tax
// is charged on. BillZap used to take it off after tax, so the customer
// paid GST on money they never paid. New bills now discount first; the
// flag defaults to off so every invoice already saved reads back the same.

import 'package:flutter_test/flutter_test.dart';
import 'package:billzap/models/models.dart';

Invoice _bill(List<InvoiceItem> items,
    {double discount = 0,
    double shipping = 0,
    bool beforeTax = true,
    GstType type = GstType.cgstSgst}) {
  final d = DateTime.utc(2026, 10, 18);
  return Invoice(
    invoiceNumber: 'T-1',
    customerName: 'Test',
    invoiceDate: d,
    dueDate: d,
    lineItems: items,
    gstType: type,
    flatDiscount: discount,
    shippingCharge: shipping,
    discountBeforeTax: beforeTax,
  );
}

void main() {
  test('single rate: ₹1,000 at 18% less ₹100 is ₹900 + ₹162 GST', () {
    final inv = _bill(
        [InvoiceItem(name: 'Fan', quantity: 1, rate: 1000, gstRate: 18)],
        discount: 100);
    expect(inv.subtotal, 1000);
    expect(inv.taxableValue, closeTo(900, 1e-9));
    expect(inv.totalTax, closeTo(162, 1e-9));
    expect(inv.totalCgst, closeTo(81, 1e-9));
    expect(inv.totalSgst, closeTo(81, 1e-9));
    expect(inv.grandTotal, closeTo(1062, 1e-9));
  });

  test('mixed 5% and 18% lines share the discount in proportion', () {
    // ₹600 of rice at 5%, ₹400 of bulbs at 18%; ₹100 off is 10% of
    // each line: ₹540 at 5% (₹27) and ₹360 at 18% (₹64.80).
    final inv = _bill([
      InvoiceItem(name: 'Rice', quantity: 1, rate: 600, gstRate: 5),
      InvoiceItem(name: 'Bulb', quantity: 4, rate: 100, gstRate: 18),
    ], discount: 100);
    expect(inv.lineTaxable(inv.lineItems[0]), closeTo(540, 1e-9));
    expect(inv.lineTaxable(inv.lineItems[1]), closeTo(360, 1e-9));
    expect(inv.totalTax, closeTo(91.80, 1e-9));
    expect(inv.grandTotal, closeTo(991.80, 1e-9));
  });

  test('inter-state puts the whole reduced tax on IGST', () {
    final inv = _bill(
        [InvoiceItem(name: 'Fan', quantity: 1, rate: 1000, gstRate: 18)],
        discount: 100,
        type: GstType.igst);
    expect(inv.totalIgst, closeTo(162, 1e-9));
    expect(inv.totalCgst, 0);
    expect(inv.totalSgst, 0);
  });

  test('shipping is added after tax and does not move the discount', () {
    final inv = _bill(
        [InvoiceItem(name: 'Fan', quantity: 1, rate: 1000, gstRate: 18)],
        discount: 100,
        shipping: 50);
    expect(inv.grandTotal, closeTo(1112, 1e-9));
  });

  test('no discount: before and after give the same bill', () {
    final items = [
      InvoiceItem(name: 'Rice', quantity: 3, rate: 649, gstRate: 5),
      InvoiceItem(name: 'Bulb', quantity: 2, rate: 90, gstRate: 18),
    ];
    final a = _bill(items, beforeTax: true);
    final b = _bill(items, beforeTax: false);
    expect(a.totalTax, b.totalTax);
    expect(a.grandTotal, b.grandTotal);
  });

  test('a discount bigger than the bill floors at zero, never negative', () {
    final inv = _bill(
        [InvoiceItem(name: 'Pen', quantity: 1, rate: 10, gstRate: 18)],
        discount: 50);
    expect(inv.taxableValue, 0);
    expect(inv.totalTax, 0);
    expect(inv.grandTotal, 0);
  });

  test('invoices saved before the flag existed keep their totals', () {
    final legacy = Invoice.fromMap({
      'invoiceNumber': 'OLD-1',
      'customerName': 'Old',
      'lineItems': [
        {'name': 'Fan', 'quantity': 1, 'rate': 1000, 'gstRate': 18},
      ],
      'flatDiscount': 100,
    });
    expect(legacy.discountBeforeTax, isFalse);
    expect(legacy.totalTax, 180);
    expect(legacy.grandTotal, 1080);
  });

  test('the flag survives a save and reload', () {
    final inv = _bill(
        [InvoiceItem(name: 'Fan', quantity: 1, rate: 1000, gstRate: 18)],
        discount: 100);
    final back = Invoice.fromMap(inv.toMap());
    expect(back.discountBeforeTax, isTrue);
    expect(back.grandTotal, inv.grandTotal);
  });
}
