// test/validators_country_test.dart
//
// Every validator in the app was India's rule applied to everybody. A
// Nigerian mobile number does not start 6-9 and is not ten digits, so
// the field refused it and the shopkeeper could not save a customer —
// with no way round it in the UI.
//
// These tests exist in both directions: India's rules must not have
// loosened (the GSTIN check is worth having), and nobody else's valid
// input may be rejected.

import 'package:flutter_test/flutter_test.dart';
import 'package:billzap/tax/active_profile.dart';
import 'package:billzap/tax/profiles.dart';
import 'package:billzap/utils/validators.dart';

void main() {
  setUp(() => setActiveProfile(indiaProfile));
  tearDown(() => setActiveProfile(indiaProfile));

  group('India keeps its own rules', () {
    test('a real GSTIN passes and a wrong-length one does not', () {
      expect(Validators.gstin('29ABCDE1234F1Z5'), isNull);
      expect(Validators.gstin('29ABCDE1234F1Z'), isNotNull);
      expect(Validators.gstin('not a gstin at all'), isNotNull);
    });

    test('an Indian mobile passes, with or without the country code', () {
      expect(Validators.phone('9876543210'), isNull);
      expect(Validators.phone('+91 98765 43210'), isNull);
    });

    test('a number that is not an Indian mobile is still refused', () {
      expect(Validators.phone('1234567890'), isNotNull,
          reason: 'Indian mobiles start 6-9');
      expect(Validators.phone('98765'), isNotNull);
    });

    test('a six-digit pincode passes and a postcode does not', () {
      expect(Validators.pincode('600001'), isNull);
      expect(Validators.pincode('SW1A 1AA'), isNotNull);
    });

    test('IFSC is checked', () {
      expect(Validators.ifsc('SBIN0001234'), isNull);
      expect(Validators.ifsc('NOPE'), isNotNull);
    });
  });

  group('everywhere else, valid input is accepted', () {
    setUp(() => setActiveProfile(uaeProfile));

    test('a tax number that is not a GSTIN is fine', () {
      // A UAE TRN is 15 digits, a UK VRN 9, an EU VAT number has a
      // country prefix, a Brazilian CNPJ is punctuated.
      for (final id in [
        '100123456700003',
        'GB123456789',
        'DE811907980',
        '12.345.678/0001-95',
        'ESB12345678',
      ]) {
        expect(Validators.gstin(id), isNull, reason: '$id must be accepted');
      }
    });

    test('the error names the country\'s own field, not GSTIN', () {
      final err = Validators.gstin('x');
      expect(err, isNotNull);
      expect(err, contains(activeTaxIdLabel));
      expect(err, isNot(contains('GSTIN')));
    });

    test('obvious nonsense is still caught', () {
      expect(Validators.gstin('x'), isNotNull, reason: 'too short');
      expect(Validators.gstin('a' * 40), isNotNull, reason: 'too long');
    });

    test('a foreign phone number is accepted however it is punctuated', () {
      for (final n in [
        '+971 50 123 4567',
        '(555) 010-9999',
        '+44 20 7946 0958',
        '+254 712 345678',
        '+81-3-1234-5678',
      ]) {
        expect(Validators.phone(n), isNull, reason: '$n must be accepted');
      }
    });

    test('a phone too short or too long to be one is caught', () {
      expect(Validators.phone('123'), isNotNull);
      expect(Validators.phone('1234567890123456789'), isNotNull);
    });

    test('a postal code with letters in it is accepted', () {
      for (final p in ['SW1A 1AA', 'K1A 0B1', '1234 AB', '10001', '75008']) {
        expect(Validators.pincode(p), isNull, reason: '$p must be accepted');
      }
    });

    test('IFSC is not enforced on a bank that has no IFSC', () {
      expect(Validators.ifsc('CHASUS33'), isNull,
          reason: 'a SWIFT code is not an IFSC and must not be refused');
    });
  });

  group('an empty field is never an error', () {
    // These are all optional fields; the required check is separate.
    for (final profile in [indiaProfile, uaeProfile]) {
      test('in ${profile.countryCode}', () {
        setActiveProfile(profile);
        expect(Validators.gstin(''), isNull);
        expect(Validators.gstin(null), isNull);
        expect(Validators.phone(''), isNull);
        expect(Validators.pincode(''), isNull);
        expect(Validators.ifsc(''), isNull);
      });
    }
  });
}
