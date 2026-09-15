// lib/widgets/ui_kit.dart
//
// The shared vocabulary of the clean/minimal redesign. Screens compose
// these instead of hand-rolling containers, so radius, hairline weight,
// shadow depth and type scale stay identical everywhere.
//
//   AppCard          — white panel, soft shadow, large radius
//   AppSectionHeader — title + optional trailing action
//   AppPill          — status / filter chip (ink when selected)
//   AppInkButton     — the primary full-width ink pill CTA
//   AppGhostButton   — secondary outline pill
//   AppIconButton    — circular icon affordance (back, close, more)
//   AppListRow       — leading badge · title/subtitle · trailing
//   AppEmptyState    — centred icon + copy + optional CTA
//   AppScreenTitle   — the large screen heading used under the app bar
//   AppSearchField   — recessed search well

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────
// Surfaces
// ─────────────────────────────────────────────────────────────────────

/// A white (dark: near-black) panel. The default look is borderless with a
/// wide, very soft drop shadow; `outlined` swaps that for a hairline, which
/// reads better for rows stacked directly on top of each other.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double radius;
  final Color? color;
  final bool outlined;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.radius = AppRadius.lg,
    this.color,
    this.outlined = false,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final panel = AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      padding: padding ?? const EdgeInsets.all(18),
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: r,
        border: border ??
            (outlined || AppColors.isDark
                ? Border.all(color: AppColors.border)
                : null),
        boxShadow: outlined ? null : AppShadow.card,
      ),
      child: child,
    );

    if (onTap == null) return panel;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        borderRadius: r,
        splashColor: AppColors.t1.withOpacity(0.04),
        highlightColor: AppColors.t1.withOpacity(0.02),
        child: panel,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Typography helpers
// ─────────────────────────────────────────────────────────────────────

/// The large heading that opens a screen ("8-Days Brazil Adventure" in the
/// reference). Tight tracking, heavy weight, generous size.
class AppScreenTitle extends StatelessWidget {
  final String text;
  final String? subtitle;
  final EdgeInsetsGeometry padding;

  const AppScreenTitle(
    this.text, {
    super.key,
    this.subtitle,
    this.padding = const EdgeInsets.fromLTRB(20, 4, 20, 14),
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text,
                style: AppFont.sans(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.7,
                    height: 1.15,
                    color: AppColors.t1)),
            if (subtitle != null) ...[
              const SizedBox(height: 5),
              Text(subtitle!,
                  style: AppFont.sans(
                      fontSize: 13.5, color: AppColors.t3, height: 1.3)),
            ],
          ],
        ),
      );
}

/// Section label with an optional "See all"-style trailing action.
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const AppSectionHeader(
    this.title, {
    super.key,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(2, 0, 2, 12),
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Row(children: [
          Text(title,
              style: AppFont.sans(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: AppColors.t1)),
          const Spacer(),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                child: Text(actionLabel!,
                    style: AppFont.sans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.t2,
                        decoration: TextDecoration.underline)),
              ),
            ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────
// Chips & pills
// ─────────────────────────────────────────────────────────────────────

/// Filter / status pill. Selected fills with ink, exactly like the
/// "South America" chip in the reference.
class AppPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? tone;
  final bool dense;

  const AppPill(
    this.label, {
    super.key,
    this.selected = false,
    this.onTap,
    this.icon,
    this.tone,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = tone;
    final Color bg;
    final Color fg;
    if (selected) {
      bg = accent ?? AppColors.brand;
      fg = accent != null ? Colors.white : AppColors.onBrand;
    } else if (accent != null) {
      bg = accent.withOpacity(AppColors.isDark ? 0.18 : 0.10);
      fg = accent;
    } else {
      bg = AppColors.inset;
      fg = AppColors.t2;
    }

    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
            horizontal: dense ? 11 : 16, vertical: dense ? 5 : 9.5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: selected || accent != null
              ? null
              : Border.all(color: AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 15, color: fg),
            SizedBox(width: dense ? 5 : 7),
          ],
          Text(label,
              style: AppFont.sans(
                  fontSize: dense ? 10.5 : 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: dense ? 0.1 : -0.1,
                  color: fg)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Buttons
// ─────────────────────────────────────────────────────────────────────

/// The primary CTA — a full-width ink pill ("Book a tour" in the
/// reference). Inverts correctly in dark mode via `brand` / `onBrand`.
class AppInkButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expand;
  final bool busy;
  final Color? color;

  const AppInkButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.expand = true,
    this.busy = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final bg = color ?? AppColors.brand;
    final fg = color != null ? Colors.white : AppColors.onBrand;

    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          SizedBox(
            width: 17, height: 17,
            child: CircularProgressIndicator(
                strokeWidth: 2, valueColor: AlwaysStoppedAnimation(fg)))
        else if (icon != null)
          Icon(icon, size: 19, color: fg),
        if (busy || icon != null) const SizedBox(width: 10),
        Text(label,
            style: AppFont.sans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: fg)),
      ],
    );

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          onTap: enabled
              ? () {
                  HapticFeedback.mediumImpact();
                  onPressed!();
                }
              : null,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Secondary action — same geometry, hairline outline instead of a fill.
class AppGhostButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? tone;

  const AppGhostButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final fg = tone ?? AppColors.t1;
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onPressed == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed!();
              },
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
                color: tone?.withOpacity(0.35) ?? AppColors.borderDark),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 9),
              ],
              Text(label,
                  style: AppFont.sans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular icon affordance — the back / favourite / forward buttons that
/// sit on top of content in the reference.
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? background;
  final Color? foreground;
  final String? tooltip;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 42,
    this.background,
    this.foreground,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: background ?? AppColors.card,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap!();
              },
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: background == null
                ? Border.all(color: AppColors.border)
                : null,
          ),
          child: Icon(icon,
              size: size * 0.45, color: foreground ?? AppColors.t1),
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

// ─────────────────────────────────────────────────────────────────────
// Rows & states
// ─────────────────────────────────────────────────────────────────────

/// Avatar-style leading badge — a rounded square holding an initial or an
/// icon. Used by list rows throughout the app.
class AppBadge extends StatelessWidget {
  final String? initial;
  final IconData? icon;
  final Color? tone;
  final double size;

  const AppBadge({super.key, this.initial, this.icon, this.tone, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final accent = tone ?? AppColors.t2;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tone == null
            ? AppColors.inset
            : accent.withOpacity(AppColors.isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      alignment: Alignment.center,
      child: icon != null
          ? Icon(icon, size: size * 0.46, color: accent)
          : Text(
              (initial?.isNotEmpty == true ? initial![0] : '?').toUpperCase(),
              style: AppFont.sans(
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w600,
                  color: accent),
            ),
    );
  }
}

/// Standard list row: badge · title/subtitle · trailing widget.
class AppListRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  const AppListRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.margin,
  });

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        margin: margin ?? const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        radius: AppRadius.lg,
        child: Row(children: [
          leading,
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFont.sans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: AppColors.t1)),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFont.sans(
                          fontSize: 12.5, color: AppColors.t3)),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ]),
      );
}

/// Centred empty state — thin outlined icon, headline, supporting line,
/// optional CTA.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Column(children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.inset,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: AppColors.t3),
          ),
          const SizedBox(height: 18),
          Text(title,
              textAlign: TextAlign.center,
              style: AppFont.sans(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: AppColors.t1)),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(message!,
                textAlign: TextAlign.center,
                style: AppFont.sans(
                    fontSize: 13.5, color: AppColors.t3, height: 1.45)),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 22),
            AppInkButton(
                label: actionLabel!, onPressed: onAction, expand: false),
          ],
        ]),
      );
}

/// Recessed search well, matching the reference's rounded search bar.
class AppSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final IconData icon;
  final Widget? trailing;

  const AppSearchField({
    super.key,
    required this.hint,
    this.onChanged,
    this.controller,
    this.icon = Icons.search,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadow.card,
        ),
        child: Row(children: [
          Icon(icon, size: 19, color: AppColors.t3),
          const SizedBox(width: 11),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppFont.sans(
                  fontSize: 14, color: AppColors.t1, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                hintText: hint,
                hintStyle: AppFont.sans(fontSize: 14, color: AppColors.t4),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ]),
      );
}
