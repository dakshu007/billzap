// lib/theme/app_spacing.dart
//
// Layout rhythm. The clean/minimal look leans heavily on whitespace, so
// these are noticeably roomier than a stock Material layout: wider screen
// gutters, taller gaps between cards, and enough bottom padding for the
// floating nav dock to clear the last row of every list.
import 'package:flutter/widgets.dart';

import 'app_theme.dart';

class AppSpacing {
  AppSpacing._();

  // Layout
  static const double screenH = 20;
  static const double screenV = 16;
  /// Clearance for the floating nav dock (dock height + its bottom margin
  /// + breathing room). Every scrollable screen pads its tail by this.
  static const double bottomNavSafe = 124;

  // Card / item
  static const double card    = 18;
  static const double cardGap = 12;
  static const double rowGap  = 14;
  static const double section = 28;

  // Radius — delegated to the single scale in app_theme.dart so cards,
  // sheets and buttons stay in lockstep.
  static const double radiusSm = AppRadius.sm;
  static const double radius   = AppRadius.md;
  static const double radiusLg = AppRadius.lg;
  static const double radiusXl = AppRadius.xl;
  static const double pill     = AppRadius.pill;

  // Common edge insets
  static const EdgeInsets screen = EdgeInsets.fromLTRB(
    screenH, screenV, screenH, bottomNavSafe,
  );
  static const EdgeInsets listScreen = EdgeInsets.fromLTRB(
    screenH, 10, screenH, bottomNavSafe,
  );
  static const EdgeInsets card14 = EdgeInsets.all(card);
  static const EdgeInsets card12 = EdgeInsets.all(14);
}
