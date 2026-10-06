// lib/tax/tax_engine.dart — the arithmetic, with no country in it.
//
// Pure Dart: no Flutter, no storage, no clock. That is deliberate. Tax
// arithmetic is the one part of a billing app where a silent wrong
// answer is worse than a crash, because the shopkeeper files it and
// finds out months later. Keeping it free of dependencies is what makes
// it exhaustively testable.
//
// The sequencing below reproduces what lib/models/models.dart already
// does for India, line for line. That is not an accident and it is not
// negotiable: tax_golden_test.dart asserts the two agree to the bit on
// the same inputs. A refactor of a billing engine that quietly changes
// anybody's totals is a bug no matter how much cleaner it reads.

import 'tax_profile.dart';

/// One line of a bill, reduced to what the arithmetic needs.
class TaxLine {
  const TaxLine({
    required this.quantity,
    required this.unitPrice,
    required this.ratePercent,
    this.taxed = true,
  });

  final double quantity;
  final double unitPrice;

  /// The tax rate for this line, as a percentage.
  final double ratePercent;

  /// False for an exempt or zero-rated line. Distinct from a 0% rate
  /// only in intent; both produce no tax.
  final bool taxed;

  double get taxable => quantity * unitPrice;
  double get tax => taxed ? taxable * ratePercent / 100 : 0;
}

/// Where a discount and a delivery charge sit relative to the tax.
///
/// This is a policy, not a detail. Taking a discount off before tax
/// reduces the tax collected; taking it off after does not. The two
/// give different answers on the same bill and different liabilities
/// for the shopkeeper.
///
/// [afterTax] is what BillZap has always done. It is the default here
/// only so that migrating to this engine changes nobody's existing
/// invoices — not because it is the better rule. See the note in
/// README-tax.md about which one India actually expects.
enum AdjustmentTiming { beforeTax, afterTax }

/// A finished bill, broken out the way it has to be printed.
class TaxBreakdown {
  const TaxBreakdown({
    required this.subtotal,
    required this.taxTotal,
    required this.components,
    required this.shipping,
    required this.discount,
    required this.grandTotal,
  });

  /// Sum of the lines before tax, after any before-tax discount.
  final double subtotal;
  final double taxTotal;

  /// Tax split into the named lines the country's bill must show, in
  /// profile order — {'CGST': 90.0, 'SGST': 90.0} or {'VAT': 180.0}.
  final Map<String, double> components;

  final double shipping;
  final double discount;
  final double grandTotal;

  @override
  String toString() => 'TaxBreakdown(subtotal: $subtotal, tax: $taxTotal, '
      'components: $components, total: $grandTotal)';
}

class TaxEngine {
  const TaxEngine(this.profile);

  final TaxProfile profile;

  /// Compute a whole bill.
  ///
  /// [scope] is ignored unless the profile says the region matters, so
  /// a caller in a flat-VAT country can pass anything and get the right
  /// answer rather than having to know whether the question applies.
  TaxBreakdown compute(
    List<TaxLine> lines, {
    SupplyScope scope = SupplyScope.intra,
    double shipping = 0,
    double discount = 0,
    AdjustmentTiming timing = AdjustmentTiming.afterTax,
  }) {
    final gross = lines.fold<double>(0, (s, l) => s + l.taxable);

    // Before-tax timing reduces the base every line is taxed on, in
    // proportion to that line's share of the bill. Done any other way
    // — all of it against the first line, say — a bill with two
    // different rates would collect the wrong amounts on both.
    double factor = 1;
    if (timing == AdjustmentTiming.beforeTax && discount > 0 && gross > 0) {
      factor = ((gross - discount) / gross).clamp(0.0, 1.0);
    }

    final subtotal = gross * factor;
    final taxTotal = lines.fold<double>(0, (s, l) => s + l.tax * factor);

    final components = <String, double>{};
    for (final c in profile.componentsFor(scope)) {
      // += rather than =, so a profile that names the same label twice
      // accumulates instead of silently dropping the first one.
      components[c.label] = (components[c.label] ?? 0) + taxTotal * c.share;
    }

    final grandTotal = timing == AdjustmentTiming.beforeTax
        ? subtotal + taxTotal + shipping
        : subtotal + taxTotal + shipping - discount;

    return TaxBreakdown(
      subtotal: subtotal,
      taxTotal: taxTotal,
      components: components,
      shipping: shipping,
      discount: discount,
      grandTotal: grandTotal,
    );
  }

  /// Group digits the way the currency expects, on the integer part.
  ///
  /// India groups the last three then in twos — 12,34,567 — and a shop
  /// owner reads 1,234,567 as a different number. Everything else
  /// groups in threes.
  static String groupDigits(String digits, NumberGrouping grouping) {
    if (digits.length <= 3) return digits;
    if (grouping == NumberGrouping.western) {
      final out = StringBuffer();
      for (var i = 0; i < digits.length; i++) {
        if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
        out.write(digits[i]);
      }
      return out.toString();
    }
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${parts.join(',')},$last3';
  }

  /// Format an amount with the profile's symbol and grouping.
  String format(double amount, {bool withSymbol = true}) {
    final negative = amount < 0;
    final fixed = amount.abs().toStringAsFixed(2);
    final dot = fixed.indexOf('.');
    final whole = fixed.substring(0, dot);
    final fraction = fixed.substring(dot + 1);
    final grouped = groupDigits(whole, profile.grouping);
    final sign = negative ? '-' : '';
    final symbol = withSymbol ? profile.currencySymbol : '';
    return '$sign$symbol$grouped.$fraction';
  }
}
