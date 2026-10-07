// test/locales_test.dart — the language list and the country matrix.
//
// Built from the owner's "Global Language & Localization Specification
// 2026". These pin the shape of that data so an edit cannot quietly
// strand a country with no languages or point a country at a language
// the app does not have.

import 'package:flutter_test/flutter_test.dart';
import 'package:billzap/i18n/locales.dart';
import 'package:billzap/tax/countries.dart';

void main() {
  test('every language the document names is in the app, once', () {
    // 100 Tier 1 + 20 Tier 2 + the six the matrix adds.
    expect(kAppLocales.length, 126);
    final ids = kAppLocales.map((l) => l.id).toList();
    expect(ids.toSet().length, ids.length, reason: 'duplicate locale id');
    for (final l in kAppLocales) {
      expect(l.nativeName.trim(), isNotEmpty, reason: l.id);
      expect(l.englishName.trim(), isNotEmpty, reason: l.id);
      expect(l.defaultRegion.length, 2, reason: l.id);
    }
  });

  test('the original twelve are all still there', () {
    for (final id in [
      'en', 'hi', 'ta', 'te', 'kn', 'ml', 'mr', 'gu', 'bn', 'pa', 'or', 'ur',
    ]) {
      expect(appLocaleFor(id), isNotNull, reason: '$id was removed');
    }
  });

  test('right-to-left is exactly the right-to-left scripts', () {
    final rtl = kAppLocales.where((l) => l.rtl).map((l) => l.id).toSet();
    expect(rtl, {
      'ar', 'he', 'ur', 'fa', 'ps', 'sd', 'kk-Arab', 'dv', 'ckb',
    });
  });

  test('every country in the picker has languages, all of them real', () {
    for (final c in allCountries) {
      final list = localesForCountry(c.code);
      expect(list, isNotEmpty, reason: c.code);
      expect(list.map((l) => l.id).toSet().length, list.length,
          reason: '${c.code} lists a language twice');
      for (final id in matrixLocalesFor(c.code)) {
        expect(appLocaleFor(id), isNotNull,
            reason: '${c.code} names $id, which the app does not have');
      }
    }
  });

  test('the matrix covers the 177 countries and nothing else', () {
    final codes = allCountries.map((c) => c.code).toSet();
    expect(matrixCountries.toSet(), codes);
  });

  test('a few rows straight from the document', () {
    expect(matrixLocalesFor('IN').take(4), ['en', 'hi', 'bn', 'ta']);
    expect(matrixLocalesFor('CH'), ['de', 'fr', 'it', 'rm']);
    expect(matrixLocalesFor('NG'), ['en', 'ha', 'ig', 'yo', 'pcm']);
    expect(matrixLocalesFor('HK'), ['yue-Hant', 'zh-Hant', 'en']);
    // Urdu stays offered in India: it was one of the launch languages.
    expect(matrixLocalesFor('IN'), contains('ur'));
    // Singapore writes Simplified Chinese. The document's zh-Hant there
    // is the one row deliberately not copied.
    expect(matrixLocalesFor('SG'), contains('zh-Hans'));
    expect(matrixLocalesFor('SG'), isNot(contains('zh-Hant')));
  });

  test('a language left out of the matrix is still offered at home', () {
    // Cherokee's home region is the US; the US row says en, es.
    expect(localesForCountry('US').map((l) => l.id), contains('chr'));
    expect(localesForCountry('DE').map((l) => l.id),
        containsAll(['de', 'hsb', 'dsb']));
  });

  test('search finds a language by any name a person would type', () {
    List<String> ids(String q) => searchLocales(q).map((l) => l.id).toList();
    expect(ids('Spanish'), contains('es'));
    expect(ids('espanol'), contains('es'), reason: 'accent-insensitive');
    expect(ids('Español'), contains('es'));
    expect(ids('தமிழ்'), contains('ta'));
    expect(ids('zh'), containsAll(['zh-Hans', 'zh-Hant']));
    expect(ids('   '), hasLength(kAppLocales.length));
  });
}
