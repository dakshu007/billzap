// lib/screens/main/shell_screen.dart
// ✅ Native MainActivity forwards back press to Flutter via MethodChannel
// ✅ Flutter decides: pop sub-route OR snap to home OR show toast OR exit
// ✅ Direct tab jump on tap, parallax swipe between pages

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../theme/app_theme.dart';
import '../../i18n/translations.dart';
import '../../providers/providers.dart';
import '../../utils/platform.dart';
import '../../widgets/liquid_glass_nav.dart';
import 'dashboard_screen.dart';
import 'invoices_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

const _backChannel = MethodChannel('billzap.app/back');

class ShellScreen extends ConsumerStatefulWidget {
  final Widget? child;
  final String location;
  const ShellScreen({super.key, this.child, required this.location});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  late final PageController _pc;
  int _idx = 0;
  DateTime? _lastBackTime;

  static const _pages = <Widget>[
    DashboardScreen(),
    InvoicesScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _idx = _indexFor(widget.location);
    _pc = PageController(initialPage: _idx);

    // Listen for back press from MainActivity.kt
    _backChannel.setMethodCallHandler((call) async {
      if (call.method == 'onBackPressed') {
        _handleBackFromNative();
      }
      return null;
    });
  }

  @override
  void didUpdateWidget(ShellScreen old) {
    super.didUpdateWidget(old);
    final newIdx = _indexFor(widget.location);
    if (newIdx != _idx && _pc.hasClients) {
      _pc.jumpToPage(newIdx);
      setState(() => _idx = newIdx);
    }
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════
  // SMART BACK HANDLER
  // Priority order:
  //   1. If a sub-route is on top (Create Invoice, Preview, etc.) → pop it
  //   2. If not on Home tab → snap to Home (no toast)
  //   3. If on Home tab → show "press again" toast / exit on second press
  // ════════════════════════════════════════════════════════
  void _handleBackFromNative() {
    final router = GoRouter.of(context);

    // Priority 1: pop sub-route (Create Invoice, Preview, etc.)
    if (router.canPop()) {
      router.pop();
      _lastBackTime = null; // reset exit timer when navigating back
      return;
    }

    // Priority 2: not on home tab → go to home
    if (_idx != 0) {
      _pc.jumpToPage(0);
      setState(() => _idx = 0);
      router.go('/home');
      _lastBackTime = null;
      return;
    }

    // Priority 3: on home tab → exit logic
    final now = DateTime.now();
    if (_lastBackTime != null &&
        now.difference(_lastBackTime!) < const Duration(milliseconds: 2000)) {
      // Second press within 2s → exit app via native
      _backChannel.invokeMethod('exitApp');
      return;
    }

    // First press → show toast
    _lastBackTime = now;
    HapticFeedback.mediumImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Symbols.exit_to_app, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(trGlobal('toast.exit_again'),
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
        duration: const Duration(milliseconds: 1900),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.t1,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 20),
      ));
    }
  }

  int _indexFor(String loc) {
    if (loc.startsWith('/invoices')) return 1;
    if (loc.startsWith('/reports')) return 2;
    if (loc.startsWith('/settings')) return 3;
    return 0;
  }

  String _pathFor(int i) {
    switch (i) {
      case 1: return '/invoices';
      case 2: return '/reports';
      case 3: return '/settings';
      default: return '/home';
    }
  }

  void _onPageChanged(int i) {
    if (i == _idx) return;
    // No haptic on swipe — the gesture itself is the feedback. Firing
    // selectionClick on every page-change felt twitchy while flicking.
    // Explicit tab *taps* (see _tapTab) still vibrate.
    setState(() => _idx = i);
    GoRouter.of(context).go(_pathFor(i));
  }

  void _tapTab(int i) {
    if (i == _idx) return;
    HapticFeedback.lightImpact();
    // Adjacent tab → animate (feels smoother than a jump). Non-adjacent
    // tab → jump (animating across multiple pages renders all the pages
    // in between, which causes a brief stutter).
    if ((i - _idx).abs() == 1) {
      _pc.animateToPage(i,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic);
    } else {
      _pc.jumpToPage(i);
    }
    setState(() => _idx = i);
    GoRouter.of(context).go(_pathFor(i));
  }

  @override
  Widget build(BuildContext context) {
    // Responsive: anything wider than 900 logical pixels gets the
    // desktop sidebar layout. macOS / Windows / Linux start above this
    // threshold by default; a phone in portrait stays well under.
    final width = MediaQuery.of(context).size.width;
    final wide = width >= 900;

    if (wide) {
      // Desktop layout — frosted glass sidebar on the left, content on
      // the right. PageView still owns the page state so swipe physics
      // continue to work if the window gets narrowed back down.
      //
      // The outer Scaffold is transparent ONLY on macOS, where the native
      // NSVisualEffectView (configured in MainFlutterWindow.swift) shines
      // the desktop wallpaper through behind the BackdropFilter sidebar.
      // On Windows/Linux there's no native vibrancy layer, so we paint the
      // cream background — the sidebar's blur then frosts the cream + a
      // sliver of content, which still reads as glass without leaving a
      // bare window-colour bar behind the sidebar.
      return Scaffold(
        backgroundColor:
            AppPlatform.isMacOS ? Colors.transparent : AppColors.bg,
        body: Row(children: [
          _GlassSidebar(
            idx: _idx,
            onHome: () => _tapTab(0),
            onInvoices: () => _tapTab(1),
            onCreate: () {
              HapticFeedback.mediumImpact();
              context.push('/create');
            },
            onReports: () => _tapTab(2),
            onMe: () => _tapTab(3),
          ),
          Expanded(child: PageView(
            controller: _pc,
            // Disable swipe on desktop — nav is via the sidebar, swipe
            // gestures collide with desktop scroll wheels and trackpads.
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: _onPageChanged,
            children: _pages,
          )),
        ]),
      );
    }

    // iOS — floating Liquid Glass bar overlaid on the content via a
    // Stack (so the frosted bar blurs the page scrolling behind it).
    // The pages already reserve ~100px bottom padding, so the floating
    // bar never covers the last row.
    if (AppPlatform.isIOS) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        // Let the body extend under the floating bar.
        body: Stack(children: [
          PageView(
            controller: _pc,
            physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
            onPageChanged: _onPageChanged,
            children: _pages,
          ),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: LiquidGlassNav(
              idx: _idx,
              onHome: () => _tapTab(0),
              onInvoices: () => _tapTab(1),
              onCreate: () {
                HapticFeedback.mediumImpact();
                context.push('/create');
              },
              onReports: () => _tapTab(2),
              onMe: () => _tapTab(3),
            ),
          ),
        ]),
      );
    }

    // Android / other mobile — docked cream nav, unchanged.
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: PageView(
        controller: _pc,
        physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
        onPageChanged: _onPageChanged,
        children: _pages,
      ),
      bottomNavigationBar: _BmwNav(
        idx: _idx,
        onHome: () => _tapTab(0),
        onInvoices: () => _tapTab(1),
        onCreate: () {
          HapticFeedback.mediumImpact();
          context.push('/create');
        },
        onReports: () => _tapTab(2),
        onMe: () => _tapTab(3),
      ),
    );
  }
}

class _BmwNav extends ConsumerWidget {
  final int idx;
  final VoidCallback onHome, onInvoices, onCreate, onReports, onMe;
  const _BmwNav({
    required this.idx,
    required this.onHome,
    required this.onInvoices,
    required this.onCreate,
    required this.onReports,
    required this.onMe,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // AnimatedContainer so the cream→dark background lerps over the same
    // window that the rest of the theme is animating in (see
    // `themeAnimationDuration` in main.dart). Reads `AppColors.bg` rather
    // than `card` so the footer joins the warm cream sweep in light mode.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border(
            top: BorderSide(color: AppColors.border, width: 0.5)),
        boxShadow: [
          BoxShadow(
              color: AppColors.brand.withOpacity(0.06),
              blurRadius: 24,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 68,
          child: Row(children: [
            _NavItem(
                icon: Symbols.home,
                label: tr('nav.home', ref),
                on: idx == 0,
                onTap: onHome),
            _NavItem(
                icon: Symbols.receipt_long,
                label: tr('nav.invoices', ref),
                on: idx == 1,
                onTap: onInvoices),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: onCreate,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.brand, Color(0xFF4070FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.brand.withOpacity(0.42),
                            blurRadius: 16,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    child: const Icon(Symbols.add,
                        color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
            _NavItem(
                icon: Symbols.bar_chart,
                label: tr('nav.reports', ref),
                on: idx == 2,
                onTap: onReports),
            _NavItem(
                icon: Symbols.person,
                label: tr('nav.me', ref),
                on: idx == 3,
                onTap: onMe),
          ]),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.on,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: AppColors.brand.withOpacity(0.10),
        highlightColor: AppColors.brand.withOpacity(0.05),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Active pill — a translucent brand wash sits proud of the
          // warm cream footer in light mode (the previous `brandSoft`
          // tint was too pale to read), and stays subtle in dark mode.
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
                horizontal: on ? 16 : 0, vertical: on ? 5 : 0),
            decoration: BoxDecoration(
              color: on
                  ? AppColors.brand.withOpacity(
                      AppColors.isDark ? 0.18 : 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon,
                size: 23, color: on ? AppColors.brand : AppColors.t3),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: on ? FontWeight.w700 : FontWeight.w500,
              color: on ? AppColors.brand : AppColors.t3,
            ),
            child: Text(label),
          ),
          const SizedBox(height: 2),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// LIQUID GLASS SIDEBAR — shown on desktop / wide windows (≥ 900 px)
// ════════════════════════════════════════════════════════════════════
//
// A frosted column on the left, with the logo at the top, four nav
// items, and a prominent "New invoice" CTA. Uses BackdropFilter to
// blur whatever's behind the sidebar — combined with the translucent
// NSWindow material on macOS (configured in MainFlutterWindow.swift),
// the desktop wallpaper shows through subtly.

class _GlassSidebar extends ConsumerWidget {
  final int idx;
  final VoidCallback onHome, onInvoices, onCreate, onReports, onMe;
  const _GlassSidebar({
    required this.idx,
    required this.onHome,
    required this.onInvoices,
    required this.onCreate,
    required this.onReports,
    required this.onMe,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biz = ref.watch(businessProvider);
    final bizName = biz?.name.isNotEmpty == true ? biz!.name : 'BillZap';
    final initial = bizName[0].toUpperCase();

    return ClipRRect(
      // The whole sidebar is one big blurred surface, edge-to-edge.
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: 248,
          decoration: BoxDecoration(
            color: AppColors.card.withOpacity(AppColors.isDark ? 0.55 : 0.62),
            border: Border(
              right: BorderSide(
                color: Colors.white.withOpacity(AppColors.isDark ? 0.06 : 0.5),
                width: 1)),
          ),
          child: SafeArea(
            child: Column(children: [
              // ─── Brand header ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.brand, Color(0xFF4070FF)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(
                        color: AppColors.brand.withOpacity(0.32),
                        blurRadius: 14, offset: const Offset(0, 6))]),
                    child: const Icon(Symbols.bolt, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 11),
                  Text('BillZap',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 19, fontWeight: FontWeight.w900,
                      color: AppColors.t1,
                      letterSpacing: -0.02)),
                ]),
              ),
              // ─── Primary CTA — New Invoice ────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Symbols.add, size: 20),
                    label: Text(tr('dash.new_invoice', ref),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              // ─── Nav items ────────────────────────────────────────
              _SideItem(
                icon: Symbols.home, label: tr('nav.home', ref),
                on: idx == 0, onTap: onHome),
              _SideItem(
                icon: Symbols.receipt_long, label: tr('nav.invoices', ref),
                on: idx == 1, onTap: onInvoices),
              _SideItem(
                icon: Symbols.bar_chart, label: tr('nav.reports', ref),
                on: idx == 2, onTap: onReports),
              _SideItem(
                icon: Symbols.person, label: tr('nav.me', ref),
                on: idx == 3, onTap: onMe),
              const Spacer(),
              // ─── Business footer ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(AppColors.isDark ? 0.04 : 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(AppColors.isDark ? 0.06 : 0.6),
                      width: 0.5),
                  ),
                  child: Row(children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.brand,
                        borderRadius: BorderRadius.circular(8)),
                      child: Center(child: Text(initial,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, fontWeight: FontWeight.w900,
                          color: Colors.white))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bizName,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5, fontWeight: FontWeight.w800,
                            color: AppColors.t1)),
                        Text(biz?.gstin.isNotEmpty == true
                            ? biz!.gstin
                            : 'No GSTIN',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5, color: AppColors.t3)),
                      ])),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _SideItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _SideItem({
    required this.icon, required this.label,
    required this.on, required this.onTap});

  @override
  State<_SideItem> createState() => _SideItemState();
}

class _SideItemState extends State<_SideItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.on;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 1, 12, 1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: on
                ? AppColors.brand.withOpacity(AppColors.isDark ? 0.18 : 0.14)
                : _hover
                  ? Colors.white.withOpacity(AppColors.isDark ? 0.04 : 0.5)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: on
                  ? AppColors.brand.withOpacity(0.22)
                  : Colors.transparent,
                width: 0.6),
            ),
            child: Row(children: [
              Icon(widget.icon,
                size: 19,
                color: on ? AppColors.brand : AppColors.t2),
              const SizedBox(width: 11),
              Text(widget.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                  color: on ? AppColors.brand : AppColors.t1)),
            ]),
          ),
        ),
      ),
    );
  }
}
