// lib/theme/app_theme.dart
//
// Theme + dynamic color tokens. Light mode is the default; dark mode is
// produced by flipping `AppColors.setMode(Brightness.dark)` before the
// MaterialApp rebuilds. Theme-independent brand colors stay `static const`
// so widgets that need const Color values keep working. Surface / text /
// border tokens are getters that respect the current brightness.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // ─── Brightness-independent brand palette (kept const) ─────────────
  static const brand       = Color(0xFF1557FF);
  static const brandDark   = Color(0xFF0A3BCC);
  static const brandSoft   = Color(0xFFEBF0FF);
  static const brandSofter = Color(0xFFF4F7FF);
  static const green       = Color(0xFF00BFA5);
  static const greenSoft   = Color(0xFFE6FAF7);
  static const red         = Color(0xFFEF4444);
  static const redSoft     = Color(0xFFFEF2F2);
  static const yellow      = Color(0xFFF59E0B);
  static const yellowSoft  = Color(0xFFFFFBEB);
  static const orange      = Color(0xFFFF5722);
  static const orangeSoft  = Color(0xFFFFF1EE);
  static const purple      = Color(0xFF7C3AED);
  static const purpleSoft  = Color(0xFFF5F3FF);
  static const navBg       = Color(0xFF0F172A);

  // ─── Brightness-aware tokens ───────────────────────────────────────
  // Default to light values; switched at runtime by AppColors.setMode().
  static Brightness _mode = Brightness.light;
  static Brightness get mode => _mode;
  static bool get isDark => _mode == Brightness.dark;

  /// Call before `runApp` (or whenever the theme toggle flips) so the
  /// non-const tokens below resolve to the dark palette on next paint.
  static void setMode(Brightness b) => _mode = b;

  // Light defaults (also used as fallback)
  static const _lightBg         = Color(0xFFF1F5FF);
  static const _lightCard       = Color(0xFFFFFFFF);
  static const _lightT1         = Color(0xFF0F172A);
  static const _lightT2         = Color(0xFF334155);
  static const _lightT3         = Color(0xFF64748B);
  static const _lightT4         = Color(0xFFCBD5E1);
  static const _lightBorder     = Color(0xFFE2E8F5);
  static const _lightBorderDark = Color(0xFFCBD5E1);

  // Dark equivalents (tuned for AMOLED-friendly low-glare contrast)
  static const _darkBg         = Color(0xFF0A1118);
  static const _darkCard       = Color(0xFF141B2A);
  static const _darkT1         = Color(0xFFE7EAF3);
  static const _darkT2         = Color(0xFFB6BFD2);
  static const _darkT3         = Color(0xFF8E97AC);
  static const _darkT4         = Color(0xFF50596B);
  static const _darkBorder     = Color(0xFF1F2A40);
  static const _darkBorderDark = Color(0xFF2A3654);

  static Color get bg         => isDark ? _darkBg : _lightBg;
  static Color get card       => isDark ? _darkCard : _lightCard;
  static Color get t1         => isDark ? _darkT1 : _lightT1;
  static Color get t2         => isDark ? _darkT2 : _lightT2;
  static Color get t3         => isDark ? _darkT3 : _lightT3;
  static Color get t4         => isDark ? _darkT4 : _lightT4;
  static Color get border     => isDark ? _darkBorder : _lightBorder;
  static Color get borderDark => isDark ? _darkBorderDark : _lightBorderDark;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark  => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isDark = b == Brightness.dark;
    final bg = isDark ? AppColors._darkBg : AppColors._lightBg;
    final card = isDark ? AppColors._darkCard : AppColors._lightCard;
    final t1 = isDark ? AppColors._darkT1 : AppColors._lightT1;
    final t3 = isDark ? AppColors._darkT3 : AppColors._lightT3;
    final t4 = isDark ? AppColors._darkT4 : AppColors._lightT4;
    final border = isDark ? AppColors._darkBorder : AppColors._lightBorder;

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ),
      colorScheme: ColorScheme(
        brightness: b,
        primary: AppColors.brand,
        onPrimary: Colors.white,
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
      appBarTheme: AppBarTheme(
        backgroundColor: card,
        foregroundColor: t1,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 19, fontWeight: FontWeight.w900, color: t1),
        iconTheme: IconThemeData(color: t1),
      ),
      cardTheme: CardThemeData(
        color: card, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: t4),
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: t3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.red)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.red, width: 1.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand, foregroundColor: Colors.white,
          elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t1, side: BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand,
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected) ? Colors.white : t4),
        trackColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected) ? AppColors.brand
              : (isDark ? AppColors._darkBorderDark : AppColors._lightBorderDark)),
        trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
      ),
      dividerTheme: DividerThemeData(color: border, space: 1, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: t1,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13, fontWeight: FontWeight.w500,
          color: isDark ? AppColors._darkBg : Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
