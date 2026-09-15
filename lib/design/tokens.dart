// lib/design/tokens.dart
//
// ─────────────────────────────────────────────────────────────────────
// BILLZAP DESIGN SYSTEM — "Ink & Jade"
// ─────────────────────────────────────────────────────────────────────
//
// The brief: a GST billing app that feels premium. Premium here is not
// decoration — this app runs on a shop counter, one-handed, often in
// sunlight, and the invoice it produces is what the shopkeeper's own
// customer sees. So the feeling we are after is *quiet confidence*: a
// precision instrument that makes a small trader's output look like a
// bigger business made it.
//
// Three commitments drive every token below.
//
// 1. MONEY TYPOGRAPHY IS THE FOUNDATION. Every rupee figure is set in
//    tabular numerals so columns align and a total never jitters as it
//    recalculates. Amounts get their own type ramp, with the ₹ sign
//    optically reduced. Financial-grade legibility is most of the feel.
//
// 2. LAYERED MATERIAL, NOT FLAT CARDS. A raised surface catches light on
//    its top edge. Every elevated surface gets an ambient shadow, a 1px
//    top highlight, and a hairline edge. That trio is the difference
//    between a rectangle and an object.
//
// 3. MOTION WITH PHYSICS. Springs and staged entrances, not opacity
//    fades. Durations and curves live here so the whole app moves as one
//    system.
//
// Colour story: an ink foundation, JADE as the single precious accent
// (money, growth, auspicious), a strict semantic trio for invoice state,
// and a warm PAPER tone reserved for the invoice itself so a bill reads
// as a document rather than a screen.

import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

// ═════════════════════════════════════════════════════════════════════
// MODE
// ═════════════════════════════════════════════════════════════════════

/// Which palette the non-const tokens resolve to. Set once per frame from
/// the root widget, before `MaterialApp` paints, so custom widgets that
/// read these getters stay in lockstep with `ThemeData`.
enum AppMode { light, dark }

class AppTokens {
  AppTokens._();

  static AppMode _mode = AppMode.light;
  static AppMode get mode => _mode;
  static bool get isDark => _mode == AppMode.dark;
  static void setMode(Brightness b) =>
      _mode = b == Brightness.dark ? AppMode.dark : AppMode.light;

  static T pick<T>(T light, T dark) => isDark ? dark : light;
}

// ═════════════════════════════════════════════════════════════════════
// COLOUR
// ═════════════════════════════════════════════════════════════════════

class AppColor {
  AppColor._();

  // ─── Jade: the one precious accent ────────────────────────────────
  // Used for the primary action, positive money, and the "paid" state.
  // Deliberately the only saturated hue in the chrome, so it always
  // means something.
  static const jade900 = Color(0xFF04442F);
  static const jade700 = Color(0xFF066B4A);
  static const jade600 = Color(0xFF0A8A5F);
  static const jade500 = Color(0xFF10A56F); // canonical
  static const jade400 = Color(0xFF2FC08A);
  static const jade300 = Color(0xFF6BD9AE);
  static const jade100 = Color(0xFFD3F3E5);
  static const jade50  = Color(0xFFEBFAF3);

  // ─── Semantic trio for invoice state ──────────────────────────────
  // Tuned so each stays legible on both the light paper and the dark
  // ink card without needing per-mode variants at the call site.
  static const amber600 = Color(0xFFB4740B);
  static const amber500 = Color(0xFFD9930F);
  static const amber400 = Color(0xFFE9AE3D);
  static const amber100 = Color(0xFFFBEFD6);

  static const coral600 = Color(0xFFC53434);
  static const coral500 = Color(0xFFE04B4B);
  static const coral400 = Color(0xFFEE7070);
  static const coral100 = Color(0xFFFBE3E3);

  static const violet600 = Color(0xFF5B4BD4);
  static const violet500 = Color(0xFF7363E8);
  static const violet400 = Color(0xFF9285F0);
  static const violet100 = Color(0xFFE9E6FC);

  // ─── Ink: the foundation ──────────────────────────────────────────
  // A near-black with a faint cool cast — pure #000 reads cheap on OLED
  // and crushes the shadow layering the system depends on.
  static const ink950 = Color(0xFF07090C);
  static const ink900 = Color(0xFF0C1014);
  static const ink850 = Color(0xFF12171D);
  static const ink800 = Color(0xFF181E26);
  static const ink700 = Color(0xFF232B35);
  static const ink600 = Color(0xFF323C48);
  static const ink500 = Color(0xFF4C5866);
  static const ink400 = Color(0xFF6B7888);
  static const ink300 = Color(0xFF93A0AE);
  static const ink200 = Color(0xFFC2CAD4);
  static const ink100 = Color(0xFFE2E7EC);
  static const ink50  = Color(0xFFF1F4F7);

  // ─── Paper: reserved for the invoice ──────────────────────────────
  // A warm off-white that never appears in the chrome. When a bill uses
  // it, the bill reads as a physical document.
  static const paper     = Color(0xFFFBFAF7);
  static const paperEdge = Color(0xFFEFEBE3);
  static const paperInk  = Color(0xFF1A1714);
  static const paperDark     = Color(0xFF16161A);
  static const paperDarkEdge = Color(0xFF24242B);

  // ─── Resolved surfaces ────────────────────────────────────────────
  // `canvas` is the page. `surface` is a raised card. `raised` is a card
  // on a card. `sunken` is a well (inputs, chips, progress tracks).
  static Color get canvas  => AppTokens.pick(const Color(0xFFF7F8FA), ink950);
  static Color get surface => AppTokens.pick(Colors.white, ink850);
  static Color get raised  => AppTokens.pick(Colors.white, ink800);
  static Color get sunken  => AppTokens.pick(const Color(0xFFEDF0F4), ink900);

  /// Invoice document surface.
  static Color get docSurface => AppTokens.pick(paper, paperDark);
  static Color get docEdge    => AppTokens.pick(paperEdge, paperDarkEdge);

  // ─── Text ramp ────────────────────────────────────────────────────
  static Color get textPrimary   => AppTokens.pick(ink900, const Color(0xFFF2F5F8));
  static Color get textSecondary => AppTokens.pick(ink600, const Color(0xFFB6C0CC));
  static Color get textTertiary  => AppTokens.pick(ink400, const Color(0xFF7E8A99));
  static Color get textQuiet     => AppTokens.pick(ink300, const Color(0xFF58646F));

  // ─── Lines ────────────────────────────────────────────────────────
  static Color get hairline => AppTokens.pick(const Color(0xFFE6EAEF), const Color(0xFF1E252E));
  static Color get border   => AppTokens.pick(const Color(0xFFD8DEE6), const Color(0xFF2A333E));

  /// The top-edge light catch that makes a surface read as an object.
  static Color get topHighlight => AppTokens.pick(
      Colors.white.withValues(alpha: 0.9), Colors.white.withValues(alpha: 0.045));

  // ─── Primary action ───────────────────────────────────────────────
  // Jade holds in both modes; it is lifted slightly in dark so it keeps
  // the same perceived weight against the ink canvas.
  static Color get primary   => AppTokens.pick(jade500, jade400);
  static Color get onPrimary => AppTokens.pick(Colors.white, ink950);
  static Color get primarySoft =>
      AppTokens.pick(jade50, jade900.withValues(alpha: 0.42));

  /// A high-contrast neutral fill — used where jade would over-signal
  /// (secondary CTAs, the nav rail, selected chips).
  static Color get contrast   => AppTokens.pick(ink900, const Color(0xFFF2F5F8));
  static Color get onContrast => AppTokens.pick(Colors.white, ink950);

  // ─── Invoice state ────────────────────────────────────────────────
  static Color get paid    => AppTokens.pick(jade600, jade400);
  static Color get pending => AppTokens.pick(amber600, amber400);
  static Color get overdue => AppTokens.pick(coral600, coral400);
  static Color get draft   => AppTokens.pick(ink400, ink300);
  static Color get info    => AppTokens.pick(violet600, violet400);

  /// Low-alpha wash of any accent, weighted per mode so the tint reads
  /// the same against white paper and dark ink.
  static Color wash(Color accent) =>
      accent.withValues(alpha: AppTokens.pick(0.10, 0.18));
}

// ═════════════════════════════════════════════════════════════════════
// TYPOGRAPHY
// ═════════════════════════════════════════════════════════════════════

/// Numeric feature sets. Money must be tabular — proportional figures
/// make a column of totals look broken and cause the layout to twitch
/// every time a digit changes width.
class AppFeature {
  AppFeature._();
  static const tabular = <FontFeature>[
    FontFeature.tabularFigures(),
    FontFeature.slashedZero(),
  ];
}

/// Named type roles. Screens reference roles, never raw sizes, so the
/// ramp can be retuned in one place.
class AppType {
  AppType._();

  // Display — reserved for the one hero number on a screen.
  static const displayL = TextStyle(fontSize: 44, height: 1.02, fontWeight: FontWeight.w700, letterSpacing: -1.8);
  static const displayM = TextStyle(fontSize: 34, height: 1.06, fontWeight: FontWeight.w700, letterSpacing: -1.2);
  static const displayS = TextStyle(fontSize: 27, height: 1.1,  fontWeight: FontWeight.w700, letterSpacing: -0.8);

  // Titles
  static const titleL = TextStyle(fontSize: 22, height: 1.18, fontWeight: FontWeight.w700, letterSpacing: -0.5);
  static const titleM = TextStyle(fontSize: 17.5, height: 1.22, fontWeight: FontWeight.w600, letterSpacing: -0.3);
  static const titleS = TextStyle(fontSize: 15.5, height: 1.26, fontWeight: FontWeight.w600, letterSpacing: -0.2);

  // Body
  static const bodyL = TextStyle(fontSize: 15.5, height: 1.45, fontWeight: FontWeight.w400, letterSpacing: -0.1);
  static const bodyM = TextStyle(fontSize: 14,   height: 1.45, fontWeight: FontWeight.w400);
  static const bodyS = TextStyle(fontSize: 12.5, height: 1.4,  fontWeight: FontWeight.w400);

  // Labels — UI furniture, slightly tighter and heavier than body.
  static const labelL = TextStyle(fontSize: 14.5, height: 1.2, fontWeight: FontWeight.w600, letterSpacing: -0.2);
  static const labelM = TextStyle(fontSize: 13,   height: 1.2, fontWeight: FontWeight.w600, letterSpacing: -0.1);
  static const labelS = TextStyle(fontSize: 11.5, height: 1.2, fontWeight: FontWeight.w600);

  /// All-caps micro label for section eyebrows and status pills.
  static const overline = TextStyle(
      fontSize: 10.5, height: 1.1, fontWeight: FontWeight.w700, letterSpacing: 0.8);

  // Money — always tabular. `amountHero` is the one big figure; the
  // others step down for rows, cells and inline mentions.
  static const amountHero = TextStyle(
      fontSize: 40, height: 1.0, fontWeight: FontWeight.w700,
      letterSpacing: -1.8, fontFeatures: AppFeature.tabular);
  static const amountL = TextStyle(
      fontSize: 24, height: 1.1, fontWeight: FontWeight.w700,
      letterSpacing: -0.8, fontFeatures: AppFeature.tabular);
  static const amountM = TextStyle(
      fontSize: 17, height: 1.15, fontWeight: FontWeight.w600,
      letterSpacing: -0.4, fontFeatures: AppFeature.tabular);
  static const amountS = TextStyle(
      fontSize: 14.5, height: 1.2, fontWeight: FontWeight.w600,
      letterSpacing: -0.2, fontFeatures: AppFeature.tabular);
  /// Dense figures inside tables and item rows.
  static const numeric = TextStyle(
      fontSize: 13.5, height: 1.25, fontWeight: FontWeight.w500,
      fontFeatures: AppFeature.tabular);
}

// ═════════════════════════════════════════════════════════════════════
// SPACE, RADIUS, ELEVATION
// ═════════════════════════════════════════════════════════════════════

/// A 4pt base scale. Screens compose from these rather than typing
/// arbitrary numbers, which is what keeps the vertical rhythm even.
class AppSpace {
  AppSpace._();
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double xxl = 28;
  static const double xxxl = 40;

  /// Page gutter.
  static const double gutter = 20;

  /// Clearance so a scroll tail never hides under the floating nav.
  /// Sized for the dock (66) plus the create button above it (~52) plus
  /// both margins — measured against the rendered layout, not guessed.
  static const double navClearance = 178;
}

class AppRadius {
  AppRadius._();
  static const double xs    = 8;
  static const double sm    = 12;
  static const double md    = 16;
  static const double lg    = 22;
  static const double xl    = 28;
  static const double sheet = 32;
  static const double pill  = 999;

  static BorderRadius all(double r) => BorderRadius.circular(r);
}

/// Elevation as *light behaviour*, not a Material z-index.
///
/// Each level pairs a wide ambient shadow with a tighter contact shadow.
/// In dark mode shadows do almost nothing (there is no light to occlude),
/// so depth is carried by the surface step and the top highlight instead.
class AppElevation {
  AppElevation._();

  static List<BoxShadow> get none => const [];

  /// Resting card.
  static List<BoxShadow> get card => AppTokens.isDark
      ? const []
      : [
          BoxShadow(
              color: AppColor.ink900.withValues(alpha: 0.05),
              blurRadius: 20, spreadRadius: -8, offset: const Offset(0, 8)),
          BoxShadow(
              color: AppColor.ink900.withValues(alpha: 0.03),
              blurRadius: 4, spreadRadius: -2, offset: const Offset(0, 2)),
        ];

  /// Lifted — sheets, the nav dock, a pressed-forward CTA.
  static List<BoxShadow> get lifted => AppTokens.isDark
      ? [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 32, spreadRadius: -10, offset: const Offset(0, 14)),
        ]
      : [
          BoxShadow(
              color: AppColor.ink900.withValues(alpha: 0.13),
              blurRadius: 36, spreadRadius: -12, offset: const Offset(0, 16)),
          BoxShadow(
              color: AppColor.ink900.withValues(alpha: 0.05),
              blurRadius: 8, spreadRadius: -4, offset: const Offset(0, 4)),
        ];

  /// A jade glow under the primary CTA — the one place the accent is
  /// allowed to bleed past its own edge.
  static List<BoxShadow> glow(Color accent) => [
        BoxShadow(
            color: accent.withValues(alpha: AppTokens.pick(0.34, 0.26)),
            blurRadius: 24, spreadRadius: -8, offset: const Offset(0, 10)),
      ];
}

// ═════════════════════════════════════════════════════════════════════
// MOTION
// ═════════════════════════════════════════════════════════════════════

/// Motion is specified as physics, not as arbitrary milliseconds. Every
/// transition in the app draws from this set so the whole thing moves
/// with one temperament.
class AppMotion {
  AppMotion._();

  /// Micro feedback — a tap ripple, a chip filling in.
  static const fast = Duration(milliseconds: 160);

  /// The workhorse — most state changes.
  static const base = Duration(milliseconds: 260);

  /// Page-level, and anything travelling a long distance.
  static const slow = Duration(milliseconds: 420);

  /// Theme crossfade — long enough to read as deliberate.
  static const theme = Duration(milliseconds: 380);

  /// Settles without overshoot. Default for size/position.
  static const standard = Curves.easeOutCubic;

  /// A little overshoot — for something arriving or being emphasised.
  static const spring = Curves.easeOutBack;

  /// Decelerate hard — entering content.
  static const enter = Curves.easeOutQuint;

  /// Accelerate away — exiting content.
  static const exit = Curves.easeInCubic;

  /// Per-item delay for a staggered list entrance.
  static const stagger = Duration(milliseconds: 38);
}
