// test/i18n_keys_test.dart — every translation key used must exist.
//
// trGlobal() returns the key itself when it cannot find one:
//
//     return dict[key] ?? _en[key] ?? key;
//
// That is a reasonable fallback for a missing translation and a trap
// for a missing KEY, because the result is a perfectly ordinary String
// that nothing flags. Two bugs in this repo came from it:
//
//   • the voice screen asked for '__lang_code', which is not a key, got
//     back the string '__lang_code', and so pinned speech recognition
//     to en_IN for every user in all twelve languages
//   • 'voice.not_available' was never defined, so a shopkeeper whose
//     phone had no speech engine was shown the literal text
//     'voice.not_available'
//
// Neither produced an error, a crash or a warning. This test is the
// thing that would have.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:billzap/i18n/translations.dart';

void main() {
  test('every trGlobal() key in lib/ resolves to a real translation', () {
    final lib = Directory('lib');
    expect(lib.existsSync(), isTrue, reason: 'run from the package root');

    // Only literal single-quoted keys; a computed key cannot be checked
    // statically and is rare enough to review by hand.
    final call = RegExp(r"""trGlobal\(\s*'([^']+)'\s*\)""");
    final missing = <String>{};

    // Comments are stripped first. Without this the test flags its own
    // documentation: the comment in voice_invoice_screen.dart that
    // explains the bug necessarily quotes the broken call, and a raw
    // scan cannot tell an explanation from a use.
    final lineComment = RegExp(r'//[^\n]*');
    final blockComment = RegExp(r'/\*.*?\*/', dotAll: true);

    for (final f in lib.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final source = f
          .readAsStringSync()
          .replaceAll(blockComment, '')
          .replaceAll(lineComment, '');
      for (final m in call.allMatches(source)) {
        final key = m.group(1)!;
        // The fallback IS the key, so a key that resolves to itself is
        // either missing or a tautology. Both are worth failing on.
        if (trGlobal(key) == key) missing.add('$key  (${f.path})');
      }
    }

    expect(missing, isEmpty,
        reason: 'These keys are used but not defined in translations.dart, '
            'so the app shows the raw key to the user:\n'
            '${missing.join('\n')}');
  });

  test('currentLangCode is a code, not a translated string', () {
    // The bug this guards: reaching for the language code through the
    // translation table instead of asking for it directly.
    expect(currentLangCode, isNotEmpty);
    expect(currentLangCode.length, lessThanOrEqualTo(5));
    expect(currentLangCode, isNot(contains(' ')));
  });
}
