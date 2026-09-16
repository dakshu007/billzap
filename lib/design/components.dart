// lib/design/components.dart
//
// The component vocabulary. Screens compose these instead of building
// containers by hand, which is what keeps radius, elevation, hairline
// weight and type consistent across 20-odd screens.

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        return (
          bg: AppColor.overdue,
          fg: Colors.white,
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
