// lib/design/components.dart
//
// The component vocabulary. Screens compose these instead of building
// containers by hand, which is what keeps radius, elevation, hairline
// weight and type consistent across 20-odd screens.

import 'package:flutter/material.dart';

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
                if (amount != null) Money(amount!, style: AppType.amountS),
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
                  ? Money(amount!, style: AppType.amountM)
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
