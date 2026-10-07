// test/money_format_test.dart — the same number, read correctly in two
// places that disagree about what "correctly" means.
//
// India groups the last three digits then pairs off: 12,34,567. Almost
// everywhere else groups in threes: 1,234,567. A shopkeeper reads the
// wrong one as a different number, which on a bill is not a cosmetic
// problem.
//
// money.dart carries the active currency in module state because it is
// on the hot path of every list row. That makes it the kind of thing
// that silently stays set from a previous screen, so these tests reset
// it explicitly rather than trusting order.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:billzap/design/money.dart';
import 'package:billzap/utils/smart_amount.dart';

void main() {
  setUp(() => setActiveCurrency(
      symbol: '₹', grouping: MoneyGrouping.indian));

  group('digit grouping', () {
    test('India pairs off above the last three', () {
      expect(formatIndianDigits(1234567, decimals: 0), '12,34,567');
      expect(formatIndianDigits(100000, decimals: 0), '1,00,000');
      expect(formatIndianDigits(1000, decimals: 0), '1,000');
      expect(formatIndianDigits(999, decimals: 0), '999');
    });

    test('everywhere else groups in threes', () {
      setActiveCurrency(symbol: r'$', grouping: MoneyGrouping.western);
      expect(formatIndianDigits(1234567, decimals: 0), '1,234,567');
      expect(formatIndianDigits(100000, decimals: 0), '100,000');
      expect(formatIndianDigits(1000, decimals: 0), '1,000');
      expect(formatIndianDigits(999, decimals: 0), '999');
    });

    test('decimals and sign survive both rules', () {
      expect(formatIndianDigits(-1234567.5), '-12,34,567.50');
      setActiveCurrency(symbol: r'$', grouping: MoneyGrouping.western);
      expect(formatIndianDigits(-1234567.5), '-1,234,567.50');
    });
  });

  group('short form', () {
    test('India uses lakh and crore', () {
      expect(formatMoneyShort(150000), '1.5L');
      expect(formatMoneyShort(25000000), '2.5Cr');
      expect(formatMoneyShort(5000), '5.0K');
    });

    test('elsewhere uses M and B, because nobody reads crore', () {
      setActiveCurrency(symbol: r'$', grouping: MoneyGrouping.western);
      expect(formatMoneyShort(1500000), '1.5M');
      expect(formatMoneyShort(2500000000), '2.5B');
      expect(formatMoneyShort(5000), '5.0K');
      // 150K, not 150.0K: the ladder drops the decimal above 10K
      // because a stat tile has no room for a digit that says nothing.
      expect(formatMoneyShort(150000), '150K',
          reason: 'must NOT say 1.5L outside India');
    });
  });

  group('the symbol follows the country', () {
    test('defaults to the rupee, so an untouched install is unchanged', () {
      expect(activeCurrencySymbol, '₹');
      expect(activeGrouping, MoneyGrouping.indian);
    });

    test('and changes when the shop does', () {
      setActiveCurrency(symbol: 'AED ', grouping: MoneyGrouping.western);
      expect(activeCurrencySymbol, 'AED ');
      expect(activeGrouping, MoneyGrouping.western);
    });
  });

  group('large amounts stay readable', () {
    tearDown(() => setActiveCurrency(
        symbol: '\u20B9', grouping: MoneyGrouping.indian));

    test('the ladder reaches past a billion', () {
      setActiveCurrency(symbol: r'$', grouping: MoneyGrouping.western);
      // The exact figure from the bug report: 14 x 999,999,999,999,999.
      // It used to render "14000000B" — seven digits in front of a
      // unit, no shorter and no clearer than the number itself.
      expect(formatMoneyShort(13999999999999986), '14,000T');
      expect(formatMoneyShort(2500000000000), '2.5T');
      expect(formatMoneyShort(1000000000000), '1.0T');
    });

    test('South Asia counts in lakh crore, not trillions', () {
      setActiveCurrency(
          symbol: '\u20B9', grouping: MoneyGrouping.indian);
      expect(formatMoneyShort(1000000000000), '1.0L Cr');
      expect(formatMoneyShort(13999999999999986), '14,000L Cr');
    });

    test('a short form is always shorter than the number it replaces', () {
      // The property that "14000000B" violated: it was no shorter than
      // 13,999,999,999,999,986 in any sense that matters, and harder
      // to read. Walked across the whole plausible range in both
      // conventions rather than spot-checked, because the failure was
      // at a magnitude nobody thought to try.
      for (final grouping in MoneyGrouping.values) {
        setActiveCurrency(symbol: r'$', grouping: grouping);
        for (var exp = 0; exp <= 18; exp++) {
          final v = 1.4 * pow(10, exp);
          final short = formatMoneyShort(v);
          final full = formatIndianDigits(v, decimals: 0);
          expect(short.length, lessThanOrEqualTo(full.length),
              reason: '$grouping 1.4e$exp: "$short" vs "$full"');

          // And the mantissa never becomes a run of digits. Seven is
          // the worst case, at 1.4e18 — a figure no invoice reaches,
          // and it still reads as 1,400,000T rather than 1400000T.
          final digits = short.replaceAll(RegExp(r'[^0-9]'), '');
          expect(digits.length, lessThanOrEqualTo(7),
              reason: '$grouping 1.4e$exp rendered as "$short"');
        }
      }
    });

    test('the sign survives the ladder', () {
      setActiveCurrency(symbol: r'$', grouping: MoneyGrouping.western);
      expect(formatMoneyShort(-2500000000000), '-2.5T');
      expect(formatMoneyShort(-1500), '-1.5K');
    });
  });

  group('the amount field refuses what a double cannot hold', () {
    test('twelve digits is accepted, thirteen is not', () {
      // A trillion dong is roughly forty million dollars, so twelve
      // digits clears any real invoice line in any currency.
      expect(SmartAmountFormatter.withinLimit('999999999999'), isTrue);
      expect(SmartAmountFormatter.withinLimit('9999999999999'), isFalse);
      expect(SmartAmountFormatter.withinLimit('999999999999999'), isFalse,
          reason: 'the fifteen nines that started this');
    });

    test('decimals do not count against the limit', () {
      // Precision is lost in the integer part, not the fraction.
      expect(SmartAmountFormatter.withinLimit('999999999999.99'), isTrue);
    });

    test('the cap sits below the exact-integer limit of a double', () {
      // Above 2^53 a double can no longer represent every whole
      // number, which is the actual reason for the cap.
      final cap = pow(10, SmartAmountFormatter.maxIntegerDigits).toDouble();
      expect(cap, lessThan(pow(2, 53)));
    });

    test('a short amount is untouched', () {
      expect(SmartAmountFormatter.withinLimit('50'), isTrue);
      expect(SmartAmountFormatter.withinLimit(''), isTrue);
    });
  });
}
