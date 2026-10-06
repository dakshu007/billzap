// test/tax_engine_test.dart — the arithmetic, and the shape of the data.
//
// Tax is the one part of this app where a silent wrong answer is worse
// than a crash: nothing looks broken, the shopkeeper files it, and the
// problem surfaces months later as a liability. So these tests are
// deliberately fussy about the parts that would fail quietly.

import 'package:flutter_test/flutter_test.dart';
import 'package:billzap/tax/tax_profile.dart';
import 'package:billzap/tax/tax_engine.dart';
import 'package:billzap/tax/profiles.dart';

void main() {
  group('profile data', () {
    test('every registered profile splits tax into exactly 100%', () {
      // A profile whose components sum to 0.9 would quietly under-report
      // tax on every bill in that country and never throw.
      for (final p in allProfiles) {
        expect(p.componentsAreWellFormed, isTrue,
            reason: '${p.countryCode} components must sum to 1');
      }
    });

    test('a malformed profile is actually caught', () {
      // Guards the guard: if componentsAreWellFormed always returned
      // true the test above would pass for a broken profile.
      final broken = TaxProfile(
        countryCode: 'ZZ', countryName: 'Broken',
        currencyCode: 'ZZZ', currencySymbol: 'Z',
        taxName: 'Tax', taxIdLabel: 'ID',
        rates: const [10], defaultRate: 10,
        intraComponents: const [TaxComponent('A', 0.4), TaxComponent('B', 0.4)],
        verified: false, source: 'test fixture',
        effectiveFrom: DateTime.utc(2020, 1, 1),
      );
      expect(broken.componentsAreWellFormed, isFalse);
    });

    test('country codes are unique', () {
      final codes = allProfiles.map((p) => p.countryCode).toList();
      expect(codes.toSet().length, codes.length);
    });

    test('the default rate is one a shopkeeper can actually pick', () {
      for (final p in allProfiles) {
        expect(p.rates, contains(p.defaultRate), reason: p.countryCode);
      }
    });

    test('only profiles a person has checked claim to be verified', () {
      // If this list grows, someone has marked a profile verified.
      // That should be a deliberate commit with evidence, not a drift.
      expect(verifiedProfiles.map((p) => p.countryCode).toList(), ['IN']);
    });

    test('an unresearched country falls back to custom, never to a guess', () {
      expect(profileFor('BR').countryCode, 'XX');
      expect(profileFor('ZW').countryCode, 'XX');
      expect(profileFor('IN').countryCode, 'IN');
      expect(profileFor('in').countryCode, 'IN', reason: 'case insensitive');
    });
  });

  group('engine arithmetic', () {
    test('a flat-VAT country produces one component', () {
      final e = TaxEngine(uaeProfile);
      final r = e.compute([
        const TaxLine(quantity: 2, unitPrice: 100, ratePercent: 5),
      ]);
      expect(r.subtotal, 200);
      expect(r.taxTotal, 10);
      expect(r.components, {'VAT': 10.0});
      expect(r.grandTotal, 210);
    });

    test('India splits intra-state in half and inter-state whole', () {
      final e = TaxEngine(indiaProfile);
      final lines = [const TaxLine(quantity: 1, unitPrice: 1000, ratePercent: 18)];

      final intra = e.compute(lines, scope: SupplyScope.intra);
      expect(intra.components, {'CGST': 90.0, 'SGST': 90.0});

      final inter = e.compute(lines, scope: SupplyScope.inter);
      expect(inter.components, {'IGST': 180.0});

      // Same total either way — only the presentation differs.
      expect(intra.taxTotal, inter.taxTotal);
    });

    test('scope is ignored where the country has no regions', () {
      final e = TaxEngine(singaporeProfile);
      final lines = [const TaxLine(quantity: 1, unitPrice: 100, ratePercent: 9)];
      expect(e.compute(lines, scope: SupplyScope.inter).components,
          e.compute(lines, scope: SupplyScope.intra).components);
    });

    test('an untaxed line contributes to the subtotal but not the tax', () {
      final e = TaxEngine(indiaProfile);
      final r = e.compute([
        const TaxLine(quantity: 1, unitPrice: 100, ratePercent: 18),
        const TaxLine(quantity: 1, unitPrice: 50, ratePercent: 18, taxed: false),
      ]);
      expect(r.subtotal, 150);
      expect(r.taxTotal, 18);
    });

    test('mixed rates on one bill are taxed per line, not averaged', () {
      final e = TaxEngine(indiaProfile);
      final r = e.compute([
        const TaxLine(quantity: 1, unitPrice: 100, ratePercent: 5),
        const TaxLine(quantity: 1, unitPrice: 100, ratePercent: 28),
      ]);
      expect(r.taxTotal, closeTo(33, 1e-9));
    });

    test('an empty bill is zero everywhere, not a crash', () {
      final r = TaxEngine(indiaProfile).compute([]);
      expect(r.subtotal, 0);
      expect(r.taxTotal, 0);
      expect(r.grandTotal, 0);
      expect(r.components.values.every((v) => v == 0), isTrue);
    });
  });

  group('discount timing changes the tax, which is the whole point', () {
    final lines = [const TaxLine(quantity: 1, unitPrice: 1000, ratePercent: 18)];

    test('after tax: the base is untouched, tax is on the full 1000', () {
      final r = TaxEngine(indiaProfile)
          .compute(lines, discount: 100, timing: AdjustmentTiming.afterTax);
      expect(r.subtotal, 1000);
      expect(r.taxTotal, 180);
      expect(r.grandTotal, 1080); // 1000 + 180 - 100
    });

    test('before tax: the base drops to 900 and so does the tax', () {
      final r = TaxEngine(indiaProfile)
          .compute(lines, discount: 100, timing: AdjustmentTiming.beforeTax);
      expect(r.subtotal, closeTo(900, 1e-9));
      expect(r.taxTotal, closeTo(162, 1e-9));
      expect(r.grandTotal, closeTo(1062, 1e-9));
    });

    test('the two rules differ by the tax on the discount', () {
      final after = TaxEngine(indiaProfile)
          .compute(lines, discount: 100, timing: AdjustmentTiming.afterTax);
      final before = TaxEngine(indiaProfile)
          .compute(lines, discount: 100, timing: AdjustmentTiming.beforeTax);
      // 18 rupees of GST on a 100 rupee discount. Which rule is right is
      // a question for the shopkeeper's accountant, not for this engine
      // — but the app must not pick one by accident.
      expect(after.taxTotal - before.taxTotal, closeTo(18, 1e-9));
    });

    test('a before-tax discount spreads across lines by value', () {
      // Charging the whole discount to the first line would collect the
      // wrong tax on both when the rates differ.
      final r = TaxEngine(indiaProfile).compute([
        const TaxLine(quantity: 1, unitPrice: 100, ratePercent: 5),
        const TaxLine(quantity: 1, unitPrice: 100, ratePercent: 28),
      ], discount: 100, timing: AdjustmentTiming.beforeTax);
      expect(r.subtotal, closeTo(100, 1e-9));
      expect(r.taxTotal, closeTo(16.5, 1e-9)); // half of 5% + half of 28%
    });

    test('a discount larger than the bill cannot invert the tax', () {
      final r = TaxEngine(indiaProfile)
          .compute(lines, discount: 5000, timing: AdjustmentTiming.beforeTax);
      expect(r.subtotal, 0);
      expect(r.taxTotal, 0);
    });
  });

  group('number grouping', () {
    test('India groups the last three then in twos', () {
      expect(TaxEngine.groupDigits('1234567', NumberGrouping.indian), '12,34,567');
      expect(TaxEngine.groupDigits('100000', NumberGrouping.indian), '1,00,000');
      expect(TaxEngine.groupDigits('1000', NumberGrouping.indian), '1,000');
      expect(TaxEngine.groupDigits('999', NumberGrouping.indian), '999');
    });

    test('everywhere else groups in threes', () {
      expect(TaxEngine.groupDigits('1234567', NumberGrouping.western), '1,234,567');
      expect(TaxEngine.groupDigits('1000', NumberGrouping.western), '1,000');
      expect(TaxEngine.groupDigits('999', NumberGrouping.western), '999');
    });

    test('formatting carries the right symbol and grouping per country', () {
      expect(TaxEngine(indiaProfile).format(1234567.5), '₹12,34,567.50');
      expect(TaxEngine(singaporeProfile).format(1234567.5), r'S$1,234,567.50');
      expect(TaxEngine(indiaProfile).format(-100), '-₹100.00');
    });
  });
}
