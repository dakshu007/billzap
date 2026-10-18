// test/voice_locale_test.dart
//
// Which speech locale the voice screen listens in.
//
// This has already been wrong twice, both times silently. First the
// app read a non-existent translation key and every user in all twelve
// languages got en_IN. Then, once that was fixed, en still mapped to
// en_IN for everybody — so an English-speaking shopkeeper in Nairobi
// was dictating into a recogniser tuned for Indian English phonetics
// and Indian number words.
//
// Both bugs produce a worse transcript, not an error, which is exactly
// why they need a test rather than a careful reading.

import 'package:flutter_test/flutter_test.dart';
import 'package:billzap/screens/invoice/voice_invoice_screen.dart';

void main() {
  group('the shop\'s country comes first', () {
    test('English in Kenya tries en_KE before anything else', () {
      final c = voiceLocaleCandidates('en', 'KE');
      expect(c.first, 'en_KE');
      expect(c, contains('en_US'));
      expect(c.indexOf('en_KE'), lessThan(c.indexOf('en_IN')));
    });

    test('English in India is unchanged — en_IN is the country match',
        () {
      // Not a special case in the code: for a shop in India the
      // country-specific candidate simply IS the _IN one.
      expect(voiceLocaleCandidates('en', 'IN').first, 'en_IN');
    });

    test('an Indian language keeps its own pack as the second choice', () {
      final c = voiceLocaleCandidates('ta', 'SG');
      expect(c[0], 'ta_SG', reason: 'Tamil as spoken in Singapore');
      expect(c[1], 'ta_IN', reason: 'then the pack that definitely exists');
    });

    test('a language with no mapped pack still gets usable fallbacks', () {
      final c = voiceLocaleCandidates('sw', 'TZ');
      expect(c.first, 'sw_TZ');
      expect(c, contains('en_TZ'));
      expect(c, contains('en_US'));
      expect(c, isNot(contains('')), reason: 'no empty locale ids');
    });
  });

  test('the list is ordered, non-empty and free of blanks for every case',
      () {
    for (final lang in ['en', 'hi', 'ta', 'te', 'ur', 'zz']) {
      for (final country in ['IN', 'AE', 'US', 'KE', 'XX']) {
        final c = voiceLocaleCandidates(lang, country);
        expect(c, isNotEmpty, reason: '$lang/$country');
        expect(c.every((l) => l.isNotEmpty), isTrue, reason: '$lang/$country');
        expect(c.every((l) => l.contains('_')), isTrue,
            reason: '$lang/$country produced a malformed locale id');
      }
    }
  });

  test('a lower-case country code still matches', () {
    expect(voiceLocaleCandidates('en', 'ke').first, 'en_KE');
  });
}
