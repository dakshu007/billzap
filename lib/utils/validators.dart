// lib/utils/validators.dart
// Lightweight field validators used by Settings and other forms.
// Returns null if valid, else a short user-facing error message.
//
// Every rule here used to be India's rule, applied to everybody. That
// is not a cosmetic problem: a shopkeeper in Lagos could not save a
// customer, because a Nigerian mobile number does not start 6-9 and is
// not ten digits, so the field refused it and there was no way round.
// A validator that rejects correct input is worse than no validator.
//
// So each one now asks which country the shop is in first. India keeps
// its exact rules — a real GSTIN check is worth having, and nothing
// about the Indian experience changes. Everywhere else the rule falls
// back to the loosest one that still catches a typo: a shape check,
// not a national format we have not researched.
//
// The honest default outside India is permissive. We do not know what a
// valid tax number looks like in 170 countries, and guessing would
// block real traders.

import '../tax/active_profile.dart';

class Validators {
  Validators._();

  /// True when the shop is trading in India, which is the only country
  /// whose formats this file actually knows.
  static bool get _india => activeProfile.countryCode == 'IN';

  /// India GSTIN: 15 chars. 2-digit state code, 10-char PAN, entity, Z, check.
  /// Pattern: 2 digits + 5 letters + 4 digits + 1 letter + 1 digit/letter + Z + 1 digit/letter.
  static final RegExp _gstin = RegExp(
    r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
  );

  /// UPI VPA: name@bank, allows dots/underscores/dashes in the local part.
  static final RegExp _vpa = RegExp(
    r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$',
  );

  static final RegExp _ifsc = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
  static final RegExp _pincode = RegExp(r'^[1-9][0-9]{5}$');
  static final RegExp _phone = RegExp(r'^[6-9][0-9]{9}$');
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// A tax number anywhere else: letters, digits, dashes and spaces,
  /// long enough to be one and short enough not to be a sentence. A
  /// UK VRN is 9 digits, an EU VAT number up to 14 with a country
  /// prefix, a Brazilian CNPJ 14 — this admits all of them.
  static final RegExp _taxIdLoose = RegExp(r'^[A-Z0-9][A-Z0-9 \-/.]{3,24}$');

  /// A phone number anywhere else. Digits only once the punctuation is
  /// stripped; the ITU caps a national number at 15 digits and the
  /// shortest real ones are 7.
  static final RegExp _phoneLoose = RegExp(r'^[0-9]{7,15}$');

  /// A postal code anywhere else. Letters are not optional: a Canadian
  /// code is K1A 0B1 and a Dutch one is 1234 AB.
  static final RegExp _postalLoose = RegExp(r'^[A-Z0-9][A-Z0-9 \-]{1,10}$');

  /// The seller's or customer's tax registration number.
  ///
  /// India gets the real GSTIN check. Everywhere else gets a shape
  /// check and the country's own name for the field, because telling a
  /// Spanish trader their NIF "must be 15 characters" is both wrong
  /// and unactionable.
  static String? gstin(String? raw) {
    final v = (raw ?? '').trim().toUpperCase();
    if (v.isEmpty) return null;
    if (_india) {
      if (v.length != 15) return 'GSTIN must be 15 characters';
      if (!_gstin.hasMatch(v)) return 'Invalid GSTIN format';
      return null;
    }
    if (!_taxIdLoose.hasMatch(v)) return 'Invalid $activeTaxIdLabel';
    return null;
  }

  static String? upi(String? raw) {
    final v = (raw ?? '').trim();
    if (v.isEmpty) return null;
    if (!_vpa.hasMatch(v)) return 'Should look like name@bank';
    return null;
  }

  /// An IFSC code is an Indian bank routing code and nothing else. In
  /// another country the same field holds a SWIFT/BIC, a sort code, a
  /// routing number — all different shapes — so it is not validated
  /// rather than validated wrongly.
  static String? ifsc(String? raw) {
    final v = (raw ?? '').trim().toUpperCase();
    if (v.isEmpty || !_india) return null;
    if (!_ifsc.hasMatch(v)) return 'Invalid IFSC (e.g. SBIN0001234)';
    return null;
  }

  static String? pincode(String? raw) {
    final v = (raw ?? '').trim();
    if (v.isEmpty) return null;
    if (_india) {
      if (!_pincode.hasMatch(v)) return 'Invalid 6-digit pincode';
      return null;
    }
    if (!_postalLoose.hasMatch(v.toUpperCase())) return 'Invalid postal code';
    return null;
  }

  /// A phone number.
  ///
  /// The India rule — ten digits starting 6-9, with an optional 91
  /// country code — is kept exactly, because it catches the typo it
  /// was written for. Elsewhere, brackets and dots are stripped too
  /// (a US number is often written (555) 010-9999) and anything of a
  /// plausible length passes.
  static String? phone(String? raw) {
    final v = (raw ?? '').replaceAll(RegExp(r'[\s+\-().]'), '');
    if (v.isEmpty) return null;
    if (_india) {
      final stripped =
          v.startsWith('91') && v.length == 12 ? v.substring(2) : v;
      if (!_phone.hasMatch(stripped)) return 'Invalid Indian mobile number';
      return null;
    }
    if (!_phoneLoose.hasMatch(v)) return 'Invalid phone number';
    return null;
  }

  static String? email(String? raw) {
    final v = (raw ?? '').trim();
    if (v.isEmpty) return null;
    if (!_email.hasMatch(v)) return 'Invalid email';
    return null;
  }

  static String? required(String? raw, {String field = 'Field'}) {
    if ((raw ?? '').trim().isEmpty) return '$field is required';
    return null;
  }
}
