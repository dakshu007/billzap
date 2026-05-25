// lib/screens/main/shell_screen.dart
// ✅ Native MainActivity forwards back press to Flutter via MethodChannel
// ✅ Flutter decides: pop sub-route OR snap to home OR show toast OR exit
// ✅ Direct tab jump on tap, parallax swipe between pages

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../theme/app_theme.dart';
import '../../i18n/translations.dart';
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      // Plain PageView — no per-frame Transform/Scale/Opacity wrappers.
      // The previous build re-evaluated those for every page on every
      // scroll tick (Opacity triggers `saveLayer`), which was the source
      // of the stutter. iOS-style bouncing physics gives a noticeably
      // softer overshoot at the edges while still being silky to flick.
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
