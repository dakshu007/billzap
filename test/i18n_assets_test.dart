// test/i18n_assets_test.dart — the translation files are what they claim.
//
// Every language other than English is a JSON file in assets/i18n. A
// file is data, so nothing in the compiler stops it drifting from the
// English it translates. These are the checks that do:
//
//   • the file is for a language the app actually offers
//   • every string is a string, and no key is one English does not have
//     (a typo'd key is a translation nobody will ever see)
//   • every {placeholder} English has, the translation has, and no more.
//     A translator who "translates" {amount} prints the literal word on
//     the shopkeeper's screen instead of the money.
//   • nothing is blank

import 'package:flutter_test/flutter_test.dart';
import 'package:billzap/i18n/translations.dart';
import 'i18n_disk.dart';

void main() {
  // English as written, before {tax} and friends are filled in.
  final english = {for (final k in englishKeys) k: rawEnglishString(k)};

  test('every file is for a language the app offers', () {
    for (final id in translationFilesOnDisk()) {
      expect(appLocaleFor(id), isNotNull,
          reason: 'assets/i18n/$id.json is for no language in locales.dart');
      expect(id, isNot('en'),
          reason: 'English lives in translations.dart, not in a file');
    }
  });

  test('no file has a key English does not, or a value that is not text',
      () {
    for (final id in translationFilesOnDisk()) {
      final raw = readTranslationFile(id);
      for (final e in raw.entries) {
        expect(english.containsKey(e.key), isTrue,
            reason: '$id has a key English does not: ${e.key}');
        expect(e.value, isA<String>(), reason: '$id ${e.key}');
        expect((e.value as String).trim(), isNotEmpty,
            reason: '$id ${e.key} is blank');
      }
    }
  });

  test('placeholders survive translation exactly', () {
    final problems = <String>[];
    for (final id in translationFilesOnDisk()) {
      final raw = readTranslationFile(id);
      for (final e in raw.entries) {
        final want = placeholdersIn(english[e.key] ?? '');
        final got = placeholdersIn(e.value as String);
        if (want.toString() != got.toString()) {
          problems.add('$id ${e.key}: English has $want, file has $got');
        }
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });
}
