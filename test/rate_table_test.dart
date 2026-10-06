// test/rate_table_test.dart — the table is data, so its shape is testable
// even though its accuracy is not.
//
// Nothing here checks whether a rate is CORRECT; no test can, and that is
// exactly why every row ships as TaxConfidence.unconfirmed. What these do
// check is that no row is malformed, that no row quietly claims to be
// verified, and that every country in the table can actually be picked.

import 'package:flutter_test/flutter_test.dart';
import 'package:billzap/tax/rate_table.dart';
import 'package:billzap/tax/countries.dart';
import 'package:billzap/tax/profiles.dart';
import 'package:billzap/tax/tax_profile.dart';

void main() {
  test('the table covers most of the country picker', () {
    // 159 of the 177 countries in the picker. The remainder is four
    // researched profiles plus fourteen small jurisdictions where no
    // national rate exists to pre-fill, and those correctly fall
    // through to the shopkeeper's own setting.
    expect(rateTableCountries.length, 159);
    expect(rateTableCountries.length / allCountries.length,
        greaterThan(0.85));
  });

  test('a tax name is never a sentence about the absence of one', () {
    // "No VAT" was a real row once. It reached the UI through the
    // {tax} placeholder as "Apply No VAT", which is nonsense. Where a
    // country levies nothing the row says "Tax" and offers only zero.
    for (final code in rateTableCountries) {
      final r = rateRowFor(code)!;
      expect(r.taxName.toLowerCase(), isNot(startsWith('no ')),
          reason: '$code names its tax after not having one');
      expect(r.taxName.split(' ').length, lessThanOrEqualTo(3),
          reason: '$code tax name is too long to fit a label');
    }
  });

  test('a country with no national rate offers only zero', () {
    // Not an omission: Hong Kong, Macau, Qatar, Kuwait, Libya and
    // Bermuda levy no consumption tax, and the USA sets it per state.
    for (final code in ['HK', 'MO', 'QA', 'KW', 'LY', 'BM']) {
      expect(rateRowFor(code)!.rates, [0.0], reason: code);
    }
    // The USA is the other shape: a real tax with no national figure,
    // so the bands are offered and nothing is defaulted.
    final us = rateRowFor('US')!;
    expect(us.defaultRate, 0);
    expect(us.rates.length, greaterThan(5),
        reason: 'a US shop must be able to pick its own combined rate');
  });

  test('every row is well-formed', () {
    for (final code in rateTableCountries) {
      final r = rateRowFor(code)!;
      expect(r.code.length, 2, reason: code);
      expect(r.taxName.trim(), isNotEmpty, reason: code);
      expect(r.taxIdLabel.trim(), isNotEmpty, reason: code);
      expect(r.rates, isNotEmpty, reason: code);
      expect(r.rates, contains(0.0),
          reason: '$code must offer a zero rate for exempt lines');
      expect(r.rates, contains(r.defaultRate),
          reason: '$code default is not one of its own rates');
      for (final rate in r.rates) {
        expect(rate, inInclusiveRange(0, 100), reason: code);
      }
    }
  });

  test('every country in the table can actually be selected', () {
    for (final code in rateTableCountries) {
      expect(countryFor(code), isNotNull,
          reason: '$code has a rate but no row in the country picker');
    }
  });

  test('no table row ever claims to be verified', () {
    // The whole safety argument rests on this. If a rate from here could
    // present itself as checked, the app would be asserting tax law it
    // has not confirmed.
    for (final code in rateTableCountries) {
      final p = tableProfileFor(code)!;
      expect(p.confidence, TaxConfidence.unconfirmed, reason: code);
      expect(p.verified, isFalse, reason: code);
      expect(p.componentsAreWellFormed, isTrue, reason: code);
    }
  });

  test('a researched profile still beats the table', () {
    // India, UAE, Saudi and Singapore have real profiles. The table must
    // not shadow them.
    expect(resolveProfile(countryCode: 'IN').taxName, 'GST');
    expect(resolveProfile(countryCode: 'IN').regionMatters, isTrue);
    expect(resolveProfile(countryCode: 'IN').confidence,
        TaxConfidence.verified);
  });

  test('the table fills a country that had nothing', () {
    final gb = resolveProfile(countryCode: 'GB');
    expect(gb.taxName, 'VAT');
    expect(gb.taxIdLabel, 'VAT number');
    expect(gb.defaultRate, 20);
    expect(gb.currencySymbol, '£');
    expect(gb.confidence, TaxConfidence.unconfirmed);
  });

  test("a shopkeeper's own rate overrides the table", () {
    // Somebody who has typed a rate has made a decision the app should
    // not quietly undo with a recollection.
    final gb = resolveProfile(
        countryCode: 'GB', customTaxName: 'VAT', customTaxRate: 5);
    expect(gb.defaultRate, 5);
    expect(gb.confidence, TaxConfidence.selfDeclared);
  });

  test('a country in neither place still works', () {
    // Gibraltar: in the picker, no researched profile, no table row.
    // This is the fall-through the whole design rests on — an
    // unresearched country must be a working app, not an error.
    final p = resolveProfile(countryCode: 'GI', countryName: 'Gibraltar');
    expect(p.confidence, TaxConfidence.selfDeclared);
    expect(p.componentsAreWellFormed, isTrue);
  });

  test('the fall-through countries really are in neither place', () {
    // If the table later grows a row for one of these, the two tests
    // above start testing the table instead of the fall-through and
    // quietly stop checking what they were written to check.
    for (final code in ['GI', 'KY', 'VA', 'VG', 'AW']) {
      expect(rateRowFor(code), isNull,
          reason: '$code now has a table row; pick another fall-through');
      expect(resolveProfile(countryCode: code).confidence,
          TaxConfidence.selfDeclared,
          reason: code);
    }
  });
}
