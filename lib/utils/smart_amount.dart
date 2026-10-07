// lib/utils/smart_amount.dart
// TextInputFormatter that converts shorthand into full numbers as the user types.
//
// Examples (typing flow shown character by character):
//   "1k"   → "1" → "1000"          (k triggers immediately)
//   "2.5k" → "2" → "2." → "2.5" → "2500"
//   "1L"   → "1" → "100000"        (L triggers immediately)
//   "1.5L" → "1" → "1." → "1.5" → "150000"
//   "1cr"  → "1" → "1c" → "10000000"   (waits for 'r' after 'c')
//   "5C"   → "5" → "50000000"      (uppercase C = crore, 1-char shortcut)
//   "100"  → "1" → "10" → "100"    (plain numbers untouched)
//
// Multipliers (Indian conventions):
//   k/K     = 1,000 (thousand)
//   l/L     = 1,00,000 (lakh)
//   cr / C  = 1,00,00,000 (crore)
//   c alone = pass-through (user might be typing "cr")

import 'package:flutter/services.dart';

class SmartAmountFormatter extends TextInputFormatter {
  static const double _kMultiplier = 1000;
  static const double _lMultiplier = 100000;
  static const double _crMultiplier = 10000000;

  /// The most digits an amount may have before the decimal point.
  ///
  /// Twelve, which is a trillion — comfortably more than any real
  /// invoice line in any currency, including the ones with small
  /// units: a line of a trillion Vietnamese dong is about forty
  /// million US dollars.
  ///
  /// The cap exists because money here is a `double`, and a double
  /// stops being able to represent every whole number above 2^53, or
  /// about 9,007 trillion. A tester typing fifteen nines produced a
  /// sixteen-digit total that no longer survives a round trip, on a
  /// document whose entire purpose is to state an exact amount. Better
  /// to refuse the keystroke than to print a number the app cannot
  /// hold.
  static const int maxIntegerDigits = 12;

  /// Whether [text] stays within the digit cap, judged on the integer
  /// part only — decimals do not cost precision at this scale.
  static bool withinLimit(String text) {
    final digits = text.split('.').first.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length <= maxIntegerDigits;
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    // Refuse the keystroke that would take the amount past what a
    // double can hold exactly. Checked before the shorthand expands,
    // and again after, because "9999999999999k" is three keystrokes
    // away from an unrepresentable number.
    if (!withinLimit(text)) return oldValue;

    // Allow only digits, dot, k/K/l/L/c/C, r/R
    final validChars = RegExp(r'^[0-9.kKlLcCrR]*$');
    if (!validChars.hasMatch(text)) {
      return oldValue; // reject invalid input
    }

    final lastChar = text[text.length - 1];

    // 'r'/'R' is a trigger ONLY if preceded by 'c'/'C' — completes "cr" suffix
    if (lastChar == 'r' || lastChar == 'R') {
      if (text.length >= 2 &&
          (text[text.length - 2] == 'c' || text[text.length - 2] == 'C')) {
        final numberPart = text.substring(0, text.length - 2);
        return _convert(numberPart, _crMultiplier, oldValue);
      }
      // 'r' without preceding 'c' — invalid
      return oldValue;
    }

    // 'c' (lowercase) alone is NOT a trigger — pass through so user can type 'r' next
    if (lastChar == 'c') {
      return newValue;
    }

    // 'C' (uppercase) is the 1-character crore shortcut — trigger immediately
    if (lastChar == 'C') {
      final numberPart = text.substring(0, text.length - 1);
      return _convert(numberPart, _crMultiplier, oldValue);
    }

    // 'k'/'K' = thousand
    if (lastChar == 'k' || lastChar == 'K') {
      final numberPart = text.substring(0, text.length - 1);
      return _convert(numberPart, _kMultiplier, oldValue);
    }

    // 'l'/'L' = lakh
    if (lastChar == 'l' || lastChar == 'L') {
      final numberPart = text.substring(0, text.length - 1);
      return _convert(numberPart, _lMultiplier, oldValue);
    }

    // Digits or '.' — pass through (intermediate state like "2.")
    return newValue;
  }

  TextEditingValue _convert(
      String numberPart, double multiplier, TextEditingValue fallback) {
    if (numberPart.isEmpty) return fallback;
    final value = double.tryParse(numberPart);
    if (value == null) return fallback;

    final result = value * multiplier;

    // Format: integer if whole, otherwise up to 2 decimals
    final String formatted;
    if (result == result.truncateToDouble()) {
      formatted = result.toInt().toString();
    } else {
      formatted = result.toStringAsFixed(2);
    }

    // The shorthand multiplies, so a value inside the cap before
    // expansion can land outside it after — "99999999999k" is twelve
    // digits typed and fifteen stored.
    if (!withinLimit(formatted)) return fallback;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
