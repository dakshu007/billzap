// test/invoice_tax_split_test.dart
//
// The Invoice model used to hardcode India: totalTax halved into CGST
// and SGST, or all of it as IGST, with no third possibility. Making it
// carry its own split is the change that lets the app bill anywhere —
// and it is also the change most able to quietly alter somebody's
// existing invoices.
//
// So the first half of this file is not about new countries at all. It
// asserts that an invoice saved before the field existed reads back
// exactly as it always did, because a reprint of a filed bill that
// disagrees with the filed copy is the worst bug a billing app has.

import 'package:flutter_test/flutter_test.dart';
import 'package:billzap/design/money.dart';
import 'package:billzap/models/models.dart';

Invoice _bill({
  double rate = 18,
  GstType type = GstType.cgstSgst,
  Map<String, double> components = const {},
  String country = 'IN',
  String symbol = '',
  double shipping = 0,
  double discount = 0,
}) =>
    Invoice(
      invoiceNumber: 'INV-1',
      customerName: 'Test',
      invoiceDate: DateTime.utc(2026, 1, 1),
      dueDate: DateTime.utc(2026, 1, 31),
      lineItems: [
        InvoiceItem(name: 'Thing', quantity: 1, rate: 1000, gstRate: rate),
      ],
      gstType: type,
      taxComponents: components,
      taxCountryCode: country,
      currencySymbol: symbol,
      shippingCharge: shipping,
      flatDiscount: discount,
    );

void main() {
  group('an invoice saved before the split existed', () {
    test('intra-state still halves into CGST and SGST', () {
      final inv = _bill();
      expect(inv.totalTax, 180);
      expect(inv.totalCgst, 90);
      expect(inv.totalSgst, 90);
      expect(inv.totalIgst, 0);
    });

    test('inter-state is still all IGST', () {
      final inv = _bill(type: GstType.igst);
      expect(inv.totalCgst, 0);
      expect(inv.totalSgst, 0);
      expect(inv.totalIgst, 180);
    });

    test('a zero-tax bill prints no tax row at all', () {
      final inv = _bill(rate: 0);
      expect(inv.totalTax, 0);
      expect(inv.taxSplit, isEmpty);
      expect(inv.taxRows, isEmpty);
    });

    test('the rows carry the halved rate, not the whole one', () {
      final rows = _bill().taxRows;
      expect(rows.map((r) => r.label), ['CGST', 'SGST']);
      // 9.0, not 9 — these are the exact strings the preview and the
      // PDF have always printed, and 0.5 is exact in binary so this
      // cannot drift.
      expect(rows.map((r) => '${r.label} ${r.rate}%'),
          ['CGST 9.0%', 'SGST 9.0%']);
      expect(rows.map((r) => r.amount), [90.0, 90.0]);
    });

    test('an inter-state row carries the whole rate', () {
      expect(_bill(type: GstType.igst).taxRows.single.rate, 18.0);
    });

    test('a map written by the old build loads with India defaults', () {
      // Exactly the keys the previous version wrote — no country, no
      // components, no symbol.
      final inv = Invoice.fromMap({
        'invoiceNumber': 'INV-OLD',
        'customerName': 'Legacy',
        'invoiceDate': '2025-06-01T00:00:00.000Z',
        'dueDate': '2025-07-01T00:00:00.000Z',
        'lineItems': [
          {'name': 'Thing', 'quantity': 1, 'rate': 1000, 'gstRate': 18},
        ],
        'gstType': 'cgstSgst',
        'status': 'sent',
      });
      expect(inv.taxCountryCode, 'IN');
      expect(inv.taxComponents, isEmpty);
      expect(inv.currencySymbol, '');
      expect(inv.totalCgst, 90);
      expect(inv.totalSgst, 90);
    });
  });

  group('an invoice billed somewhere else', () {
    test('prints the one tax line that country names', () {
      final inv = _bill(
          rate: 5,
          components: const {'VAT': 50},
          country: 'AE',
          symbol: 'AED ');
      expect(inv.taxSplit, {'VAT': 50.0});
      expect(inv.totalCgst, 0, reason: 'a Dubai bill has no CGST on it');
      expect(inv.totalSgst, 0);
      expect(inv.totalIgst, 0);
      final row = inv.taxRows.single;
      expect(row.label, 'VAT');
      expect(row.rate, 5.0);
      expect(row.amount, 50.0);
    });

    test('a stored split wins over the India fallback', () {
      // Same gstType as an Indian bill, but the components say
      // otherwise. The snapshot is the record; the enum is not.
      final inv = _bill(components: const {'Sales Tax': 180});
      expect(inv.taxSplit.keys, ['Sales Tax']);
      expect(inv.totalCgst, 0);
    });

    test('the components round-trip through storage', () {
      final inv = _bill(
          rate: 7.5,
          components: const {'Consumption Tax': 75},
          country: 'JP',
          symbol: '¥');
      final back = Invoice.fromMap(inv.toMap());
      expect(back.taxComponents, {'Consumption Tax': 75.0});
      expect(back.taxCountryCode, 'JP');
      expect(back.currencySymbol, '¥');
      expect(back.taxRows.single.label, 'Consumption Tax');
    });

    test('a two-part split anywhere adds back up to the tax', () {
      final inv = _bill(components: const {'State Tax': 120, 'City Tax': 60});
      expect(inv.taxRows.fold<double>(0, (s, r) => s + r.amount),
          closeTo(inv.totalTax, 1e-9));
      expect(inv.taxRows.fold<double>(0, (s, r) => s + r.rate),
          closeTo(18, 1e-9));
    });
  });

  group('the zero-tax reporting bug', () {
    // Three reports — the Reports screen, the CSV summary and the PDF
    // — each computed total tax as totalCgst + totalSgst + totalIgst.
    // That is correct in India and silently zero everywhere else, on
    // documents headed "Tax Summary". These assert the invariant that
    // makes any such sum wrong, so the next person who writes one has
    // a failing test rather than a plausible-looking report.
    test('the India getters do not add up to the tax outside India', () {
      final inv = _bill(rate: 5, components: const {'VAT': 50}, country: 'AE');
      expect(inv.totalTax, 50);
      expect(inv.totalCgst + inv.totalSgst + inv.totalIgst, 0,
          reason: 'this is exactly why that sum must not be used');
      expect(inv.totalTax, isNot(0),
          reason: 'the tax is real; only the India names are empty');
    });

    test('they do add up to it in India, which is why it went unnoticed',
        () {
      final inv = _bill();
      expect(inv.totalCgst + inv.totalSgst + inv.totalIgst, inv.totalTax);
    });

    test('the split always adds back up to the tax, in any country', () {
      for (final components in [
        const <String, double>{},
        const {'VAT': 180.0},
        const {'CGST': 90.0, 'SGST': 90.0},
        const {'State Tax': 100.0, 'City Tax': 80.0},
      ]) {
        final inv = _bill(components: components);
        expect(inv.taxSplit.values.fold<double>(0, (s, v) => s + v),
            closeTo(inv.totalTax, 1e-9),
            reason: 'components: $components');
      }
    });
  });

  group('a stored amount keeps its own currency', () {
    tearDown(() => setActiveCurrency(
        symbol: '₹', grouping: MoneyGrouping.indian));

    test('an Indian bill reprints in lakhs after the shop moves abroad', () {
      // The shop is now set to dollars and western grouping...
      setActiveCurrency(symbol: r'$', grouping: MoneyGrouping.western);
      // ...but last year's rupee bill is still a rupee bill.
      expect(
          formatStoredMoney(1234567, symbol: '', countryCode: 'IN'),
          '₹12,34,567.00');
    });

    test('a foreign bill reprints in threes after the shop moves to India',
        () {
      setActiveCurrency(
          symbol: '₹', grouping: MoneyGrouping.indian);
      expect(
          formatStoredMoney(1234567, symbol: r'$', countryCode: 'US'),
          r'$1,234,567.00');
    });

    test('an empty stored symbol means the rupee, as every old bill was', () {
      expect(formatStoredMoney(100, symbol: '', countryCode: 'IN'),
          '₹100.00');
    });

    test('a negative stored amount keeps the sign outside the symbol', () {
      expect(formatStoredMoney(-250, symbol: r'$', countryCode: 'US'),
          r'-$250.00');
    });

    test('South Asia is not only India', () {
      // Lakh and crore are the everyday units in Dhaka and Karachi too.
      for (final code in ['IN', 'PK', 'BD', 'NP', 'LK', 'BT']) {
        expect(groupingForCountry(code), MoneyGrouping.indian,
            reason: '$code groups the South Asian way');
      }
      for (final code in ['US', 'GB', 'AE', 'KE', 'JP']) {
        expect(groupingForCountry(code), MoneyGrouping.western,
            reason: '$code groups in threes');
      }
    });
  });
}
