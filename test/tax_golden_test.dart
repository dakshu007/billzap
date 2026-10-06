// test/tax_golden_test.dart — the new engine must not move anybody's money.
//
// lib/tax/ is a refactor of arithmetic that is already in production and
// already on shopkeepers' invoices. The only acceptable outcome is that
// it computes exactly what lib/models/models.dart computes. Not "close
// enough", not "cleaner and roughly the same" — identical, because a
// bill that changes by a paisa after an update is a support call at best
// and a filing error at worst.
//
// So this walks a spread of real-shaped bills through both paths and
// asserts they agree bit for bit. If this file ever fails, the engine is
// wrong and the model is right, not the other way round.

import 'package:flutter_test/flutter_test.dart';
import 'package:billzap/models/models.dart';
import 'package:billzap/tax/tax_engine.dart';
import 'package:billzap/tax/tax_profile.dart';
import 'package:billzap/tax/profiles.dart';

/// Bills chosen to cover what actually goes wrong: a single line, mixed
/// slabs, an exempt line, fractional quantities, the 0.25% stone rate,
/// a long bill where rounding error would accumulate, and amounts big
/// enough to lose precision in a double.
final _cases = <String, List<InvoiceItem>>{
  'single 18% line': [
    InvoiceItem(name: 'Cable', quantity: 1, rate: 1000, gstRate: 18),
  ],
  'mixed slabs': [
    InvoiceItem(name: 'Rice', quantity: 2, rate: 60, gstRate: 5),
    InvoiceItem(name: 'Fan', quantity: 1, rate: 2400, gstRate: 18),
    InvoiceItem(name: 'Cola', quantity: 6, rate: 40, gstRate: 28),
  ],
  'exempt line alongside taxed': [
    InvoiceItem(name: 'Milk', quantity: 3, rate: 28, gstRate: 0),
    InvoiceItem(
        name: 'Gift wrap', quantity: 1, rate: 15, gstRate: 18, applyGst: false),
    InvoiceItem(name: 'Soap', quantity: 4, rate: 45, gstRate: 18),
  ],
  'fractional quantity': [
    InvoiceItem(name: 'Wire', quantity: 2.5, rate: 133.33, gstRate: 18),
    InvoiceItem(name: 'Sugar', quantity: 0.75, rate: 52, gstRate: 5),
  ],
  'the 0.25% stone rate': [
    InvoiceItem(name: 'Rough diamond', quantity: 1, rate: 125000, gstRate: 0.25),
  ],
  'the 40% rate': [
    InvoiceItem(name: 'Luxury item', quantity: 1, rate: 50000, gstRate: 40),
  ],
  'a thirty line bill': [
    for (var i = 1; i <= 30; i++)
      InvoiceItem(
        name: 'Item $i',
        quantity: i.toDouble(),
        rate: 19.99 + i,
        gstRate: const [0.0, 5.0, 12.0, 18.0, 28.0][i % 5],
      ),
  ],
  'amounts large enough to strain a double': [
    InvoiceItem(name: 'Bulk', quantity: 9999, rate: 8888.88, gstRate: 28),
  ],
  'zero value line': [
    InvoiceItem(name: 'Free sample', quantity: 1, rate: 0, gstRate: 18),
  ],
};

Invoice _invoice(List<InvoiceItem> items, GstType type,
    {double shipping = 0, double discount = 0}) {
  final now = DateTime.utc(2026, 1, 1);
  return Invoice(
    invoiceNumber: 'T-1',
    customerName: 'Test',
    invoiceDate: now,
    dueDate: now,
    lineItems: items,
    gstType: type,
    shippingCharge: shipping,
    flatDiscount: discount,
  );
}

List<TaxLine> _lines(List<InvoiceItem> items) => [
      for (final i in items)
        TaxLine(
          quantity: i.quantity,
          unitPrice: i.rate,
          ratePercent: i.gstRate,
          taxed: i.applyGst,
        ),
    ];

void main() {
  final engine = TaxEngine(indiaProfile);

  group('the engine reproduces the shipped India arithmetic exactly', () {
    for (final entry in _cases.entries) {
      for (final type in GstType.values) {
        final scope =
            type == GstType.cgstSgst ? SupplyScope.intra : SupplyScope.inter;

        test('${entry.key} / ${type.name}', () {
          final inv = _invoice(entry.value, type);
          final got = engine.compute(_lines(entry.value), scope: scope);

          // Bit-identical, not approximately equal. Both paths do the
          // same multiplications in the same order, so if this ever
          // needs a tolerance the orders have diverged and the fix is
          // to find out why, not to loosen the test.
          expect(got.subtotal, inv.subtotal, reason: 'subtotal');
          expect(got.taxTotal, inv.totalTax, reason: 'total tax');
          expect(got.components['CGST'] ?? 0, inv.totalCgst, reason: 'CGST');
          expect(got.components['SGST'] ?? 0, inv.totalSgst, reason: 'SGST');
          expect(got.components['IGST'] ?? 0, inv.totalIgst, reason: 'IGST');
          expect(got.grandTotal, inv.grandTotal, reason: 'grand total');
        });
      }
    }
  });

  group('shipping and discount match the model too', () {
    // The model adds shipping untaxed and subtracts the discount after
    // tax. The engine's default timing is afterTax precisely so that
    // this holds; see AdjustmentTiming for why that default is about
    // compatibility rather than about being the better rule.
    final items = _cases['mixed slabs']!;

    for (final shipping in [0.0, 50.0, 1234.56]) {
      for (final discount in [0.0, 100.0, 999.99]) {
        test('shipping $shipping, discount $discount', () {
          final inv = _invoice(items, GstType.cgstSgst,
              shipping: shipping, discount: discount);
          final got = engine.compute(
            _lines(items),
            scope: SupplyScope.intra,
            shipping: shipping,
            discount: discount,
          );
          expect(got.taxTotal, inv.totalTax,
              reason: 'neither shipping nor an after-tax discount '
                  'may change the tax');
          expect(got.grandTotal, inv.grandTotal);
        });
      }
    }
  });

  test('the components always add back up to the tax total', () {
    for (final entry in _cases.entries) {
      for (final scope in SupplyScope.values) {
        final got = engine.compute(_lines(entry.value), scope: scope);
        final summed = got.components.values.fold<double>(0, (s, v) => s + v);
        expect(summed, closeTo(got.taxTotal, 1e-9),
            reason: '${entry.key} / ${scope.name}');
      }
    }
  });
}
