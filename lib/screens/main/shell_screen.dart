// lib/screens/main/shell_screen.dart
// ✅ TAP nav → DIRECT JUMP to target tab (no slide-through)
// ✅ SWIPE → smooth parallax + scale animation between adjacent tabs
// ✅ BACK gesture → single press = toast, second press within 2s = exit
// ✅ Robust against duplicate PopScope events on Android

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
  DateTime? _lastBack;
  bool _backHandling = false; // guard against duplicate PopScope events

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
  }

  @override
  void didUpdateWidget(ShellScreen old) {
    super.didUpdateWidget(old);
    final newIdx = _indexFor(widget.location);
    if (newIdx != _idx && _pc.hasClients) {
      // Use jumpToPage for direct tab taps (no slide-through pages)
      _pc.jumpToPage(newIdx);
      setState(() => _idx = newIdx);
    }
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
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
    HapticFeedback.selectionClick();
    setState(() => _idx = i);
    GoRouter.of(context).go(_pathFor(i));
  }

  // ════════════════════════════════════════════════════════
  // TAP NAV → DIRECT JUMP (no slide through pages)
  // ════════════════════════════════════════════════════════
  void _tapTab(int i) {
    if (i == _idx) return;
    HapticFeedback.lightImpact();
    // jumpToPage = instant, no animation through other pages
    _pc.jumpToPage(i);
    setState(() => _idx = i);
    GoRouter.of(context).go(_pathFor(i));
  }

  // ════════════════════════════════════════════════════════
  // BACK GESTURE — robust double-press exit
  // ════════════════════════════════════════════════════════
  Future<bool> _handleBack() async {
    // Guard against duplicate calls (Android sometimes fires twice)
    if (_backHandling) return false;
    _backHandling = true;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _backHandling = false;
    });

    // If not on home tab, jump to home first
    if (_idx != 0) {
      _pc.jumpToPage(0);
      setState(() => _idx = 0);
      GoRouter.of(context).go('/home');
      _lastBack = null; // reset back timer
      return false;
    }

    // On home — double-press to exit
    final now = DateTime.now();
    if (_lastBack != null &&
        now.difference(_lastBack!) < const Duration(milliseconds: 1800)) {
      // Second press within window → exit
      return true;
    }

    // First press → save timestamp, show toast
    _lastBack = now;
    HapticFeedback.lightImpact();
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
        duration: const Duration(milliseconds: 1800),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.t1,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 20),
      ));
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (await _handleBack()) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: PageView.builder(
          controller: _pc,
          physics: const _CoolPhysics(),
          itemCount: _pages.length,
          onPageChanged: _onPageChanged,
          itemBuilder: (ctx, i) {
            return AnimatedBuilder(
              animation: _pc,
              child: _pages[i],
              builder: (ctx, child) {
                double offset = 0;
                if (_pc.position.haveDimensions) {
                  offset = (_pc.page ?? _idx.toDouble()) - i;
                }
                // Parallax + scale + fade for adjacent pages
                final clamped = offset.clamp(-1.0, 1.0);
                final scale = 1.0 - (clamped.abs() * 0.06);
                final opacity = 1.0 - (clamped.abs() * 0.25);
                return Transform.translate(
                  offset: Offset(clamped * 30, 0), // gentle parallax
                  child: Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: child,
                    ),
                  ),
                );
              },
            );
          },
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
      ),
    );
  }
}

// Custom physics — slightly springy feel between pages
class _CoolPhysics extends ScrollPhysics {
  const _CoolPhysics({super.parent});

  @override
  _CoolPhysics applyTo(ScrollPhysics? ancestor) {
    return _CoolPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 0.5,
        stiffness: 100,
        damping: 1.0,
      );

  @override
  double get minFlingVelocity => 50.0;

  @override
  double get maxFlingVelocity => 5000.0;
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: const Border(
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
                horizontal: on ? 16 : 0, vertical: on ? 5 : 0),
            decoration: BoxDecoration(
              color: on ? AppColors.brandSoft : Colors.transparent,
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
