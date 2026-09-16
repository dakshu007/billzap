// The app's UI face must ship inside the APK.
//
// google_fonts resolves a family from the asset manifest first and
// falls back to an HTTP fetch from fonts.gstatic.com when it finds
// nothing. That fallback is invisible in development — the font simply
// appears — and wrong in production twice over: it is a network call
// from an app that advertises itself as fully offline, and it fails on
// the no-signal counter BillZap is built for, leaving Roboto behind.
//
// main() sets `allowRuntimeFetching = false`, which turns the silent
// fallback into a throw. These tests make sure that throw can never be
// reached, by checking the two things that would cause it: the file
// missing from disk, and the file missing from pubspec's asset list.
//
// The names matter. google_fonts matches an asset whose path ends in
// `<Family>-<Variant>`, with the variant spelled Regular / Medium /
// SemiBold / Bold. Renaming one restores the runtime fetch.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every weight the app actually sets, mapped to the filename part
/// google_fonts derives from it.
const _variants = <String, String>{
  'w400 (also FontWeight.normal)': 'Regular',
  'w500': 'Medium',
  'w600': 'SemiBold',
  'w700 (also FontWeight.bold)': 'Bold',
};

void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();

  group('Plus Jakarta Sans is bundled, not fetched', () {
    for (final entry in _variants.entries) {
      final path = 'assets/fonts/PlusJakartaSans-${entry.value}.ttf';

      test('${entry.key} -> ${entry.value} exists on disk', () {
        final f = File(path);
        expect(f.existsSync(), isTrue,
            reason: '$path is missing, so google_fonts would try to '
                'download it at runtime.');
        // A truncated or placeholder file loads as garbage rather than
        // failing, so check it is plausibly a real font.
        expect(f.lengthSync(), greaterThan(40000),
            reason: '$path is too small to be the real font.');
      });

      test('${entry.key} -> ${entry.value} is listed in pubspec', () {
        expect(pubspec, contains(path),
            reason: 'A font that is not in the asset list is not in the '
                'asset manifest, which is the only place google_fonts '
                'looks before reaching for the network.');
      });
    }
  });

  test('runtime fetching is switched off at startup', () {
    // The bundled assets are what make this safe; this is the guard
    // that converts a future mistake into a loud failure.
    expect(File('lib/main.dart').readAsStringSync(),
        contains('GoogleFonts.config.allowRuntimeFetching = false'));
  });
}
