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

import 'package:flutter_test/flutter_test.dart';
import 'package:billzap/design/money.dart';

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
}
