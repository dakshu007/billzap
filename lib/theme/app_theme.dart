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
  // Strong brand hues stay identical across themes. Only the "soft" tints
  // (used as panel backgrounds) flip per-mode — see the getters below.
  static const brand       = Color(0xFF1557FF);
  static const brandDark   = Color(0xFF0A3BCC);
  static const green       = Color(0xFF00BFA5);
  static const red         = Color(0xFFEF4444);
  static const yellow      = Color(0xFFF59E0B);
  static const orange      = Color(0xFFFF5722);
  static const purple      = Color(0xFF7C3AED);
  static const navBg       = Color(0xFF0F172A);

  // ─── Soft tints (brightness-aware) ─────────────────────────────────
  // Light = pale pastel of the hue. Dark = deep tinted overlay that sits
  // cleanly on `_darkCard` / `_darkBg` so text drawn over it stays
  // readable. These used to be `static const` but became getters so that
  // soft-backed panels (Profile Incomplete banner, GST Summary, etc.)
  // adapt to dark mode instead of staying stuck in light mode.
  static const _lightBrandSoft   = Color(0xFFEBF0FF);
  static const _lightBrandSofter = Color(0xFFF4F7FF);
  static const _lightGreenSoft   = Color(0xFFE6FAF7);
  static const _lightRedSoft     = Color(0xFFFEF2F2);
  static const _lightYellowSoft  = Color(0xFFFFFBEB);
  static const _lightOrangeSoft  = Color(0xFFFFF1EE);
  static const _lightPurpleSoft  = Color(0xFFF5F3FF);

  static const _darkBrandSoft    = Color(0xFF1B2546);
  static const _darkBrandSofter  = Color(0xFF161D38);
  static const _darkGreenSoft    = Color(0xFF12281F);
  static const _darkRedSoft      = Color(0xFF2A1818);
  static const _darkYellowSoft   = Color(0xFF2B2517);
  static const _darkOrangeSoft   = Color(0xFF2D1F16);
  static const _darkPurpleSoft   = Color(0xFF20183A);

  static Color get brandSoft   => isDark ? _darkBrandSoft   : _lightBrandSoft;
  static Color get brandSofter => isDark ? _darkBrandSofter : _lightBrandSofter;
  static Color get greenSoft   => isDark ? _darkGreenSoft   : _lightGreenSoft;
  static Color get redSoft     => isDark ? _darkRedSoft     : _lightRedSoft;
  static Color get yellowSoft  => isDark ? _darkYellowSoft  : _lightYellowSoft;
  static Color get orangeSoft  => isDark ? _darkOrangeSoft  : _lightOrangeSoft;
  static Color get purpleSoft  => isDark ? _darkPurpleSoft  : _lightPurpleSoft;

  // ─── Brightness-aware tokens ───────────────────────────────────────
  // Default to light values; switched at runtime by AppColors.setMode().
  static Brightness _mode = Brightness.light;
  static Brightness get mode => _mode;
  static bool get isDark => _mode == Brightness.dark;

  /// Call before `runApp` (or whenever the theme toggle flips) so the
  /// non-const tokens below resolve to the dark palette on next paint.
  static void setMode(Brightness b) => _mode = b;

  // Light defaults (also used as fallback). Light bg is a warm cream so
  // the white card surfaces pop against it (#F6F2E9 — requested tone).
  static const _lightBg         = Color(0xFFF6F2E9);
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
      // AppBar shares the scaffold tone so the warm cream extends edge-to-edge
      // in light mode (and the dark surface stays flat in dark mode). White
      // "card" surfaces inside the body do the heavy contrast lifting.
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: t1,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 19, fontWeight: FontWeight.w900, color: t1),
        iconTheme: IconThemeData(color: t1),
      ),
      // NOTE: Flutter 3.19 expects `CardTheme` here (renamed to
      // `CardThemeData` only in 3.27+). Keep as CardTheme so the CI
      // build (3.19.6) compiles.
      // ignore: deprecated_member_use
      cardTheme: CardTheme(
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
      // Default sheet surfaces — used by Material's showModalBottomSheet,
      // PopupMenu and AlertDialog when no explicit colour is provided.
      // Without these, dark-mode sheets fall back to a near-white Material
      // surface and look stuck in light mode.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: card,
        modalBarrierColor: Colors.black.withOpacity(isDark ? 0.6 : 0.4),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
      ),
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
