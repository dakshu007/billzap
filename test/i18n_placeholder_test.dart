// test/i18n_placeholder_test.dart
//
// The app's strings carry {tax} and {taxid} where they used to say GST
// and GSTIN, filled in from the country the shop is in. Two things can
// go wrong with that, and both are visible to the shopkeeper:
//
//   1. A placeholder leaks to the screen as the literal "{tax}".
//   2. A string that should say GST stops saying it — GSTR-1 is called
//      GSTR-1 in every country, because it only exists in one.

import 'package:flutter_test/flutter_test.dart';
import 'package:billzap/i18n/translations.dart';
import 'i18n_disk.dart';
import 'package:billzap/tax/active_profile.dart';
import 'package:billzap/tax/profiles.dart';

void main() {
  setUpAll(registerAllTranslationsFromDisk);
  tearDown(() => setActiveProfile(indiaProfile));

  test('no placeholder survives a lookup, in any language', () {
    for (final code in ['en', ...translationFilesOnDisk()]) {
      for (final profile in [indiaProfile, uaeProfile, customProfile]) {
        setActiveProfile(profile);
        for (final key in allTranslationKeys(code)) {
          final out = trKey(key, code);
          expect(out, isNot(contains('{tax}')),
              reason: '$key in $code leaked {tax}');
          expect(out, isNot(contains('{taxid}')),
              reason: '$key in $code leaked {taxid}');
          expect(out, isNot(contains('{itemcode}')),
              reason: '$key in $code leaked {itemcode}');
        }
      }
    }
  });

  test('the tax noun follows the country', () {
    setActiveProfile(indiaProfile);
    expect(trKey('create.apply_gst', 'en'), 'Apply GST');
    expect(trKey('cust.gstin', 'en'), 'GSTIN');

    setActiveProfile(uaeProfile);
    expect(trKey('create.apply_gst', 'en'), 'Apply VAT');
    expect(trKey('cust.gstin', 'en'), 'TRN');

    setActiveProfile(singaporeProfile);
    expect(trKey('create.apply_gst', 'en'), 'Apply GST');
    expect(trKey('cust.gstin', 'en'), 'GST registration number');
  });

  test('the noun is substituted inside a translated sentence too', () {
    setActiveProfile(uaeProfile);
    // Hindi grammar, UAE noun. The translator owns the sentence; the
    // country owns the word.
    expect(trKey('create.apply_gst', 'hi'), contains('VAT'));
    expect(trKey('create.apply_gst', 'hi'), isNot(contains('GST')));
  });

  test('India-only names keep their literal word everywhere', () {
    // These are not nouns for "the tax" — they are the names of Indian
    // filings and Indian tax components. Renaming them to VAT in Dubai
    // would be nonsense, so they are deliberately not placeholders.
    setActiveProfile(uaeProfile);
    for (final key in [
      'rep.gstr1_json',
      'inv.cgst',
      'inv.sgst',
      'inv.igst',
      'create.cgst_sgst',
      'create.igst',
    ]) {
      expect(trKey(key, 'en'), contains('GST'),
          reason: '$key must keep its Indian name');
    }
  });

  test('the summary report is named after the country\'s tax', () {
    // This one was briefly in the India-only list above, which was
    // wrong: "GST Summary" is a report title, not the name of an
    // Indian filing, and a shop in Dubai should read "VAT Summary".
    setActiveProfile(indiaProfile);
    expect(trKey('rep.gst_summary', 'en'), 'GST Summary');
    setActiveProfile(uaeProfile);
    expect(trKey('rep.gst_summary', 'en'), 'VAT Summary');
  });

  test('the item code label falls back rather than going blank', () {
    // India names it HSN. Most countries name it nothing at all, and
    // the profile's itemCodeLabel is null there — which must not reach
    // the screen as "  Code (optional)".
    setActiveProfile(indiaProfile);
    expect(trKey('cat.hsn', 'en'), 'HSN Code (optional)');
    setActiveProfile(uaeProfile);
    expect(trKey('cat.hsn', 'en'), 'Item Code (optional)');
  });

  test('a shopkeeper-named tax reaches the labels', () {
    setActiveProfile(resolveProfile(
        countryCode: 'ZW', customTaxName: 'Sales Tax', customTaxRate: 14));
    expect(trKey('create.apply_gst', 'en'), 'Apply Sales Tax');
  });
}
