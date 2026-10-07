// test/business_address_country_test.dart
//
// A trader in Japan opened Settings and was asked to pick between
// Tamil Nadu and West Bengal. The business address had no country of
// its own, so the region field fell back to India's states for
// everybody.
//
// The address country is a separate question from the trading country.
// They are the same for almost everyone, which is why the address one
// defaults to the other — but a business registered in one country
// with premises in another has one of each, and the app has to be able
// to say so.

import 'package:flutter_test/flutter_test.dart';
import 'package:billzap/models/models.dart';
import 'package:billzap/tax/regions.dart';

void main() {
  group('the address country defaults to the trading country', () {
    test('an empty address country means "same as where I trade"', () {
      final b = Business(countryCode: 'JP');
      expect(b.addressCountryCode, '');
      expect(b.effectiveAddressCountry, 'JP');
    });

    test('and follows it when the trading country changes', () {
      final b = Business(countryCode: 'JP').copyWith(countryCode: 'KE');
      expect(b.effectiveAddressCountry, 'KE',
          reason: 'an unset address country must not pin to the old one');
    });

    test('but an explicit one wins', () {
      // Registered in Singapore, premises in Malaysia.
      final b = Business(countryCode: 'SG', addressCountryCode: 'MY');
      expect(b.effectiveAddressCountry, 'MY');
      expect(b.countryCode, 'SG', reason: 'the tax country is untouched');
    });

    test('a profile saved before the field existed reads as "same"', () {
      final b = Business.fromMap({
        'name': 'Legacy Shop',
        'countryCode': 'IN',
        'state': 'Tamil Nadu',
      });
      expect(b.addressCountryCode, '');
      expect(b.effectiveAddressCountry, 'IN');
    });

    test('it round-trips through storage', () {
      final b = Business(countryCode: 'SG', addressCountryCode: 'MY');
      expect(Business.fromMap(b.toMap()).addressCountryCode, 'MY');
    });
  });

  group('the region list follows the address country', () {
    test('Japan offers prefectures, not Indian states', () {
      final jp = regionsFor('JP')!;
      expect(jp, contains('Tokyo'));
      expect(jp, contains('Osaka'));
      expect(jp, isNot(contains('Tamil Nadu')));
      expect(jp, isNot(contains('West Bengal')));
    });

    test('India still offers its own, with the GST codes intact', () {
      // regionsFor deliberately has no India row: kStates carries the
      // codes that the intra/inter split and GSTR-1 parse back out.
      expect(regionsFor('IN'), isNull);
      expect(kStates, contains('Tamil Nadu (33)'));
      expect(kStates, contains('Goa (30)'));
    });
  });

  group('India has every GST jurisdiction', () {
    test('all 37, which is 28 states plus 8 territories plus Other', () {
      // The list held twenty. A shopkeeper in Goa, Chhattisgarh,
      // Uttarakhand, Puducherry or any north-eastern state could not
      // select where they trade — and that field decides CGST/SGST
      // against IGST, so picking a neighbour to get past it would have
      // produced the wrong split.
      expect(kStates.length, 37);
      expect(kStateMap.length, 37);
      for (final name in [
        'Goa', 'Chhattisgarh', 'Uttarakhand', 'Puducherry', 'Sikkim',
        'Manipur', 'Meghalaya', 'Mizoram', 'Nagaland', 'Tripura',
        'Arunachal Pradesh', 'Jammu & Kashmir', 'Ladakh', 'Lakshadweep',
        'Andaman & Nicobar Islands',
      ]) {
        expect(kStateMap.containsKey(name), isTrue,
            reason: '$name is a GST jurisdiction and was missing');
      }
    });

    test('every entry carries its code and the two lists agree', () {
      for (final entry in kStates) {
        final name = entry.split(' (').first;
        final code = entry.split(' (').last.replaceAll(')', '');
        expect(kStateMap[name], code,
            reason: '$entry disagrees with kStateMap');
        expect(code.length, 2, reason: entry);
      }
      expect(kStateMap.keys.toSet(),
          kStates.map((s) => s.split(' (').first).toSet());
    });

    test('codes are unique, and the retired ones are absent', () {
      final codes = kStateMap.values.toList();
      expect(codes.toSet().length, codes.length, reason: 'duplicate code');
      // 25 was Daman & Diu before the 2020 merger into 26; 28 was the
      // undivided Andhra Pradesh before Telangana.
      expect(codes, isNot(contains('25')));
      expect(codes, isNot(contains('28')));
    });

    test('sorted by name, so the picker is navigable', () {
      final names = kStates.map((s) => s.split(' (').first).toList();
      expect(names, [...names]..sort());
    });
  });
}
