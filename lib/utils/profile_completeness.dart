// lib/utils/profile_completeness.dart
// Calculates how complete the business profile is (0-100%)
// and returns a human-readable list of what's missing.

import '../i18n/translations.dart';
import '../models/models.dart';

class ProfileCompleteness {
  // Field weights (must sum to 100)
  static const _weights = {
    'name': 40,
    'phone': 15,
    'gstin': 10,
    'address': 7,
    'city': 4,
    'state': 4,
    'upiId': 20,
  };

  /// Returns 0-100 score
  static int score(Business? biz) {
    if (biz == null) return 0;
    int total = 0;
    if (biz.name.trim().isNotEmpty) total += _weights['name']!;
    if (biz.phone.trim().isNotEmpty) total += _weights['phone']!;
    if (biz.gstin.trim().isNotEmpty) total += _weights['gstin']!;
    if (biz.address.trim().isNotEmpty) total += _weights['address']!;
    if (biz.city.trim().isNotEmpty) total += _weights['city']!;
    if (biz.state.trim().isNotEmpty && biz.state != 'Tamil Nadu') {
      // Default state is 'Tamil Nadu' so we count it as filled even if just the default
      total += _weights['state']!;
    } else if (biz.state.trim().isNotEmpty) {
      total += _weights['state']!;
    }
    if (biz.upiId.trim().isNotEmpty) total += _weights['upiId']!;
    return total;
  }

  /// Returns true if profile is "ready" (>= 80% complete)
  static bool isComplete(Business? biz) => score(biz) >= 80;

  /// Returns true if business is essentially empty (< 40% means name is missing)
  static bool isEmpty(Business? biz) => score(biz) < 40;

  /// Returns a list of human-readable missing field labels (for the banner)
  static List<String> missingLabels(Business? biz) {
    final missing = <String>[];
    if (biz == null) {
      return [
        trGlobal('pc.business_name'),
        trGlobal('pc.phone'),
        trGlobal('pc.address'),
        trGlobal('pc.upi'),
      ];
    }
    if (biz.name.trim().isEmpty) missing.add(trGlobal('pc.business_name'));
    if (biz.phone.trim().isEmpty) missing.add(trGlobal('pc.phone'));
    if (biz.upiId.trim().isEmpty) missing.add(trGlobal('pc.upi'));
    if (biz.address.trim().isEmpty) missing.add(trGlobal('pc.address'));
    return missing;
  }

  /// Top 1-2 most impactful missing fields (for short banner text)
  static String topMissing(Business? biz) {
    if (biz == null) return trGlobal('dash.setup_profile');
    final missing = missingLabels(biz);
    if (missing.isEmpty) return '';
    if (missing.length == 1) return trGlobal('pc.add_one', {'a': missing.first});
    if (missing.length == 2) {
      return trGlobal('pc.add_two', {'a': missing[0], 'b': missing[1]});
    }
    return trGlobal('pc.add_more', {'a': missing[0], 'b': missing[1]});
  }
}
