// test/countries_test.dart — the picker's data is only useful if intact.
//
// countries.dart is a parsed table rather than const objects. That buys
// readability at the cost of compile-time checking, so the checking
// happens here: a malformed row would otherwise be a country silently
// missing from the picker, with nothing to notice it.

import 'package:flutter_test/flutter_test.dart';
import 'package:billzap/tax/countries.dart';
import 'package:billzap/tax/profiles.dart';

void main() {
  test('the table holds every country on the distribution list', () {
    // Exact, not "more than 150". Four rows went missing the first time
    // this file was written — India, Saudi Arabia, Singapore and the
    // UAE, which is to say precisely the four with researched tax
    // profiles, because I treated them as handled elsewhere while
    // transcribing. A loose bound would not have noticed.
    expect(allCountries.length, 177);
  });

  test('every row is complete and well-shaped', () {
    for (final c in allCountries) {
      expect(c.code.length, 2, reason: '${c.name} code must be alpha-2');
      expect(c.code, c.code.toUpperCase(), reason: '${c.name} code upper');
      expect(c.name.trim(), isNotEmpty);
      expect(c.currencyCode.length, 3, reason: '${c.name} ISO 4217');
      expect(c.currencySymbol.trim(), isNotEmpty, reason: c.name);
    }
  });

  test('country codes are unique', () {
    final codes = allCountries.map((c) => c.code).toList();
    expect(codes.toSet().length, codes.length);
  });

  test('sorted by name, so the picker is navigable', () {
    final names = allCountries.map((c) => c.name).toList();
    final sorted = [...names]..sort();
    expect(names, sorted);
  });

  test('lookup works and is case-insensitive', () {
    expect(countryFor('IN')?.name, 'India');
    expect(countryFor('in')?.name, 'India');
    expect(countryFor('ZZ'), isNull);
  });

  test('the four researched countries are all in the picker', () {
    for (final p in allProfiles.where((p) => p.countryCode != 'XX')) {
      expect(countryFor(p.countryCode), isNotNull,
          reason: '${p.countryCode} has a tax profile but no picker row');
    }
  });

  group('resolveProfile', () {
    test('a researched country keeps its own rules', () {
      final p = resolveProfile(countryCode: 'IN', customTaxRate: 99);
      expect(p.countryCode, 'IN');
      expect(p.taxName, 'GST');
      expect(p.regionMatters, isTrue);
      expect(p.rates, contains(18.0),
          reason: 'custom values must not leak into a real profile');
      expect(p.rates, isNot(contains(99.0)));
    });

    test('an unresearched country takes the shopkeeper\'s settings', () {
      final p = resolveProfile(
        countryCode: 'BR',
        countryName: 'Brazil',
        customTaxName: 'ICMS',
        customTaxRate: 17,
        customCurrencySymbol: r'R$',
        customCurrencyCode: 'BRL',
      );
      expect(p.countryCode, 'BR', reason: 'the real country, custom rules');
      expect(p.taxName, 'ICMS');
      expect(p.defaultRate, 17);
      expect(p.rates, [0.0, 17.0]);
      expect(p.currencySymbol, r'R$');
      expect(p.verified, isFalse);
      expect(p.componentsAreWellFormed, isTrue);
    });

    test('zero is always offered, for exempt lines', () {
      expect(resolveProfile(countryCode: 'BR', customTaxRate: 20).rates,
          contains(0.0));
      // Gibraltar, deliberately: it is in the picker, has no researched
      // profile AND no row in the rate table, so a zero custom rate
      // really does reach the bare custom profile. Using a country the
      // table covers would test the table instead.
      expect(resolveProfile(countryCode: 'GI', customTaxRate: 0).rates, [0.0],
          reason: 'a zero custom rate must not produce a duplicate');
    });

    test('a blank tax name falls back rather than showing an empty label', () {
      expect(resolveProfile(countryCode: 'GI', customTaxName: '   ').taxName,
          'Tax');
    });
  });
}
