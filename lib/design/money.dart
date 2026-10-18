// lib/design/money.dart
//
// Money rendering. This is the most important file in the design system.
//
// A billing app is judged on its numbers. Three rules, applied everywhere:
//
//  1. TABULAR FIGURES. Every digit occupies the same advance width, so a
//     column of totals lines up and a live-updating total never shifts
//     the layout as digits change. Proportional figures are what make
//     most billing apps feel amateur.
//
//  2. THE RUPEE SIGN IS NOT A DIGIT. It is set smaller and lighter than
//     the amount, and sits on the amount's baseline. Rendering "₹" at the
//     same weight as the number makes the number harder to scan.
//
//  3. INDIAN DIGIT GROUPING. 12,34,567 — not 1,234,567. Getting this
//     wrong is the single fastest way to look foreign to the user.

import 'package:flutter/material.dart';

import '../tax/tax_profile.dart';

import 'tokens.dart';
import 'theme.dart';

// ── The active currency ─────────────────────────────────────────────
//
// Money renders every amount in the app, from a dashboard hero figure to
// a line item in a list, and it used to hardcode the rupee glyph and
// Indian grouping. Making it a ConsumerWidget would have meant touching
// all 37 call sites and putting a provider read on the hot path of every
// row of every list.
//
// Instead the same shape the i18n layer already uses: a module-level
// value that a provider keeps current. taxProfileProvider calls
// setActiveCurrency whenever the shop's country changes, and every Money
// built afterwards picks it up. The default is the rupee, so an install
// that never touches the setting behaves exactly as it always did.

/// Whether a currency groups digits in threes or the Indian way.
enum MoneyGrouping { western, indian }

String _symbol = '\u20B9';
MoneyGrouping _grouping = MoneyGrouping.indian;

/// Called by taxProfileProvider. Not for screens to call directly.
void setActiveCurrency({required String symbol, required MoneyGrouping grouping}) {
  _symbol = symbol;
  _grouping = grouping;
}

String get activeCurrencySymbol => _symbol;
MoneyGrouping get activeGrouping => _grouping;

/// The grouping a given country's amounts use, independent of whatever
/// the shop is set to right now.
///
/// Needed when formatting a *stored* amount rather than a live one: a
/// rupee invoice written last year must reprint as 12,34,567 even after
/// the shop has moved to Dubai. The country list lives in
/// tax_profile.dart so there is one answer, not two.
MoneyGrouping groupingForCountry(String countryCode) =>
    groupingFor(countryCode) == NumberGrouping.indian
        ? MoneyGrouping.indian
        : MoneyGrouping.western;

/// Formats a number in the Indian grouping system (lakh / crore).
///
/// `intl`'s en_IN locale can do this, but this is on the hot path for
/// every row of every list, so a direct implementation avoids the
/// per-call locale lookup.
/// [grouping] overrides the shop's current setting, for the one case
/// that needs it: formatting an amount that was *stored* under
/// different settings. Omit it and every live call behaves as before.
String formatIndianDigits(num value, {int decimals = 2, MoneyGrouping? grouping}) {
  final negative = value < 0;
  final abs = value.abs();
  final mode = grouping ?? _grouping;

  final fixed = abs.toStringAsFixed(decimals);
  final parts = fixed.split('.');
  var whole = parts[0];
  final fraction = parts.length > 1 ? parts[1] : '';

  // Outside India, group in threes. The function keeps its name because
  // it is called from 37 places and the Indian path is still the one
  // that needed hand-writing; the western path is the ordinary rule.
  if (mode == MoneyGrouping.western && whole.length > 3) {
    final buf = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
      buf.write(whole[i]);
    }
    final body = fraction.isEmpty ? buf.toString() : '$buf.$fraction';
    return negative ? '-$body' : body;
  }

  // Last three digits stay together; everything above pairs off.
  String grouped;
  if (whole.length <= 3) {
    grouped = whole;
  } else {
    final last3 = whole.substring(whole.length - 3);
    var rest = whole.substring(0, whole.length - 3);
    final buf = <String>[];
    while (rest.length > 2) {
      buf.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) buf.insert(0, rest);
    grouped = '${buf.join(',')},$last3';
  }

  final body = fraction.isEmpty ? grouped : '$grouped.$fraction';
  return negative ? '-$body' : body;
}

/// Drops a trailing `.00` — a shop's prices are usually whole rupees, and
/// the noise adds up across a dense list.
String formatMoneyCompact(num value, {MoneyGrouping? grouping}) {
  final whole = value == value.roundToDouble();
  return formatIndianDigits(value,
      decimals: whole ? 0 : 2, grouping: grouping);
}

/// Short form for chart axes and dense stat tiles: 1.2L, 3.4Cr, 2.5M.
///
/// The ladder has to reach as far as the numbers do. It used to stop
/// at B, so a dashboard showing a sixteen-digit total rendered it as
/// "14000000B" — seven digits in front of a unit, which is no shorter
/// and no more readable than the number it replaced.
///
/// Each rung is now used only while it keeps the mantissa under four
/// digits, and the top rung groups its digits so even an absurd figure
/// stays legible rather than running off the tile.
String formatMoneyShort(num value) {
  final abs = value.abs();
  final sign = value < 0 ? '-' : '';

  // Each entry is (threshold, divisor, suffix), largest first. Lakh
  // and crore are not units anyone outside the subcontinent reads, and
  // a lakh crore is how South Asia says "ten trillion".
  final rungs = _grouping == MoneyGrouping.indian
      ? const [
          (1e12, 1e12, 'L Cr'),
          (1e7, 1e7, 'Cr'),
          (1e5, 1e5, 'L'),
          (1e3, 1e3, 'K'),
        ]
      : const [
          (1e12, 1e12, 'T'),
          (1e9, 1e9, 'B'),
          (1e6, 1e6, 'M'),
          (1e3, 1e3, 'K'),
        ];

  for (final (threshold, divisor, suffix) in rungs) {
    if (abs < threshold) continue;
    final scaled = abs / divisor;
    // One decimal below ten, none above — 1.2M, but 340M not 340.0M.
    // Past four digits the decimal is noise, and the digits get
    // grouped so the top rung never becomes an unreadable run.
    final body = scaled >= 10000
        ? formatIndianDigits(scaled, decimals: 0)
        : scaled.toStringAsFixed(scaled >= 10 ? 0 : 1);
    return '$sign$body$suffix';
  }
  return '$sign${formatIndianDigits(abs, decimals: 0)}';
}

/// The shop's current currency, as a plain string.
///
/// The live counterpart of [formatStoredMoney], for the places that
/// need text rather than the [Money] widget — a PDF, a CSV header, a
/// share message.
String formatActiveMoney(num value, {bool withSymbol = true, int decimals = 2}) {
  final body = formatIndianDigits(value.abs(), decimals: decimals);
  final sign = value < 0 ? '-' : '';
  return '$sign${withSymbol ? _symbol : ''}$body';
}

/// Format an amount exactly as it was recorded, not as the shop is set
/// up today.
///
/// A bill is a legal record. Reprinting a rupee invoice as dirhams
/// because the shopkeeper has since changed country would be a forged
/// document, so stored amounts carry their own symbol and their own
/// country's grouping. An empty [symbol] means the rupee, which is what
/// every invoice written before BillZap left India was in.
String formatStoredMoney(
  num value, {
  required String symbol,
  required String countryCode,
  bool withSymbol = true,
  int decimals = 2,
}) {
  final glyph = symbol.isEmpty ? '\u20B9' : symbol;
  final body = formatIndianDigits(value.abs(),
      decimals: decimals, grouping: groupingForCountry(countryCode));
  final sign = value < 0 ? '-' : '';
  return '$sign${withSymbol ? glyph : ''}$body';
}

/// How large the ₹ glyph is relative to the amount it prefixes.
const double _symbolRatio = 0.62;

/// A rupee amount, set correctly.
///
/// The symbol is optically reduced and de-emphasised so the eye lands on
/// the figure. Pass [animate] to roll the value when it changes — used on
/// running totals, where watching the number climb is the whole point.
class Money extends StatelessWidget {
  final num value;

  /// A role from [AppType]'s amount ramp.
  final TextStyle style;
  final Color? color;

  /// Hide the ₹ prefix (for a column that already has a currency header).
  final bool showSymbol;

  /// Drop `.00` on whole rupee values.
  final bool compact;

  /// Round to whole rupees. Headline and summary figures use this —
  /// paise on a dashboard total is width without information. Line items
  /// and tax rows keep their decimals.
  final bool round;

  /// Tween to the new value instead of cutting to it.
  final bool animate;

  /// Tint by sign — jade for positive, coral for negative.
  final bool signed;

  final TextAlign? textAlign;

  /// Render in a *stored* currency instead of the shop's current one.
  ///
  /// Only a saved record should pass this — an invoice reprint, a past
  /// receipt. Live figures leave it null and follow the setting.
  final String? storedSymbol;

  /// The country whose digit grouping this stored amount used. Ignored
  /// unless [storedSymbol] is given.
  final String? storedCountryCode;

  /// Shrink the text rather than let it run past its box.
  ///
  /// A hero figure is laid out for a plausible amount, and a shop that
  /// bills in rupiah or dong reaches sixteen digits honestly. Without
  /// this the grand total ran off its pill and the bottom bar cut the
  /// number mid-digit, which on a bill is worse than small type: a
  /// truncated total reads as a smaller, wrong number.
  ///
  /// Needs a bounded width, so it belongs on figures inside an
  /// Expanded, a SizedBox or a padded Container — not in a Row that
  /// sizes itself to its children.
  final bool shrinkToFit;

  const Money(
    this.value, {
    super.key,
    this.style = AppType.amountM,
    this.color,
    this.showSymbol = true,
    this.compact = true,
    this.round = false,
    this.animate = false,
    this.signed = false,
    this.textAlign,
    this.storedSymbol,
    this.storedCountryCode,
    this.shrinkToFit = false,
  });

  Color _resolve() {
    if (color != null) return color!;
    if (!signed) return AppColor.textPrimary;
    if (value > 0) return AppColor.paid;
    if (value < 0) return AppColor.overdue;
    return AppColor.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final fg = _resolve();

    if (!animate) return _fit(_render(value, fg));

    return _fit(TweenAnimationBuilder<double>(
      tween: Tween(begin: value.toDouble(), end: value.toDouble()),
      duration: AppMotion.slow,
      curve: AppMotion.standard,
      builder: (_, v, __) => _render(v, fg),
    ));
  }

  /// scaleDown, not contain: a short amount keeps its designed size and
  /// only a long one shrinks, so the ramp still means something.
  Widget _fit(Widget child) => shrinkToFit
      ? FittedBox(
          fit: BoxFit.scaleDown,
          alignment: textAlign == TextAlign.right
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: child,
        )
      : child;

  Widget _render(num v, Color fg) {
    final shown = round ? v.roundToDouble() : v;
    // A stored amount is formatted in the currency it was recorded in,
    // so an old invoice reads the same after the shop changes country.
    final stored = storedSymbol != null;
    final grouping =
        stored ? groupingForCountry(storedCountryCode ?? 'IN') : null;
    final body = compact
        ? formatMoneyCompact(shown, grouping: grouping)
        : formatIndianDigits(shown, grouping: grouping);
    final base = AppFont.style(style, color: fg);

    if (!showSymbol) {
      return Text(body, style: base, textAlign: textAlign, maxLines: 1);
    }

    return Text.rich(
      TextSpan(children: [
        TextSpan(
          text: stored && storedSymbol!.isNotEmpty ? storedSymbol! : _symbol,
          style: base.copyWith(
            fontSize: (base.fontSize ?? 16) * _symbolRatio,
            fontWeight: FontWeight.w500,
            color: fg.withValues(alpha: 0.62),
            letterSpacing: 0,
          ),
        ),
        // A hair of space, scaled to the SYMBOL rather than the amount —
        // tying it to the amount made the gap balloon on the hero figure.
        TextSpan(
          text: ' ',
          style: base.copyWith(fontSize: (base.fontSize ?? 16) * 0.45),
        ),
        TextSpan(text: body, style: base),
      ]),
      style: base,
      textAlign: textAlign,
      maxLines: 1,
    );
  }
}

/// A money value that counts up from zero the first time it appears, then
/// tweens on every later change. Reserved for hero figures — a dashboard
/// balance, an invoice grand total — where the motion says "this is the
/// number that matters". Overusing it would be noise.
class MoneyCounter extends StatefulWidget {
  final num value;
  final TextStyle style;
  final Color? color;
  final bool compact;
  final bool round;
  final Duration duration;

  /// See [Money.storedSymbol] — for a hero figure read off a saved
  /// record rather than computed live.
  final String? storedSymbol;
  final String? storedCountryCode;

  /// See [Money.shrinkToFit]. On by default here: every MoneyCounter
  /// in the app is a hero figure in a fixed-width well, which is
  /// exactly where a long number does the most damage.
  final bool shrinkToFit;

  const MoneyCounter(
    this.value, {
    super.key,
    this.style = AppType.amountHero,
    this.color,
    this.compact = true,
    this.round = true,
    this.duration = const Duration(milliseconds: 900),
    this.storedSymbol,
    this.storedCountryCode,
    this.shrinkToFit = true,
  });

  @override
  State<MoneyCounter> createState() => _MoneyCounterState();
}

class _MoneyCounterState extends State<MoneyCounter> {
  late num _from = 0;

  @override
  void didUpdateWidget(MoneyCounter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _from = old.value;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _from.toDouble(), end: widget.value.toDouble()),
      duration: widget.duration,
      // Decelerate hard so the last digits settle rather than snap.
      curve: Curves.easeOutQuart,
      builder: (_, v, __) => Money(
        v,
        style: widget.style,
        color: widget.color,
        compact: widget.compact,
        round: widget.round,
        storedSymbol: widget.storedSymbol,
        storedCountryCode: widget.storedCountryCode,
        shrinkToFit: widget.shrinkToFit,
      ),
    );
  }
}
