// lib/utils/validators.dart
// Lightweight field validators used by Settings and other forms.
// Returns null if valid, else a short user-facing error message.

class Validators {
  Validators._();

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

  static String? gstin(String? raw) {
    final v = (raw ?? '').trim().toUpperCase();
    if (v.isEmpty) return null;
    if (v.length != 15) return 'GSTIN must be 15 characters';
    if (!_gstin.hasMatch(v)) return 'Invalid GSTIN format';
    return null;
  }

  static String? upi(String? raw) {
    final v = (raw ?? '').trim();
    if (v.isEmpty) return null;
    if (!_vpa.hasMatch(v)) return 'Should look like name@bank';
    return null;
  }

  static String? ifsc(String? raw) {
    final v = (raw ?? '').trim().toUpperCase();
    if (v.isEmpty) return null;
    if (!_ifsc.hasMatch(v)) return 'Invalid IFSC (e.g. SBIN0001234)';
    return null;
  }

  static String? pincode(String? raw) {
    final v = (raw ?? '').trim();
    if (v.isEmpty) return null;
    if (!_pincode.hasMatch(v)) return 'Invalid 6-digit pincode';
    return null;
  }

  static String? phone(String? raw) {
    final v = (raw ?? '').replaceAll(RegExp(r'[\s+\-]'), '');
    if (v.isEmpty) return null;
    final stripped = v.startsWith('91') && v.length == 12 ? v.substring(2) : v;
    if (!_phone.hasMatch(stripped)) return 'Invalid Indian mobile number';
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
