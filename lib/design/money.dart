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

/// Formats a number in the Indian grouping system (lakh / crore).
///
/// `intl`'s en_IN locale can do this, but this is on the hot path for
/// every row of every list, so a direct implementation avoids the
/// per-call locale lookup.
String formatIndianDigits(num value, {int decimals = 2}) {
  final negative = value < 0;
  final abs = value.abs();

  final fixed = abs.toStringAsFixed(decimals);
  final parts = fixed.split('.');
  var whole = parts[0];
  final fraction = parts.length > 1 ? parts[1] : '';

  // Outside India, group in threes. The function keeps its name because
  // it is called from 37 places and the Indian path is still the one
  // that needed hand-writing; the western path is the ordinary rule.
  if (_grouping == MoneyGrouping.western && whole.length > 3) {
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
String formatMoneyCompact(num value) {
  final whole = value == value.roundToDouble();
  return formatIndianDigits(value, decimals: whole ? 0 : 2);
}

/// Short form for chart axes and dense stat tiles: 1.2L, 3.4Cr.
String formatMoneyShort(num value) {
  final abs = value.abs();
  final sign = value < 0 ? '-' : '';
  // Lakh and crore are not units anyone outside the subcontinent reads.
  // Elsewhere the ladder is K / M / B.
  if (_grouping == MoneyGrouping.indian) {
    if (abs >= 10000000) return '$sign${(abs / 10000000).toStringAsFixed(abs >= 100000000 ? 0 : 1)}Cr';
    if (abs >= 100000) return '$sign${(abs / 100000).toStringAsFixed(abs >= 1000000 ? 0 : 1)}L';
  } else {
    if (abs >= 1000000000) return '$sign${(abs / 1000000000).toStringAsFixed(abs >= 10000000000 ? 0 : 1)}B';
    if (abs >= 1000000) return '$sign${(abs / 1000000).toStringAsFixed(abs >= 10000000 ? 0 : 1)}M';
  }
  if (abs >= 1000) return '$sign${(abs / 1000).toStringAsFixed(abs >= 10000 ? 0 : 1)}K';
  return '$sign${formatIndianDigits(abs, decimals: 0)}';
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

    if (!animate) return _render(value, fg);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: value.toDouble(), end: value.toDouble()),
      duration: AppMotion.slow,
      curve: AppMotion.standard,
      builder: (_, v, __) => _render(v, fg),
    );
  }

  Widget _render(num v, Color fg) {
    final shown = round ? v.roundToDouble() : v;
    final body =
        compact ? formatMoneyCompact(shown) : formatIndianDigits(shown);
    final base = AppFont.style(style, color: fg);

    if (!showSymbol) {
      return Text(body, style: base, textAlign: textAlign, maxLines: 1);
    }

    return Text.rich(
      TextSpan(children: [
        TextSpan(
          text: _symbol,
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

  const MoneyCounter(
    this.value, {
    super.key,
    this.style = AppType.amountHero,
    this.color,
    this.compact = true,
    this.round = true,
    this.duration = const Duration(milliseconds: 900),
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
      ),
    );
  }
}
