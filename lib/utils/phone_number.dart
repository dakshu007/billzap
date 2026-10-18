// lib/utils/phone_number.dart — a customer's number, as WhatsApp wants it.

/// The full international number for a wa.me link, digits only, or null
/// when it cannot be known.
///
/// This used to put 91 in front of every number that did not already
/// start with it — India's country code, for every shop in the world.
/// A Nairobi number typed as 0712 345678 became 910712345678, which is
/// somebody in India. Now:
///
///   +254 712 345678   → 254712345678   (typed with a +: trust it)
///   00254 712 345678  → 254712345678
///   98765 43210 in an Indian shop → 919876543210   (as it always was)
///   098765 43210 in an Indian shop → 919876543210
///   0712 345678 anywhere else    → null
///
/// Null means "let the shopkeeper pick the contact in WhatsApp" — a
/// message to the wrong person is worse than one extra tap.
String? whatsAppNumber(String raw, {required String shopCountry}) {
  final t = raw.trim();
  final digits = t.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  if (t.startsWith('+')) return digits;
  if (digits.startsWith('00') && digits.length > 4) return digits.substring(2);
  if (shopCountry.toUpperCase() == 'IN') {
    if (digits.length == 10) return '91$digits';
    if (digits.length == 11 && digits.startsWith('0')) {
      return '91${digits.substring(1)}'; // trunk prefix
    }
    return digits.startsWith('91') ? digits : '91$digits';
  }
  return null;
}
