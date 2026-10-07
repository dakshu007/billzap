// test/regions_test.dart
//
// "Place of supply" was a picker of twenty Indian states, shown to
// every shop in the world. Someone billing in Albania was offered
// Tamil Nadu and West Bengal, and the field prints on the invoice.

import 'package:flutter_test/flutter_test.dart';
import 'package:billzap/models/models.dart';
import 'package:billzap/tax/countries.dart';
import 'package:billzap/tax/regions.dart';

void main() {
  test('every row is well-formed and sorted', () {
    for (final code in regionTableCountries) {
      final regions = regionsFor(code)!;
      expect(code.length, 2, reason: code);
      expect(regions, isNotEmpty, reason: code);
      expect(regions.toSet().length, regions.length,
          reason: '$code repeats a region');
      for (final r in regions) {
        expect(r.trim(), r, reason: '$code has an untrimmed region "$r"');
        expect(r, isNotEmpty, reason: code);
      }
      final sorted = [...regions]..sort();
      expect(regions, sorted, reason: '$code is not alphabetical');
    }
  });

  test('every country in the table is one the picker offers', () {
    for (final code in regionTableCountries) {
      expect(countryFor(code), isNotNull,
          reason: '$code has regions but is not a country in the picker');
    }
  });

  test('India is deliberately absent', () {
    // India's list lives in models.dart as kStates, because each entry
    // carries the GST state code — 'Tamil Nadu (33)' — that
    // gstr1_builder.dart and the intra/inter-state split parse back
    // out. Two lists could disagree about a number the tax return
    // depends on.
    expect(regionsFor('IN'), isNull);
    expect(kStates.any((s) => s.contains('(33)')), isTrue,
        reason: 'the GST codes must still be in kStates');
  });

  test('the countries the user named are covered', () {
    // Albania was the example in the bug report.
    expect(regionsFor('AL'), contains('Tirana'));
    expect(regionsFor('AE'), contains('Dubai'));
    expect(regionsFor('US'), contains('California'));
    expect(regionsFor('GB'), contains('Scotland'));
    expect(regionsFor('KE'), contains('Nairobi'));
  });

  test('no country was handed India\'s list by mistake', () {
    // The actual bug: Indian states shown everywhere. The check is on
    // the overlap rather than on any single name, because Punjab is
    // genuinely a province of Pakistan as well as a state of India —
    // one shared name is geography, a handful is a copy-paste.
    final indianStates = kStates.map((s) => s.split(' (').first).toSet();
    for (final code in regionTableCountries) {
      final shared =
          regionsFor(code)!.where(indianStates.contains).toList();
      expect(shared.length, lessThanOrEqualTo(1),
          reason: '$code shares ${shared.length} names with India\'s '
              'states ($shared), which looks like the old list');
    }
  });

  test('an uncovered country returns null rather than a wrong list', () {
    // Null is a working state: the caller shows a free-text field.
    // Returning somebody else's regions is what this file exists to
    // stop.
    expect(regionsFor('ZZ'), isNull);
    expect(regionsFor(''), isNull);
  });

  test('lookup is case-insensitive', () {
    expect(regionsFor('al'), regionsFor('AL'));
  });
}
