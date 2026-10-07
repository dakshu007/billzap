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
  test('the table covers the whole country picker bar India', () {
    // 176 of the 177. India is the exception on purpose: it has a
    // researched profile carrying the CGST/SGST/IGST split and the GST
    // state codes, and a second entry here could disagree with it.
    expect(rateTableCountries.length, 176);
    expect(rateTableCountries, isNot(contains('IN')));
    for (final c in allCountries) {
      if (c.code == 'IN') continue;
      expect(rateRowFor(c.code), isNotNull,
          reason: '${c.name} (${c.code}) has no rate row');
    }
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
    // ZZ is the ISO user-assigned code, so it is permanently not a
    // country and can never grow a table row. This used to be
    // Gibraltar, until the 2026 reference gave Gibraltar a 15%
    // transaction tax and the test quietly started exercising the
    // table instead of the fall-through it was written for.
    //
    // The fall-through still matters even though the table now covers
    // every country in the picker: it is what happens when a code
    // arrives that the app does not know.
    final p = resolveProfile(countryCode: 'ZZ', countryName: 'Elsewhere');
    expect(p.confidence, TaxConfidence.selfDeclared);
    expect(p.componentsAreWellFormed, isTrue);
    expect(p.rates, contains(0.0));
  });

  test('an unknown code never acquires a rate from nowhere', () {
    for (final code in ['ZZ', 'QQ', 'XY']) {
      expect(rateRowFor(code), isNull, reason: code);
      expect(resolveProfile(countryCode: code).confidence,
          TaxConfidence.selfDeclared,
          reason: code);
      expect(resolveProfile(countryCode: code).defaultRate, 0,
          reason: '$code must not arrive with a rate the app invented');
    }
  });

  test('the rows the reference singles out are the rates it names', () {
    // Each of these is a row the source document flags as one where a
    // naive reading gives the wrong answer, so each is worth pinning.
    expect(rateRowFor('LR')!.defaultRate, 13,
        reason: 'Liberia is 13% GST in 2026; 15% VAT starts in 2027 and '
            'the document says explicitly not to use it yet');
    expect(rateRowFor('TH')!.defaultRate, 10,
        reason: 'Thailand rose from 7% to 10% on 1 Oct 2026');
    expect(rateRowFor('ID')!.defaultRate, 11,
        reason: '12% statutory on an 11/12 base is 11% effective');
    expect(rateRowFor('GH')!.defaultRate, 20,
        reason: '15% VAT + 2.5% NHIL + 2.5% GETFund on one base');
    expect(rateRowFor('BR')!.defaultRate, 0,
        reason: 'Brazil has no single rate during the 2026 transition');
    expect(rateRowFor('US')!.defaultRate, 0,
        reason: 'sales tax is state and local; guessing a state is worse '
            'than asking');
    expect(rateRowFor('EE')!.defaultRate, 24);
    expect(rateRowFor('RO')!.defaultRate, 21);
    expect(rateRowFor('KZ')!.defaultRate, 16);
    expect(rateRowFor('ZW')!.defaultRate, 15.5);
    expect(rateRowFor('GI')!.defaultRate, 15,
        reason: 'a transaction tax from 1 Aug 2026, where there was '
            'historically no VAT at all');
  });
}
