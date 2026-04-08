// lib/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();
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
  static const t1          = Color(0xFF0F172A);
  static const t2          = Color(0xFF334155);
  static const t3          = Color(0xFF64748B);
  static const t4          = Color(0xFFCBD5E1);
  static const bg          = Color(0xFFF1F5FF);
  static const card        = Color(0xFFFFFFFF);
  static const border      = Color(0xFFE2E8F5);
  static const borderDark  = Color(0xFFCBD5E1);
  static const navBg       = Color(0xFF0F172A);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.brand,
        secondary: AppColors.green,
        error: AppColors.red,
        surface: AppColors.card,
        background: AppColors.bg,
      ),
      scaffoldBackgroundColor: AppColors.bg,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.t1,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.t1),
        iconTheme: const IconThemeData(color: AppColors.t1),
      ),
      cardTheme: CardTheme(
        color: AppColors.card, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        hintStyle: GoogleFonts.dmSans(fontSize: 13, color: AppColors.t4),
        labelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.t3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border)),
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
          textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.t1, side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand,
          textStyle: GoogleFonts.dmSans(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected) ? Colors.white : AppColors.t4),
        trackColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected) ? AppColors.brand : AppColors.borderDark),
        trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.t1,
        contentTextStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
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
