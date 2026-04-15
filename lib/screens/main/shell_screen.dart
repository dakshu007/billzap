// lib/screens/main/shell_screen.dart
// ✅ Back on ANY tab (Invoices/Reports/Me) → goes to Home
// ✅ Back on Home → first press shows toast
// ✅ Back on Home → second press within 2s → exits app
// ✅ Works for BOTH swipe gesture AND hardware back button

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../theme/app_theme.dart';

class ShellScreen extends StatefulWidget {
  final Widget child;
  final String location;
  const ShellScreen({super.key, required this.child, required this.location});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  DateTime? _lastBackPress;

  bool get _isHome => widget.location.startsWith('/home');

  void _handleBack() {
    if (!_isHome) {
      // ── Not Home → always go to Home ──────────
      HapticFeedback.lightImpact();
      context.go('/home');
      return;
    }

    // ── On Home → double press to exit ─────────
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Symbols.exit_to_app, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text('Press back again to exit',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.t1,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 20),
        ),
      );
    } else {
      // Second press → exit
      SystemNavigator.pop();
    }
  }

  int get _idx {
    if (widget.location.startsWith('/home')) return 0;
    if (widget.location.startsWith('/invoices')) return 1;
    if (widget.location.startsWith('/reports')) return 3;
    if (widget.location.startsWith('/settings')) return 4;
    return 0;
  }

  void _go(String path) {
    HapticFeedback.lightImpact();
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // canPop: false blocks BOTH hardware back AND predictive back gesture
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: KeyedSubtree(
            key: ValueKey(widget.location),
            child: widget.child,
          ),
        ),
        bottomNavigationBar: _BottomNav(
          idx: _idx,
          onHome: () => _go('/home'),
          onInvoices: () => _go('/invoices'),
          onCreate: () {
            HapticFeedback.mediumImpact();
            context.push('/create');
          },
          onReports: () => _go('/reports'),
          onMe: () => _go('/settings'),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int idx;
  final VoidCallback onHome, onInvoices, onCreate, onReports, onMe;
  const _BottomNav({
    required this.idx,
    required this.onHome,
    required this.onInvoices,
    required this.onCreate,
    required this.onReports,
    required this.onMe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        boxShadow: [BoxShadow(
            color: Color(0x0D1557FF), blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(children: [
            _NavItem(icon: Symbols.home, label: 'Home', on: idx == 0, onTap: onHome),
            _NavItem(icon: Symbols.receipt_long, label: 'Invoices', on: idx == 1, onTap: onInvoices),
            // FAB
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: onCreate,
                  child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(
                          color: AppColors.brand.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4))],
                    ),
                    child: const Icon(Symbols.add, color: Colors.white, size: 26),
                  ),
                ),
              ),
            ),
            _NavItem(icon: Symbols.bar_chart, label: 'Reports', on: idx == 3, onTap: onReports),
            _NavItem(icon: Symbols.person, label: 'Me', on: idx == 4, onTap: onMe),
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
  const _NavItem({required this.icon, required this.label, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: AppColors.brand.withOpacity(0.08),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimatedScale(
              scale: on ? 1.18 : 1.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: Icon(icon, size: 22, color: on ? AppColors.brand : AppColors.t3),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                color: on ? AppColors.brand : AppColors.t3,
              ),
              child: Text(label),
            ),
          ]),
        ),
      );
}
