// test/invoice_labels_test.dart — what a bill says about how to pay it.
//
// A shop set to Albania showed a UPI QR asking for ₹46.02 under a
// L46.02 invoice. UPI moves rupees between Indian accounts and nothing
// else, so the QR, the "Pay to UPI" line and the WhatsApp UPI link
// belong on rupee invoices only — decided by the invoice's own country,
// because a bill keeps the currency it was issued in.

import 'package:flutter_test/flutter_test.dart';
import 'package:billzap/models/models.dart';
import 'package:billzap/utils/invoice_labels.dart';

Invoice _inv(String country) => Invoice(
      invoiceNumber: 'INV-1',
      customerName: 'A',
      invoiceDate: DateTime(2026, 10, 7),
      dueDate: DateTime(2026, 11, 6),
      lineItems: const [],
      taxCountryCode: country,
    );

void main() {
  test('UPI only on rupee invoices', () {
    expect(upiApplies(_inv('IN')), isTrue);
    for (final c in ['AL', 'AE', 'US', 'GB', 'KE', 'XX']) {
      expect(upiApplies(_inv(c)), isFalse, reason: c);
    }
  });

  test('the bank code is called IFSC only in India', () {
    expect(bankCodeLabel(_inv('IN')), 'IFSC');
    expect(bankCodeLabel(_inv('AL')), isNot('IFSC'));
  });

  test('a business logo survives a save and a restore', () {
    final b = Business(name: 'Ravi', logoBase64: 'iVBORw0KGgo=');
    final back = Business.fromMap(b.toMap());
    expect(back.logoBase64, 'iVBORw0KGgo=');
    // A profile saved before the field existed has no logo, not a crash.
    final old = b.toMap()..remove('logoBase64');
    expect(Business.fromMap(old).logoBase64, '');
    // Removing it is an empty string, which copyWith can express.
    expect(b.copyWith(logoBase64: '').logoBase64, '');
  });

  group('the bill heading follows the tax on it', () {
    Invoice bill({required bool taxed, String country = 'IN'}) => Invoice(
          invoiceNumber: 'INV-1',
          customerName: 'A',
          invoiceDate: DateTime(2026, 10, 7),
          dueDate: DateTime(2026, 11, 6),
          taxCountryCode: country,
          lineItems: [
            InvoiceItem(name: 'Rice', quantity: 1, rate: 100, gstRate: 5,
                applyGst: taxed),
          ],
        );
    Business shop(String gstin) => Business(name: 'Shop', gstin: gstin);

    test('a bill that charges GST is a tax invoice', () {
      expect(documentTitle(bill(taxed: true), shop('33ABCDE1234F1Z5')),
          'Tax Invoice');
    });
    test('a registered shop billing without tax issues a bill of supply', () {
      expect(documentTitle(bill(taxed: false), shop('33ABCDE1234F1Z5')),
          'Bill of Supply');
    });
    test('an unregistered shop never prints "tax invoice"', () {
      expect(documentTitle(bill(taxed: false), shop('')), 'Bill');
      expect(documentTitle(bill(taxed: false), null), 'Bill');
    });
    test('outside India a bill with no tax is an invoice', () {
      expect(documentTitle(bill(taxed: false, country: 'AE'), shop('')),
          'Invoice');
    });
  });
}

