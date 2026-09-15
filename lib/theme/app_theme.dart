// lib/theme/app_theme.dart
//
// BillZap design system — "clean & minimal".
//
// The visual language is deliberately near-monochrome: a soft neutral page,
// pure-white cards with generous corner radii and near-invisible hairlines,
// and a single high-contrast "ink" tone that carries every primary action
// (CTAs, the nav dock, selected chips). Colour is reserved for meaning —
// paid / pending / overdue / stock — never for decoration.
//
// Theme-independent accents stay `static const` so widgets can keep using
// them inside const expressions. Surface / text / ink tokens are getters
// that flip with `AppColors.setMode(...)` before MaterialApp rebuilds.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Single source of truth for the app's typeface.
///
/// The brief asked for Google Sans. Google Sans is Google's proprietary
/// brand face and is not served by the Google Fonts open API (and so is
/// not reachable through the `google_fonts` package), so we ship Inter —
/// the closest open equivalent in proportion, x-height and numeral design.
/// Swapping to a licensed Google Sans later is a one-line change here plus
/// the font declaration in pubspec.yaml.
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
  }) => GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        fontStyle: fontStyle,
        decoration: decoration,
        shadows: shadows,
      );

  static TextTheme theme(TextTheme base) => GoogleFonts.interTextTheme(base);
}

class AppColors {
  AppColors._();

  // ─── Semantic accents (brightness-independent, const) ──────────────
  // Tuned to stay legible on both the white light-mode card and the near
  // black dark-mode card, so they can remain const at every call site.
  static const green  = Color(0xFF12A05E);
  static const red    = Color(0xFFE5484D);
  static const yellow = Color(0xFFD79A0B);
  static const orange = Color(0xFFE0662A);
  static const purple = Color(0xFF7C5CF5);
  static const blue   = Color(0xFF3B6FF6);
  static const navBg  = Color(0xFF111114);

  // ─── Ink (the primary tone) ────────────────────────────────────────
  // Near-black in light mode, near-white in dark mode. Every primary
  // surface — CTA, nav dock, selected chip — is painted in `brand` with
  // `onBrand` on top, so the pairing inverts correctly per theme.
  static const _lightInk   = Color(0xFF121216);
  static const _darkInk    = Color(0xFFF2F2F5);
  static const _lightOnInk = Color(0xFFFFFFFF);
  static const _darkOnInk  = Color(0xFF0C0C0F);

  static Color get brand     => isDark ? _darkInk : _lightInk;
  static Color get onBrand   => isDark ? _darkOnInk : _lightOnInk;
  /// Slightly recessed ink — pressed states, gradient tails.
  static Color get brandDark => isDark ? const Color(0xFFD8D8DE) : const Color(0xFF000000);

  // ─── Soft tints ────────────────────────────────────────────────────
  // Panel washes. Light = a barely-there pastel; dark = a deep tinted
  // overlay that sits cleanly on `_darkCard` so text over it stays
  // readable. `brandSoft` is intentionally neutral grey — the ink tone
  // has no hue to tint with.
  static const _lightBrandSoft   = Color(0xFFF1F1F4);
  static const _lightBrandSofter = Color(0xFFF7F7F9);
  static const _lightGreenSoft   = Color(0xFFE7F6EE);
  static const _lightRedSoft     = Color(0xFFFDECEC);
  static const _lightYellowSoft  = Color(0xFFFBF3E0);
  static const _lightOrangeSoft  = Color(0xFFFBEFE7);
  static const _lightPurpleSoft  = Color(0xFFF1EDFE);
  static const _lightBlueSoft    = Color(0xFFECF1FE);

  static const _darkBrandSoft    = Color(0xFF1E1E24);
  static const _darkBrandSofter  = Color(0xFF17171C);
  static const _darkGreenSoft    = Color(0xFF11251B);
  static const _darkRedSoft      = Color(0xFF2A1517);
  static const _darkYellowSoft   = Color(0xFF251E0F);
  static const _darkOrangeSoft   = Color(0xFF271A12);
  static const _darkPurpleSoft   = Color(0xFF1B1730);
  static const _darkBlueSoft     = Color(0xFF131B2E);

  static Color get brandSoft   => isDark ? _darkBrandSoft   : _lightBrandSoft;
  static Color get brandSofter => isDark ? _darkBrandSofter : _lightBrandSofter;
  static Color get greenSoft   => isDark ? _darkGreenSoft   : _lightGreenSoft;
  static Color get redSoft     => isDark ? _darkRedSoft     : _lightRedSoft;
  static Color get yellowSoft  => isDark ? _darkYellowSoft  : _lightYellowSoft;
  static Color get orangeSoft  => isDark ? _darkOrangeSoft  : _lightOrangeSoft;
  static Color get purpleSoft  => isDark ? _darkPurpleSoft  : _lightPurpleSoft;
  static Color get blueSoft    => isDark ? _darkBlueSoft    : _lightBlueSoft;

  // ─── Brightness-aware surfaces & text ──────────────────────────────
  static Brightness _mode = Brightness.light;
  static Brightness get mode => _mode;
  static bool get isDark => _mode == Brightness.dark;

  /// Call before `runApp` (or whenever the theme toggle flips) so the
  /// non-const tokens below resolve to the right palette on next paint.
  static void setMode(Brightness b) => _mode = b;

  // Light — a soft neutral page so pure-white cards read as raised
  // panels without needing a heavy border.
  static const _lightBg         = Color(0xFFF3F3F5);
  static const _lightCard       = Color(0xFFFFFFFF);
  static const _lightInset      = Color(0xFFF5F5F7);
  static const _lightT1         = Color(0xFF0C0C0F);
  static const _lightT2         = Color(0xFF37373D);
  static const _lightT3         = Color(0xFF76767E);
  static const _lightT4         = Color(0xFFA9A9B2);
  static const _lightBorder     = Color(0xFFEAEAEE);
  static const _lightBorderDark = Color(0xFFDCDCE2);

  // Dark — flat, low-glare, AMOLED friendly.
  static const _darkBg         = Color(0xFF0A0A0C);
  static const _darkCard       = Color(0xFF141418);
  static const _darkInset      = Color(0xFF1B1B20);
  static const _darkT1         = Color(0xFFF4F4F7);
  static const _darkT2         = Color(0xFFC6C6CE);
  static const _darkT3         = Color(0xFF8C8C96);
  static const _darkT4         = Color(0xFF5C5C66);
  static const _darkBorder     = Color(0xFF232329);
  static const _darkBorderDark = Color(0xFF2F2F37);

  static Color get bg         => isDark ? _darkBg : _lightBg;
  static Color get card       => isDark ? _darkCard : _lightCard;
  /// Recessed fill — chips, search fields, inline wells.
  static Color get inset      => isDark ? _darkInset : _lightInset;
  static Color get t1         => isDark ? _darkT1 : _lightT1;
  static Color get t2         => isDark ? _darkT2 : _lightT2;
  static Color get t3         => isDark ? _darkT3 : _lightT3;
  static Color get t4         => isDark ? _darkT4 : _lightT4;
  static Color get border     => isDark ? _darkBorder : _lightBorder;
  static Color get borderDark => isDark ? _darkBorderDark : _lightBorderDark;
}

/// Elevation is expressed as soft, wide, low-opacity shadows rather than
/// Material's grey scrims — that is what keeps the surfaces feeling light.
class AppShadow {
  AppShadow._();

  /// Resting card.
  static List<BoxShadow> get card => AppColors.isDark
      ? const []
      : [
          BoxShadow(
            color: const Color(0xFF0C0C14).withOpacity(0.04),
            blurRadius: 18,
            spreadRadius: -6,
            offset: const Offset(0, 8)),
        ];

  /// Floating surface — the nav dock, FABs, sheets.
  static List<BoxShadow> get float => [
        BoxShadow(
          color: const Color(0xFF0C0C14).withOpacity(AppColors.isDark ? 0.55 : 0.14),
          blurRadius: 30,
          spreadRadius: -8,
          offset: const Offset(0, 12)),
      ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark  => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isDark = b == Brightness.dark;
    final bg     = isDark ? AppColors._darkBg : AppColors._lightBg;
    final card   = isDark ? AppColors._darkCard : AppColors._lightCard;
    final inset  = isDark ? AppColors._darkInset : AppColors._lightInset;
    final t1     = isDark ? AppColors._darkT1 : AppColors._lightT1;
    final t3     = isDark ? AppColors._darkT3 : AppColors._lightT3;
    final t4     = isDark ? AppColors._darkT4 : AppColors._lightT4;
    final border = isDark ? AppColors._darkBorder : AppColors._lightBorder;
    final ink    = isDark ? AppColors._darkInk : AppColors._lightInk;
    final onInk  = isDark ? AppColors._darkOnInk : AppColors._lightOnInk;

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: AppFont.theme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ),
      colorScheme: ColorScheme(
        brightness: b,
        primary: ink,
        onPrimary: onInk,
        secondary: AppColors.green,
        onSecondary: Colors.white,
        error: AppColors.red,
        onError: Colors.white,
        surface: card,
        onSurface: t1,
        background: bg,
        onBackground: t1,
      ),
      scaffoldBackgroundColor: bg,
      // The app bar shares the page tone so the neutral field runs
      // edge-to-edge; white cards inside the body do the contrast work.
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: t1,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: AppFont.sans(
          fontSize: 20, fontWeight: FontWeight.w700, color: t1,
          letterSpacing: -0.4),
        iconTheme: IconThemeData(color: t1, size: 22),
      ),
      // NOTE: Flutter 3.19 expects `CardTheme` here (renamed to
      // `CardThemeData` only in 3.27+). Keep as CardTheme so the CI
      // build (3.19.6) compiles.
      // ignore: deprecated_member_use
      cardTheme: CardTheme(
        color: card, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: border),
        ),
      ),
      // Inputs are recessed wells, not outlined boxes — no visible border
      // at rest, an ink hairline on focus.
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: inset,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: AppFont.sans(fontSize: 13.5, color: t4, fontWeight: FontWeight.w400),
        labelStyle: AppFont.sans(fontSize: 12.5, fontWeight: FontWeight.w500, color: t3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: ink, width: 1.4)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.red)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.red, width: 1.4)),
      ),
      // Primary action = a full ink pill.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ink, foregroundColor: onInk,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: AppFont.sans(
            fontSize: 14.5, fontWeight: FontWeight.w600, letterSpacing: -0.1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t1, side: BorderSide(color: border),
          backgroundColor: card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: AppFont.sans(
            fontSize: 14.5, fontWeight: FontWeight.w600, letterSpacing: -0.1),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t1,
          textStyle: AppFont.sans(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: inset,
        side: BorderSide.none,
        labelStyle: AppFont.sans(fontSize: 13, fontWeight: FontWeight.w500, color: t1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected) ? onInk : (isDark ? t3 : Colors.white)),
        trackColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected) ? ink
              : (isDark ? AppColors._darkBorderDark : AppColors._lightBorderDark)),
        trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
      ),
      dividerTheme: DividerThemeData(color: border, space: 1, thickness: 1),
      // Sheets / dialogs / menus — large radii, flat surfaces, no tint.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: card,
        modalBarrierColor: Colors.black.withOpacity(isDark ? 0.62 : 0.32),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet))),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl)),
        titleTextStyle: AppFont.sans(
          fontSize: 17.5, fontWeight: FontWeight.w700, color: t1, letterSpacing: -0.3),
        contentTextStyle: AppFont.sans(fontSize: 14, color: t3, height: 1.45),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: border)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        elevation: 0,
        contentTextStyle: AppFont.sans(
          fontSize: 13.5, fontWeight: FontWeight.w500, color: onInk),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Corner radius scale. Generous and consistent — this is most of what
/// makes the UI read as "soft and clean" rather than boxy.
class AppRadius {
  AppRadius._();

  static const double xs    = 10;
  static const double sm    = 14;
  static const double md    = 16;
  static const double lg    = 20;
  static const double xl    = 26;
  static const double sheet = 28;
  static const double pill  = 999;
}
