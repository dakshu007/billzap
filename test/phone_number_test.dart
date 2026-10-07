// test/phone_number_test.dart — whose WhatsApp a message opens.
//
// Every number used to get India's 91 in front of it, so a shop in
// Nairobi messaging 0712 345678 reached somebody in India. India's own
// behaviour must not change; nobody else's number may be guessed.

import 'package:flutter_test/flutter_test.dart';
import 'package:billzap/utils/phone_number.dart';

void main() {
  group('India keeps what it had', () {
    test('ten digits get 91', () {
      expect(whatsAppNumber('98765 43210', shopCountry: 'IN'), '919876543210');
    });
    test('already international stays', () {
      expect(whatsAppNumber('919876543210', shopCountry: 'IN'),
          '919876543210');
      expect(whatsAppNumber('+91 98765 43210', shopCountry: 'IN'),
          '919876543210');
    });
    test('a trunk 0 is dropped', () {
      expect(whatsAppNumber('09876543210', shopCountry: 'IN'), '919876543210');
    });
  });

  group('everywhere else', () {
    test('a number typed with + is trusted', () {
      expect(whatsAppNumber('+254 712 345678', shopCountry: 'KE'),
          '254712345678');
      expect(whatsAppNumber('+1 (555) 010-9999', shopCountry: 'US'),
          '15550109999');
    });
    test('00 is the same as +', () {
      expect(whatsAppNumber('00254 712 345678', shopCountry: 'KE'),
          '254712345678');
    });
    test('a local number is not guessed at', () {
      expect(whatsAppNumber('0712 345678', shopCountry: 'KE'), isNull);
      expect(whatsAppNumber('9876543210', shopCountry: 'AE'), isNull,
          reason: 'never India\'s code for a shop that is not in India');
    });
  });

  test('nothing to dial is null, not an empty number', () {
    expect(whatsAppNumber('', shopCountry: 'IN'), isNull);
    expect(whatsAppNumber('  -  ', shopCountry: 'KE'), isNull);
  });
}
