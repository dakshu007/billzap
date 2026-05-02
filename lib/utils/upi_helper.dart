// lib/utils/upi_helper.dart
// Generates UPI deep links for payment collection.
// Format: upi://pay?pa=VPA&pn=NAME&am=AMOUNT&cu=INR&tn=NOTE

class UpiHelper {
  /// Builds a UPI deep link that opens any UPI app (PhonePe/GPay/Paytm/BHIM/etc).
  ///
  /// [vpa] — the payee's UPI ID (e.g. "ravi@okaxis")
  /// [name] — payee/business name (will be shown in UPI app)
  /// [amount] — exact amount to pay (in rupees)
  /// [note] — transaction note (typically the invoice number)
  static String buildLink({
    required String vpa,
    required String name,
    required double amount,
    required String note,
  }) {
    final params = <String, String>{
      'pa': vpa.trim(),
      'pn': name.trim(),
      'am': amount.toStringAsFixed(2),
      'cu': 'INR',
      'tn': note.trim(),
    };

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'upi://pay?$query';
  }

  /// Validates a UPI VPA format.
  /// Valid: ravi@okaxis, business123@paytm, name.surname@upi
  /// Invalid: ravi, ravi@, @okaxis
  static bool isValidVpa(String vpa) {
    if (vpa.isEmpty) return false;
    final pattern = RegExp(r'^[a-zA-Z0-9._-]{2,256}@[a-zA-Z]{2,64}$');
    return pattern.hasMatch(vpa.trim());
  }
}
