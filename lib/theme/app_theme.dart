// lib/theme/app_theme.dart
//
// COMPATIBILITY BRIDGE.
//
// The design system now lives in `lib/design/` (tokens, theme, money,
// motion, components). This file keeps the older `AppColors.*` /
// `AppFont.sans(...)` vocabulary working by mapping it onto the new
// tokens, so screens can be moved across one at a time instead of in a
// single breaking change — and so a screen that has not been rewritten
// yet still picks up the new palette, radii and elevation.
//
// New code should import `package:billzap/design/components.dart` (and
// the token/money/motion files) directly. Nothing new should be added
// here; this file only shrinks from now on.

import 'package:flutter/material.dart';

import '../design/theme.dart' as ds;
import '../design/tokens.dart' as dt;

export '../design/tokens.dart' show AppRadius, AppSpace, AppMotion, AppType;

/// Legacy colour vocabulary mapped onto the Ink & Jade tokens.
class AppColors {
  AppColors._();

  // The old "brand" was a blue used for both chrome and primary actions.
  // It now resolves to the neutral contrast tone, so jade stays reserved
  // for money. Screens wanting the accent use `AppColors.green`.
  static Color get brand     => dt.AppColor.contrast;
  static Color get onBrand   => dt.AppColor.onContrast;
  static Color get brandDark => dt.AppColor.contrast;

  static Color get green  => dt.AppColor.paid;
  static Color get red    => dt.AppColor.overdue;
  static Color get yellow => dt.AppColor.pending;
  static Color get orange => dt.AppColor.pending;
  static Color get purple => dt.AppColor.info;
  static Color get blue   => dt.AppColor.info;
  static Color get navBg  => dt.AppColor.contrast;

  static Color get brandSoft   => dt.AppColor.sunken;
  static Color get brandSofter => dt.AppColor.sunken;
  static Color get greenSoft   => dt.AppColor.wash(dt.AppColor.paid);
  static Color get redSoft      => dt.AppColor.wash(dt.AppColor.overdue);
  static Color get yellowSoft   => dt.AppColor.wash(dt.AppColor.pending);
  static Color get orangeSoft   => dt.AppColor.wash(dt.AppColor.pending);
  static Color get purpleSoft   => dt.AppColor.wash(dt.AppColor.info);
  static Color get blueSoft     => dt.AppColor.wash(dt.AppColor.info);

  static Color get bg     => dt.AppColor.canvas;
  static Color get card   => dt.AppColor.surface;
  static Color get inset  => dt.AppColor.sunken;
  static Color get t1     => dt.AppColor.textPrimary;
  static Color get t2     => dt.AppColor.textSecondary;
  static Color get t3     => dt.AppColor.textTertiary;
  static Color get t4     => dt.AppColor.textQuiet;
  static Color get border => dt.AppColor.hairline;
  static Color get borderDark => dt.AppColor.border;

  static bool get isDark => dt.AppTokens.isDark;
  static Brightness get mode =>
      dt.AppTokens.isDark ? Brightness.dark : Brightness.light;
  static void setMode(Brightness b) => dt.AppTokens.setMode(b);
}

/// Legacy elevation names.
class AppShadow {
  AppShadow._();
  static List<BoxShadow> get card  => dt.AppElevation.card;
  static List<BoxShadow> get float => dt.AppElevation.lifted;
}

/// Legacy type helper. Screens call `AppFont.sans(fontSize: …)`; this
/// forwards to the design system's typeface so there is still exactly
/// one place the font is chosen.
class AppFont {
  AppFont._();

  static TextStyle sans({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    List<Shadow>? shadows,
  }) =>
      ds.AppFont.style(
        TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
          height: height,
          fontStyle: fontStyle,
          decoration: decoration,
          shadows: shadows,
        ),
        color: color,
      );

  static TextTheme theme(TextTheme base) =>
      ds.AppFont.textTheme(base.bodyMedium?.color == null
          ? Brightness.light
          : Brightness.light);
}

/// Legacy entry point. Delegates to the design system's theme builder.
class AppTheme {
  AppTheme._();
  static ThemeData get light => ds.AppTheme.light();
  static ThemeData get dark => ds.AppTheme.dark();
}
