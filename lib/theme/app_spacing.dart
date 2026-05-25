// lib/theme/app_spacing.dart
// Centralised spacing tokens so screens share the same layout rhythm.
import 'package:flutter/widgets.dart';

class AppSpacing {
  AppSpacing._();

  // Layout
  static const double screenH = 14;
  static const double screenV = 12;
  static const double bottomNavSafe = 100;

  // Card / item
  static const double card = 14;
  static const double cardGap = 8;
  static const double rowGap = 10;

  // Radius
  static const double radiusSm = 8;
  static const double radius = 12;
  static const double radiusLg = 14;
  static const double pill = 99;

  // Common edge insets
  static const EdgeInsets screen = EdgeInsets.fromLTRB(
    screenH, screenV, screenH, bottomNavSafe,
  );
  static const EdgeInsets listScreen = EdgeInsets.fromLTRB(
    screenH, 8, screenH, bottomNavSafe,
  );
  static const EdgeInsets card14 = EdgeInsets.all(14);
  static const EdgeInsets card12 = EdgeInsets.all(12);
}
