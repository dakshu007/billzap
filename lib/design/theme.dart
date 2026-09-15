// lib/design/theme.dart
//
// ThemeData assembled from design/tokens.dart. Nothing here invents a
// value — every colour, radius, duration and type role comes from the
// token layer, so retuning the system is a single-file edit.
//
// Typeface: Plus Jakarta Sans. It is a geometric humanist with a tall
// x-height (good in sunlight at a counter), genuinely distinct letter
// shapes at small sizes, and — critically for a billing app — a proper
// tabular-figure set, which is what lets money columns line up.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

class AppFont {
  AppFont._();

  static TextStyle style(TextStyle base, {Color? color}) =>
      GoogleFonts.plusJakartaSans(textStyle: base).copyWith(color: color);

  static TextTheme textTheme(Brightness b) {
    final base = b == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;
    return GoogleFonts.plusJakartaSansTextTheme(base);
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    // Resolve tokens for the mode being built. The root widget keeps
    // AppTokens in sync for runtime reads; this makes the *static*
    // ThemeData correct regardless of current mode.
    final previous = AppTokens.mode;
    AppTokens.setMode(brightness);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColor.primary,
      onPrimary: AppColor.onPrimary,
      primaryContainer: AppColor.primarySoft,
      onPrimaryContainer: AppColor.primary,
      secondary: AppColor.contrast,
      onSecondary: AppColor.onContrast,
      error: AppColor.overdue,
      onError: Colors.white,
      surface: AppColor.surface,
      onSurface: AppColor.textPrimary,
      surfaceContainerHighest: AppColor.sunken,
      outline: AppColor.border,
      outlineVariant: AppColor.hairline,
    );

    final text = AppFont.textTheme(brightness);

    final theme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColor.canvas,
      canvasColor: AppColor.canvas,
      splashFactory: InkSparkle.splashFactory,
      textTheme: text,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColor.canvas,
        foregroundColor: AppColor.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: AppFont.style(AppType.titleL, color: AppColor.textPrimary),
        iconTheme: IconThemeData(color: AppColor.textPrimary, size: 22),
      ),

      cardTheme: CardThemeData(
        color: AppColor.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.all(AppRadius.lg),
          side: BorderSide(color: AppColor.hairline),
        ),
      ),

      // Inputs are sunken wells: no border at rest, a jade hairline on
      // focus. Less chrome per field means denser forms stay calm.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColor.sunken,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg, vertical: AppSpace.lg),
        hintStyle: AppFont.style(AppType.bodyM, color: AppColor.textQuiet),
        labelStyle: AppFont.style(AppType.labelM, color: AppColor.textSecondary),
        floatingLabelStyle: AppFont.style(AppType.labelM, color: AppColor.primary),
        border: OutlineInputBorder(
            borderRadius: AppRadius.all(AppRadius.md),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.all(AppRadius.md),
            borderSide: BorderSide(color: AppColor.hairline)),
        focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.all(AppRadius.md),
            borderSide: BorderSide(color: AppColor.primary, width: 1.6)),
        errorBorder: OutlineInputBorder(
            borderRadius: AppRadius.all(AppRadius.md),
            borderSide: BorderSide(color: AppColor.overdue)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppRadius.all(AppRadius.md),
            borderSide: BorderSide(color: AppColor.overdue, width: 1.6)),
        errorStyle: AppFont.style(AppType.labelS, color: AppColor.overdue),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.primary,
          foregroundColor: AppColor.onPrimary,
          disabledBackgroundColor: AppColor.sunken,
          disabledForegroundColor: AppColor.textQuiet,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.all(AppRadius.pill)),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.xxl, vertical: 17),
          textStyle: AppFont.style(AppType.labelL),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColor.textPrimary,
          backgroundColor: AppColor.surface,
          side: BorderSide(color: AppColor.border),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.all(AppRadius.pill)),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.xxl, vertical: 17),
          textStyle: AppFont.style(AppType.labelL),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColor.primary,
          textStyle: AppFont.style(AppType.labelM),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColor.sunken,
        selectedColor: AppColor.contrast,
        side: BorderSide.none,
        labelStyle: AppFont.style(AppType.labelM, color: AppColor.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all(AppRadius.pill)),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md, vertical: AppSpace.sm),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColor.onPrimary
                : AppTokens.pick(Colors.white, AppColor.ink300)),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColor.primary : AppColor.border),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: AppColor.primary,
        inactiveTrackColor: AppColor.sunken,
        thumbColor: AppColor.primary,
      ),

      dividerTheme: DividerThemeData(
          color: AppColor.hairline, space: 1, thickness: 1),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColor.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColor.surface,
        modalBarrierColor:
            Colors.black.withValues(alpha: AppTokens.pick(0.34, 0.62)),
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: AppColor.border,
        dragHandleSize: const Size(40, 4),
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppRadius.sheet))),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColor.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all(AppRadius.xl)),
        titleTextStyle: AppFont.style(AppType.titleM, color: AppColor.textPrimary),
        contentTextStyle:
            AppFont.style(AppType.bodyM, color: AppColor.textSecondary),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: AppColor.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.all(AppRadius.md),
          side: BorderSide(color: AppColor.hairline),
        ),
        textStyle: AppFont.style(AppType.bodyM, color: AppColor.textPrimary),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColor.contrast,
        elevation: 0,
        contentTextStyle:
            AppFont.style(AppType.labelM, color: AppColor.onContrast),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all(AppRadius.md)),
        insetPadding: const EdgeInsets.fromLTRB(
            AppSpace.gutter, 0, AppSpace.gutter, AppSpace.xl),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColor.contrast,
          borderRadius: AppRadius.all(AppRadius.xs),
        ),
        textStyle: AppFont.style(AppType.labelS, color: AppColor.onContrast),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColor.primary,
        linearTrackColor: AppColor.sunken,
        circularTrackColor: AppColor.sunken,
      ),

      // Android gets the M3 fade-through; iOS keeps its native
      // interactive back-swipe, which users there expect.
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
      }),
    );

    AppTokens.setMode(previous == AppMode.dark ? Brightness.dark : Brightness.light);
    return theme;
  }
}
