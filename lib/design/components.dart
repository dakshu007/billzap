// lib/design/components.dart
//
// The component vocabulary. Screens compose these instead of building
// containers by hand, which is what keeps radius, elevation, hairline
// weight and type consistent across 20-odd screens.

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:billzap/theme/app_icons.dart';

import 'money.dart';
import 'motion.dart';
import 'theme.dart';
import 'tokens.dart';

// ═════════════════════════════════════════════════════════════════════
// SURFACE
// ═════════════════════════════════════════════════════════════════════

/// A raised surface.
///
/// The premium detail is [_TopHighlight]: a 1px gradient along the top
/// edge that simulates light catching a lifted panel. With the ambient
/// shadow below and a hairline around, a rectangle starts reading as an
/// object with thickness.
class AppSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final List<BoxShadow>? shadow;
  final Border? border;

  /// Draw the top light-catch. Off for surfaces nested inside another.
  final bool highlight;

  const AppSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.lg),
    this.margin,
    this.radius = AppRadius.lg,
    this.color,
    this.onTap,
    this.onLongPress,
    this.shadow,
    this.border,
    this.highlight = true,
  });

  @override
  Widget build(BuildContext context) {
    final r = AppRadius.all(radius);

    Widget panel = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? AppColor.surface,
        borderRadius: r,
        border: border ?? Border.all(color: AppColor.hairline),
        boxShadow: shadow ?? AppElevation.card,
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Stack(children: [
          Padding(padding: padding, child: child),
          if (highlight)
            Positioned(top: 0, left: 0, right: 0, child: _TopHighlight(radius: radius)),
        ]),
      ),
    );

    if (margin != null) panel = Padding(padding: margin!, child: panel);
    if (onTap == null && onLongPress == null) return panel;

    return PressScale(onTap: onTap, onLongPress: onLongPress, child: panel);
  }
}

/// The 1px light catch along a surface's top edge. Fades out toward the
/// corners so it reads as a curved highlight rather than a drawn line.
class _TopHighlight extends StatelessWidget {
  final double radius;
  const _TopHighlight({required this.radius});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          height: 1,
          margin: EdgeInsets.symmetric(horizontal: radius * 0.5),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppColor.topHighlight.withValues(alpha: 0),
              AppColor.topHighlight,
              AppColor.topHighlight.withValues(alpha: 0),
            ]),
          ),
        ),
      );
}

/// A recessed well — inputs, inline panels, progress tracks.
class AppWell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;

  const AppWell({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.lg),
    this.radius = AppRadius.md,
    this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? AppColor.sunken,
          borderRadius: AppRadius.all(radius),
        ),
        child: child,
      );
}

// ═════════════════════════════════════════════════════════════════════
// BUTTONS
// ═════════════════════════════════════════════════════════════════════

enum AppButtonKind { primary, neutral, outline, ghost, danger }

/// Whichever of white / near-black reads better on [fill], by WCAG
/// contrast ratio. Used for fills that flip lightness between themes.
Color _readableOn(Color fill) {
  double ratio(Color a, Color b) {
    final la = a.computeLuminance(), lb = b.computeLuminance();
    final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  return ratio(Colors.white, fill) >= ratio(AppColor.ink900, fill)
      ? Colors.white
      : AppColor.ink900;
}

/// The app's button. Primary carries a jade glow — the one place an
/// accent is allowed to bleed past its own edge, which is what makes the
/// main action on a screen unmistakable.
class AppButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onPressed;
  final AppButtonKind kind;
  final bool expand;
  final bool busy;
  final bool compact;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.kind = AppButtonKind.primary,
    this.expand = true,
    this.busy = false,
    this.compact = false,
  });

  const AppButton.neutral({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.expand = true,
    this.busy = false,
    this.compact = false,
  }) : kind = AppButtonKind.neutral;

  const AppButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.expand = true,
    this.busy = false,
    this.compact = false,
  }) : kind = AppButtonKind.outline;

  const AppButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.expand = false,
    this.busy = false,
    this.compact = true,
  }) : kind = AppButtonKind.ghost;

  const AppButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.expand = true,
    this.busy = false,
    this.compact = false,
  }) : kind = AppButtonKind.danger;

  ({Color bg, Color fg, Border? border, List<BoxShadow> shadow}) _skin() {
    switch (kind) {
      case AppButtonKind.primary:
        return (
          bg: AppColor.primary,
          fg: AppColor.onPrimary,
          border: null,
          shadow: AppElevation.glow(AppColor.primary)
        );
      case AppButtonKind.neutral:
        return (
          bg: AppColor.contrast,
          fg: AppColor.onContrast,
          border: null,
          shadow: AppElevation.card
        );
      case AppButtonKind.outline:
        return (
          bg: AppColor.surface,
          fg: AppColor.textPrimary,
          border: Border.all(color: AppColor.border),
          shadow: AppElevation.none
        );
      case AppButtonKind.ghost:
        return (
          bg: Colors.transparent,
          fg: AppColor.textSecondary,
          border: null,
          shadow: AppElevation.none
        );
      case AppButtonKind.danger:
        // Dark mode lifts `overdue` to a soft red, where white text only
        // clears 2.6:1. Pick whichever foreground actually contrasts.
        return (
          bg: AppColor.overdue,
          fg: _readableOn(AppColor.overdue),
          border: null,
          shadow: AppElevation.glow(AppColor.overdue)
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final s = _skin();
    final pad = compact
        ? const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md)
        : const EdgeInsets.symmetric(horizontal: AppSpace.xxl, vertical: 17);

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          SizedBox(
            width: 17,
            height: 17,
            child: CircularProgressIndicator(
                strokeWidth: 2, valueColor: AlwaysStoppedAnimation(s.fg)),
          )
        else if (icon != null)
          Icon(icon, size: compact ? 17 : 19, color: s.fg),
        if (busy || icon != null) const SizedBox(width: AppSpace.sm),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFont.style(
                compact ? AppType.labelM : AppType.labelL, color: s.fg),
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: AppSpace.sm),
          Icon(trailingIcon, size: compact ? 17 : 19, color: s.fg),
        ],
      ],
    );

    return PressScale(
      onTap: enabled ? onPressed : null,
      scale: 0.96,
      haptic: kind == AppButtonKind.primary || kind == AppButtonKind.danger
          ? HapticFeedbackType.medium
          : HapticFeedbackType.light,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.42,
        duration: AppMotion.fast,
        child: Container(
          padding: pad,
          decoration: BoxDecoration(
            color: s.bg,
            borderRadius: AppRadius.all(AppRadius.pill),
            border: s.border,
            boxShadow: enabled ? s.shadow : AppElevation.none,
          ),
          child: content,
        ),
      ),
    );
  }
}

/// A circular icon affordance — back, close, overflow, inline actions.
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? background;
  final Color? foreground;
  final String? tooltip;
  final bool bordered;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 42,
    this.background,
    this.foreground,
    this.tooltip,
    this.bordered = true,
  });

  @override
  Widget build(BuildContext context) {
    final btn = PressScale(
      onTap: onTap,
      scale: 0.9,
      haptic: HapticFeedbackType.light,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background ?? AppColor.surface,
          shape: BoxShape.circle,
          border: bordered && background == null
              ? Border.all(color: AppColor.hairline)
              : null,
          boxShadow: background == null ? AppElevation.none : AppElevation.card,
        ),
        child: Icon(icon,
            size: size * 0.44, color: foreground ?? AppColor.textPrimary),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

// ═════════════════════════════════════════════════════════════════════
// CHIPS & PILLS
// ═════════════════════════════════════════════════════════════════════

/// Filter chip. Selected fills with the neutral contrast tone rather than
/// jade, so jade keeps meaning "money" rather than "selected".
class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final int? count;

  const AppChip(
    this.label, {
    super.key,
    this.selected = false,
    this.onTap,
    this.icon,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColor.onContrast : AppColor.textSecondary;
    return PressScale(
      onTap: onTap,
      scale: 0.94,
      child: AnimatedContainer(
        duration: AppMotion.base,
        curve: AppMotion.standard,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColor.contrast : AppColor.surface,
          borderRadius: AppRadius.all(AppRadius.pill),
          border: Border.all(
              color: selected ? AppColor.contrast : AppColor.hairline),
          boxShadow: selected ? AppElevation.card : AppElevation.none,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 6),
          ],
          Text(label, style: AppFont.style(AppType.labelM, color: fg)),
          if (count != null && count! > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: (selected ? AppColor.onContrast : AppColor.textTertiary)
                    .withValues(alpha: 0.16),
                borderRadius: AppRadius.all(AppRadius.pill),
              ),
              child: Text('$count',
                  style: AppFont.style(AppType.labelS, color: fg)),
            ),
          ],
        ]),
      ),
    );
  }
}

/// Invoice-state badge. Always a tinted wash of its own accent, never a
/// solid fill — a list of solid badges turns into confetti.
class StatusPill extends StatelessWidget {
  final String label;
  final Color tone;
  final bool dot;

  const StatusPill(this.label, {super.key, required this.tone, this.dot = true});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: AppColor.wash(tone),
          borderRadius: AppRadius.all(AppRadius.pill),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (dot) ...[
            Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(color: tone, shape: BoxShape.circle)),
            const SizedBox(width: 5),
          ],
          Text(label.toUpperCase(),
              style: AppFont.style(AppType.overline, color: tone)),
        ]),
      );
}

// ═════════════════════════════════════════════════════════════════════
// STRUCTURE
// ═════════════════════════════════════════════════════════════════════

/// Screen heading. [eyebrow] carries the small caps label above the title.
class ScreenTitle extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const ScreenTitle(
    this.title, {
    super.key,
    this.eyebrow,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(
        AppSpace.gutter, AppSpace.sm, AppSpace.gutter, AppSpace.lg),
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eyebrow != null) ...[
                  Text(eyebrow!.toUpperCase(),
                      style: AppFont.style(AppType.overline,
                          color: AppColor.textTertiary)),
                  const SizedBox(height: 5),
                ],
                Text(title,
                    style: AppFont.style(AppType.titleL,
                        color: AppColor.textPrimary)),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFont.style(AppType.bodyS,
                          color: AppColor.textTertiary)),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: AppSpace.md), trailing!],
        ]),
      );
}

/// Section label with an optional trailing action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const SectionHeader(
    this.title, {
    super.key,
    this.action,
    this.onAction,
    this.padding = const EdgeInsets.only(bottom: AppSpace.md),
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Row(children: [
          Text(title,
              style:
                  AppFont.style(AppType.titleS, color: AppColor.textPrimary)),
          const Spacer(),
          if (action != null && onAction != null)
            PressScale(
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(children: [
                  Text(action!,
                      style: AppFont.style(AppType.labelM,
                          color: AppColor.textSecondary)),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded,
                      size: 16, color: AppColor.textTertiary),
                ]),
              ),
            ),
        ]),
      );
}

/// Rounded-square avatar holding an initial or an icon.
class AppAvatar extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final Color? tone;
  final double size;
  final bool solid;

  const AppAvatar({
    super.key,
    this.label,
    this.icon,
    this.tone,
    this.size = 44,
    this.solid = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = tone ?? AppColor.textSecondary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: solid ? accent : AppColor.wash(accent),
        borderRadius: AppRadius.all(size * 0.32),
      ),
      alignment: Alignment.center,
      child: icon != null
          ? Icon(icon,
              size: size * 0.44, color: solid ? Colors.white : accent)
          : Text(
              (label?.trim().isNotEmpty == true ? label!.trim()[0] : '?')
                  .toUpperCase(),
              style: AppFont.style(
                AppType.titleS.copyWith(fontSize: size * 0.38),
                color: solid ? Colors.white : accent,
              ),
            ),
    );
  }
}

/// The standard list row: avatar · title/subtitle · amount + status.
class AppListRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final num? amount;
  final Widget? badge;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? margin;

  const AppListRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.amount,
    this.badge,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.margin,
  });

  @override
  Widget build(BuildContext context) => AppSurface(
        onTap: onTap,
        onLongPress: onLongPress,
        margin: margin ?? const EdgeInsets.only(bottom: AppSpace.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md, vertical: AppSpace.md),
        child: Row(children: [
          leading,
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFont.style(AppType.labelL,
                        color: AppColor.textPrimary)),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFont.style(AppType.bodyS,
                          color: AppColor.textTertiary)),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpace.sm),
            trailing!,
          ] else if (amount != null || badge != null) ...[
            const SizedBox(width: AppSpace.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (amount != null)
                  // Ledger column: always two decimals so the tabular
                  // figures align down the list.
                  Money(amount!, style: AppType.amountS, compact: false),
                if (badge != null) ...[
                  const SizedBox(height: 5),
                  badge!,
                ],
              ],
            ),
          ],
        ]),
      );
}

/// Centred empty state. The illustration is a tinted disc behind a thin
/// icon — cheap to render, and it reads as intentional rather than as a
/// missing image.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? tone;
  final EdgeInsetsGeometry padding;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.tone,
    this.padding = const EdgeInsets.symmetric(
        horizontal: AppSpace.xxl, vertical: AppSpace.xxxl),
  });

  @override
  Widget build(BuildContext context) {
    final accent = tone ?? AppColor.textTertiary;
    return Padding(
      padding: padding,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: AppColor.wash(accent),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 34, color: accent),
        ),
        const SizedBox(height: AppSpace.xl),
        Text(title,
            textAlign: TextAlign.center,
            style: AppFont.style(AppType.titleM, color: AppColor.textPrimary)),
        if (message != null) ...[
          const SizedBox(height: AppSpace.sm),
          Text(message!,
              textAlign: TextAlign.center,
              style:
                  AppFont.style(AppType.bodyM, color: AppColor.textTertiary)),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: AppSpace.xl),
          AppButton(label: actionLabel!, onPressed: onAction, expand: false),
        ],
      ]),
    );
  }
}

/// Pill-shaped search field.
class AppSearchField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool hasValue;

  const AppSearchField({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.onClear,
    this.hasValue = false,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: AppRadius.all(AppRadius.pill),
          border: Border.all(color: AppColor.hairline),
          boxShadow: AppElevation.card,
        ),
        child: Row(children: [
          Icon(Icons.search_rounded, size: 20, color: AppColor.textTertiary),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppFont.style(AppType.bodyL, color: AppColor.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                hintText: hint,
                hintStyle:
                    AppFont.style(AppType.bodyL, color: AppColor.textQuiet),
              ),
            ),
          ),
          if (hasValue)
            PressScale(
              onTap: onClear,
              scale: 0.85,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close_rounded,
                    size: 18, color: AppColor.textTertiary),
              ),
            ),
        ]),
      );
}

/// Compact metric tile — icon, label, figure, delta line.
class StatTile extends StatelessWidget {
  final String label;
  final num? amount;
  final String? value;
  final String? caption;
  final IconData icon;
  final Color tone;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    required this.label,
    required this.icon,
    required this.tone,
    this.amount,
    this.value,
    this.caption,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => AppSurface(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpace.md),
        radius: AppRadius.md,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColor.wash(tone),
                  borderRadius: AppRadius.all(AppRadius.xs),
                ),
                child: Icon(icon, size: 15, color: tone),
              ),
            ]),
            const SizedBox(height: AppSpace.md),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    AppFont.style(AppType.labelS, color: AppColor.textTertiary)),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: amount != null
                  ? Money(amount!, style: AppType.amountM, round: true)
                  : Text(value ?? '—',
                      style: AppFont.style(AppType.amountM,
                          color: AppColor.textPrimary)),
            ),
            if (caption != null) ...[
              const SizedBox(height: 2),
              Text(caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFont.style(AppType.bodyS,
                      color: AppColor.textQuiet)),
            ],
          ],
        ),
      );
}

/// Circular back affordance for pushed screens. Falls back to a caller
/// supplied route when there is nothing on the stack to pop (deep links,
/// restored sessions).
class AppBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String? tooltip;

  const AppBackButton({super.key, this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) => Center(
        child: AppIconButton(
          icon: Icons.arrow_back_rounded,
          size: 40,
          tooltip: tooltip,
          onTap: onTap ?? () => Navigator.of(context).maybePop(),
        ),
      );
}

/// A sparkline — the shape of a series, without axes or labels.
///
/// Used behind a headline figure so the number carries its own trend. It
/// draws itself on first paint (the line sweeps left to right and the
/// fill rises underneath) because a static chart next to an animated
/// counter looks like it failed to load.
class Sparkline extends StatefulWidget {
  final List<double> values;
  final Color color;
  final double strokeWidth;

  const Sparkline({
    super.key,
    required this.values,
    required this.color,
    this.strokeWidth = 2.2,
  });

  @override
  State<Sparkline> createState() => _SparklineState();
}

class _SparklineState extends State<Sparkline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _SparklinePainter(
            values: widget.values,
            color: widget.color,
            strokeWidth: widget.strokeWidth,
            progress: Curves.easeOutCubic.transform(_c.value),
          ),
          size: Size.infinite,
        ),
      );
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double strokeWidth;
  final double progress;

  _SparklinePainter({
    required this.values,
    required this.color,
    required this.strokeWidth,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.width <= 0) return;

    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final span = (maxV - minV).abs() < 0.0001 ? 1.0 : maxV - minV;

    Offset at(int i) {
      final x = size.width * (i / (values.length - 1));
      // Inset vertically so the stroke is never clipped by the bounds.
      final t = (values[i] - minV) / span;
      final y = size.height - (t * (size.height - strokeWidth)) - strokeWidth / 2;
      return Offset(x, y);
    }

    // Catmull-Rom style smoothing: each segment's control points are
    // pulled toward its neighbours, which reads as a curve rather than a
    // chain of straight lines without overshooting the data.
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 0; i < values.length - 1; i++) {
      final p0 = at(i);
      final p1 = at(i + 1);
      final dx = (p1.dx - p0.dx) * 0.42;
      path.cubicTo(p0.dx + dx, p0.dy, p1.dx - dx, p1.dy, p1.dx, p1.dy);
    }

    // Reveal by clipping to the swept width, so the line draws on.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.20),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();

    // A dot on the latest point, once the line has reached it.
    if (progress > 0.985) {
      final last = at(values.length - 1);
      canvas.drawCircle(last, strokeWidth * 1.9,
          Paint()..color = color.withValues(alpha: 0.22));
      canvas.drawCircle(last, strokeWidth * 0.95, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.progress != progress ||
      old.color != color ||
      !listEquals(old.values, values);
}

// ═════════════════════════════════════════════════════════════════════
// DIALOGS
// ═════════════════════════════════════════════════════════════════════
//
// Every confirmation, warning and "done" message in the app goes through
// here. Material's stock AlertDialog was the last place the old chrome
// survived — square-ish corners, a 24pt title, two flat text buttons —
// and it showed, because destructive confirmations are exactly the
// moments a person looks closely at what they are tapping.
//
// The sheet rises and settles with a little overshoot, which is the same
// entrance the welcome modal uses, so dialogs read as one family.

/// The card itself. Use [showAppDialog] rather than building this
/// directly unless you need a custom body.
class AppDialog extends StatelessWidget {
  /// Tone for the icon disc and the primary button. Defaults to jade.
  final Color? tone;
  final IconData? icon;
  final String title;
  final String? message;

  /// Optional content between the message and the buttons.
  final Widget? body;

  /// Primary action. Its label is required; a null [onConfirm] pops true.
  final String confirmLabel;
  final VoidCallback? onConfirm;

  /// Secondary action. Pass null to show only the primary button.
  final String? cancelLabel;
  final VoidCallback? onCancel;

  /// Renders the primary button in the danger style.
  final bool destructive;

  const AppDialog({
    super.key,
    required this.title,
    this.message,
    this.body,
    this.icon,
    this.tone,
    this.confirmLabel = 'OK',
    this.onConfirm,
    this.cancelLabel,
    this.onCancel,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = tone ?? (destructive ? AppColor.overdue : AppColor.primary);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.gutter),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.fromLTRB(
                AppSpace.xl, AppSpace.xl, AppSpace.xl, AppSpace.lg),
            decoration: BoxDecoration(
              color: AppColor.surface,
              borderRadius: AppRadius.all(AppRadius.sheet),
              border: Border.all(color: AppColor.hairline),
              boxShadow: AppElevation.lifted,
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColor.wash(accent),
                    borderRadius: AppRadius.all(AppRadius.lg),
                  ),
                  child: Icon(icon, color: accent, size: 26),
                ),
                const SizedBox(height: AppSpace.lg),
              ],
              Text(title,
                  textAlign: TextAlign.center,
                  style: AppFont.style(AppType.titleM,
                      color: AppColor.textPrimary)),
              if (message != null) ...[
                const SizedBox(height: AppSpace.sm),
                Text(message!,
                    textAlign: TextAlign.center,
                    style: AppFont.style(AppType.bodyM,
                        color: AppColor.textTertiary)),
              ],
              if (body != null) ...[
                const SizedBox(height: AppSpace.lg),
                body!,
              ],
              const SizedBox(height: AppSpace.xl),
              SizedBox(
                width: double.infinity,
                child: destructive
                    ? AppButton.danger(
                        label: confirmLabel,
                        onPressed: onConfirm ??
                            () => Navigator.of(context).pop(true),
                      )
                    : AppButton(
                        label: confirmLabel,
                        onPressed: onConfirm ??
                            () => Navigator.of(context).pop(true),
                      ),
              ),
              if (cancelLabel != null) ...[
                const SizedBox(height: AppSpace.xs),
                TextButton(
                  onPressed: onCancel ??
                      () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop(false);
                      },
                  child: Text(cancelLabel!,
                      style: AppFont.style(AppType.labelM,
                          color: AppColor.textTertiary)),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

/// Presents [child] with the app's dialog entrance and scrim.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool dismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: AppTokens.pick(0.34, 0.62)),
    transitionDuration: AppMotion.base,
    pageBuilder: (ctx, _, _) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, _) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      return Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 28 * (1 - curved.value)),
          child: Transform.scale(
            scale: 0.94 + 0.06 * curved.value,
            child: builder(ctx),
          ),
        ),
      );
    },
  );
}

/// The common case: ask a yes/no question and return whether the person
/// said yes. Returns false if they dismissed it.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  String? message,
  IconData? icon,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
  Color? tone,
}) async {
  HapticFeedback.mediumImpact();
  final ok = await showAppDialog<bool>(
    context: context,
    builder: (ctx) => AppDialog(
      title: title,
      message: message,
      icon: icon,
      tone: tone,
      destructive: destructive,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    ),
  );
  return ok == true;
}

/// A one-button acknowledgement — "done", "all sent", "restore complete".
Future<void> notify(
  BuildContext context, {
  required String title,
  String? message,
  Widget? body,
  IconData? icon,
  Color? tone,
  String buttonLabel = 'Done',
}) {
  return showAppDialog<void>(
    context: context,
    builder: (ctx) => AppDialog(
      title: title,
      message: message,
      body: body,
      icon: icon,
      tone: tone,
      confirmLabel: buttonLabel,
      onConfirm: () => Navigator.of(ctx).pop(),
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════
// SEGMENTED TABS
// ═════════════════════════════════════════════════════════════════════

/// A segmented control whose indicator *travels*.
///
/// The obvious build — an AnimatedContainer per segment, fading a pill in
/// on the selected one and out on the last — reads as a cut, because
/// nothing actually moves between the two positions. Here a single pill
/// slides, and it carries the dock's physics: it stretches along its
/// direction of travel and thins slightly mid-flight, then settles.
class SegmentedTabs extends StatefulWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onSelect;

  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onSelect,
  });

  @override
  State<SegmentedTabs> createState() => _SegmentedTabsState();
}

class _SegmentedTabsState extends State<SegmentedTabs>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  /// Where the pill is travelling from and to, in slot units. The
  /// indicator is drawn at lerp(_from, _to, curve), which is what lets
  /// an interrupted tap continue from wherever it had reached.
  late double _from;
  late double _to;
  int? _pressed;

  @override
  void initState() {
    super.initState();
    _from = _to = widget.index.toDouble();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(SegmentedTabs old) {
    super.didUpdateWidget(old);
    if (widget.index != old.index) {
      // Start from the pill's *current* position, not from the previous
      // slot: tapping through three tabs quickly should look like one
      // continuous slide, not three restarts.
      _from = _position;
      _to = widget.index.toDouble();
      _c
        ..value = 0
        ..forward();
    }
  }

  double get _position {
    final t = Curves.easeOutCubic.transform(_c.value);
    return _from + (_to - _from) * t;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _tap(int i) {
    if (i == widget.index) return;
    HapticFeedback.selectionClick();
    widget.onSelect(i);
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.labels.length;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColor.sunken,
        borderRadius: AppRadius.all(AppRadius.pill),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final slot = (box.maxWidth - 8) / n;
          return AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final pos = _position;

              // Distance from the nearest slot centre — 0 at rest, 0.5
              // mid-flight. Exactly the number the dock's bubble uses.
              final travel = (pos - pos.roundToDouble()).abs() * 2;
              final stretch = 1 + travel * 0.16;
              final squash = 1 - travel * 0.08;

              return Stack(children: [
                Positioned(
                  left: slot * pos,
                  top: 0,
                  bottom: 0,
                  width: slot,
                  child: Center(
                    child: Transform.scale(
                      scaleX: stretch,
                      scaleY: squash,
                      child: Container(
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColor.surface,
                          borderRadius: AppRadius.all(AppRadius.pill),
                          boxShadow: AppElevation.card,
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: List.generate(n, (i) {
                    // Continuous, like the dock: the label's weight and
                    // colour blend across the pill's travel rather than
                    // flipping when it arrives.
                    final t = (1 - (pos - i).abs()).clamp(0.0, 1.0);
                    return Expanded(
                      child: Semantics(
                        button: true,
                        selected: t > 0.5,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (_) => setState(() => _pressed = i),
                          onTapUp: (_) => setState(() => _pressed = null),
                          onTapCancel: () => setState(() => _pressed = null),
                          onTap: () => _tap(i),
                          child: AnimatedScale(
                            scale: _pressed == i ? 0.94 : 1.0,
                            duration: AppMotion.fast,
                            curve: AppMotion.standard,
                            child: SizedBox(
                              height: 34,
                              child: Center(
                                child: Text(
                                  widget.labels[i],
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppFont.style(
                                    AppType.labelM,
                                    color: Color.lerp(AppColor.textTertiary,
                                        AppColor.textPrimary, t),
                                  ).copyWith(
                                    fontWeight: FontWeight.lerp(
                                        FontWeight.w500, FontWeight.w700, t),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ]);
            },
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// FIELDS
// ═════════════════════════════════════════════════════════════════════

/// The app's text field.
///
/// Material's default is a box that sits there. This one responds: at
/// rest it is a recessed well, on focus it lifts to the surface tone,
/// draws a jade keyline and picks up the same glow the primary button
/// has — so the field you are typing into is the brightest thing on the
/// screen. The label and the leading icon travel with it.
///
/// Validation is shown on the field rather than only under it: a quiet
/// jade check once the value is good, a coral ring and an inline reason
/// when it is not. A shopkeeper filling in a GSTIN at a counter should
/// not have to hunt for which of nine fields is unhappy.
class AppField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? helper;
  final IconData? icon;
  final TextInputType? keyboardType;
  final bool caps;
  final int? maxLength;
  final int maxLines;
  final String? errorText;

  /// Show the jade tick once the field has a value and no error. Off for
  /// fields where "filled in" is not the same as "correct".
  final bool validatable;
  final bool enabled;
  final bool autofocus;
  final String? suffix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;
  final VoidCallback? onTap;
  final bool readOnly;

  const AppField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.helper,
    this.icon,
    this.keyboardType,
    this.caps = false,
    this.maxLength,
    this.maxLines = 1,
    this.errorText,
    this.validatable = true,
    this.enabled = true,
    this.autofocus = false,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.onTap,
    this.readOnly = false,
  });

  @override
  State<AppField> createState() => _AppFieldState();
}

class _AppFieldState extends State<AppField> {
  late final FocusNode _focus;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()
      ..addListener(() {
        if (_focus.hasFocus != _focused) {
          setState(() => _focused = _focus.hasFocus);
        }
      });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final err = widget.errorText;
    final hasError = err != null && err.isNotEmpty;
    final filled = widget.controller.text.trim().isNotEmpty;
    final good = widget.validatable && filled && !hasError;

    final accent = hasError
        ? AppColor.overdue
        : _focused
            ? AppColor.primary
            : AppColor.hairline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The label takes the accent while the field is live, so the eye
        // can find the active row without reading any of them.
        AnimatedDefaultTextStyle(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          style: AppFont.style(
            AppType.labelS,
            color: hasError
                ? AppColor.overdue
                : _focused
                    ? AppColor.primary
                    : AppColor.textTertiary,
          ),
          child: Text(widget.label.toUpperCase()),
        ),
        const SizedBox(height: AppSpace.xs),
        AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          decoration: BoxDecoration(
            color: _focused ? AppColor.surface : AppColor.sunken,
            borderRadius: AppRadius.all(AppRadius.md),
            border: Border.all(
              color: accent,
              width: _focused || hasError ? 1.5 : 1,
            ),
            boxShadow: _focused && !hasError
                ? AppElevation.glow(AppColor.primary)
                : AppElevation.none,
          ),
          padding: EdgeInsets.fromLTRB(
            widget.icon != null ? AppSpace.md : AppSpace.lg,
            widget.maxLines > 1 ? AppSpace.md : 2,
            AppSpace.md,
            widget.maxLines > 1 ? AppSpace.md : 2,
          ),
          child: Row(
            crossAxisAlignment: widget.maxLines > 1
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                AnimatedContainer(
                  duration: AppMotion.fast,
                  padding: const EdgeInsets.only(right: AppSpace.md),
                  child: Icon(
                    widget.icon,
                    size: 18,
                    color: hasError
                        ? AppColor.overdue
                        : _focused
                            ? AppColor.primary
                            : AppColor.textTertiary,
                  ),
                ),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  enabled: widget.enabled,
                  readOnly: widget.readOnly,
                  autofocus: widget.autofocus,
                  onTap: widget.onTap,
                  keyboardType: widget.keyboardType,
                  maxLength: widget.maxLength,
                  maxLines: widget.maxLines,
                  minLines: widget.maxLines > 1 ? widget.maxLines : null,
                  textAlign: widget.textAlign,
                  onChanged: (v) {
                    widget.onChanged?.call(v);
                    // Repaint for the tick: whether the value is good is
                    // read from the controller, not from an onChanged
                    // the caller may not have passed.
                    setState(() {});
                  },
                  onSubmitted: widget.onSubmitted,
                  inputFormatters: widget.inputFormatters,
                  textCapitalization: widget.caps
                      ? TextCapitalization.characters
                      : TextCapitalization.sentences,
                  style: AppFont.style(AppType.bodyL,
                      color: AppColor.textPrimary),
                  cursorColor: AppColor.primary,
                  cursorWidth: 2,
                  cursorRadius: const Radius.circular(2),
                  decoration: InputDecoration(
                    isDense: true,
                    // Every border variant, not just `border`: the global
                    // InputDecorationTheme sets enabledBorder and
                    // focusedBorder, and those are what was drawing a
                    // second rounded rect inside the well. The well
                    // itself is the field — one outline, one glow.
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(
                        vertical: widget.maxLines > 1 ? 0 : AppSpace.md),
                    hintText: widget.hint,
                    hintStyle: AppFont.style(AppType.bodyL,
                        color: AppColor.textTertiary),
                  ),
                ),
              ),
              if (widget.suffix != null)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpace.sm),
                  child: Text(widget.suffix!,
                      style: AppFont.style(AppType.labelM,
                          color: AppColor.textTertiary)),
                ),
              // The state mark. It fades rather than popping, so a field
              // going valid mid-typing does not flash at you.
              AnimatedSwitcher(
                duration: AppMotion.fast,
                transitionBuilder: (c, a) =>
                    FadeTransition(opacity: a, child: ScaleTransition(scale: a, child: c)),
                child: hasError
                    ? Icon(Symbols.warning,
                        key: const ValueKey('err'),
                        size: 17,
                        color: AppColor.overdue)
                    : good
                        ? Icon(Symbols.check_circle,
                            key: const ValueKey('ok'),
                            size: 17,
                            color: AppColor.primary)
                        : const SizedBox(
                            key: ValueKey('none'), width: 0, height: 17),
              ),
            ],
          ),
        ),
        // Reserved space would leave a gap under every field; instead the
        // message animates its own height in.
        AnimatedSize(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          alignment: Alignment.topLeft,
          child: (hasError || widget.helper != null)
              ? Padding(
                  padding: const EdgeInsets.only(
                      top: AppSpace.xs, left: AppSpace.xs),
                  child: Text(
                    hasError ? err : widget.helper!,
                    style: AppFont.style(
                      AppType.bodyS,
                      color: hasError
                          ? AppColor.overdue
                          : AppColor.textTertiary,
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }
}

/// A group of fields under one heading, on one surface.
///
/// Nine fields as nine separate grey blobs is a form; the same nine in
/// three labelled groups is a page about a business. The heading carries
/// a tinted icon so the groups are findable by shape when scrolling.
class FieldGroup extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? tone;
  final List<Widget> children;
  final EdgeInsetsGeometry? margin;

  const FieldGroup({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.subtitle,
    this.tone,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final accent = tone ?? AppColor.primary;
    return AppSurface(
      margin: margin ?? const EdgeInsets.only(bottom: AppSpace.lg),
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColor.wash(accent),
                borderRadius: AppRadius.all(AppRadius.sm),
              ),
              child: Icon(icon, size: 16, color: accent),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: AppFont.style(AppType.labelL,
                          color: AppColor.textPrimary)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(subtitle!,
                        style: AppFont.style(AppType.bodyS,
                            color: AppColor.textTertiary)),
                  ],
                ],
              ),
            ),
          ]),
          const SizedBox(height: AppSpace.lg),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpace.md),
            children[i],
          ],
        ],
      ),
    );
  }
}
