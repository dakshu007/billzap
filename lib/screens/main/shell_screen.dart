// lib/screens/main/shell_screen.dart
// ✅ SINGLE PopScope at shell level only — no conflicts
// ✅ Samsung S23 gesture navigation compatible
// ✅ canPop: false blocks swipe-back on ALL tabs
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

  void _onBack() {
    if (!_isHome) {
      // ── Any tab → go to Home ─────────────────
      HapticFeedback.lightImpact();
      context.go('/home');
      return;
    }
    // ── Home: double-back to exit ─────────────
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 20),
      ));
    } else {
      SystemNavigator.pop();
    }
  }

  int get _idx {
    if (widget.location.startsWith('/home'))      return 0;
    if (widget.location.startsWith('/invoices'))  return 1;
    if (widget.location.startsWith('/reports'))   return 3;
    if (widget.location.startsWith('/settings'))  return 4;
    return 0;
  }

  void _go(String path) {
    if (widget.location == path) return;
    HapticFeedback.lightImpact();
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // canPop: false = intercepts ALL back gestures including Samsung swipe
      canPop: false,
      onPopInvoked: (didPop) {
        // didPop is always false since canPop: false
        _onBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          layoutBuilder: (curr, prev) => Stack(
            alignment: Alignment.topCenter,
            children: [...prev, if (curr != null) curr],
          ),
          child: KeyedSubtree(
            key: ValueKey(widget.location),
            child: widget.child,
          ),
        ),
        bottomNavigationBar: _BottomNav(
          idx: _idx,
          onHome:     () => _go('/home'),
          onInvoices: () => _go('/invoices'),
          onCreate: () {
            HapticFeedback.mediumImpact();
            context.push('/create');
          },
          onReports: () => _go('/reports'),
          onMe:      () => _go('/settings'),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int idx;
  final VoidCallback onHome, onInvoices, onCreate, onReports, onMe;
  const _BottomNav({required this.idx, required this.onHome,
    required this.onInvoices, required this.onCreate,
    required this.onReports, required this.onMe});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: AppColors.card,
      border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      boxShadow: [BoxShadow(
          color: Color(0x0D1557FF), blurRadius: 20, offset: Offset(0, -4))],
    ),
    child: SafeArea(
      child: SizedBox(height: 64, child: Row(children: [
        _NavItem(icon: Symbols.home,         label: 'Home',     on: idx == 0, onTap: onHome),
        _NavItem(icon: Symbols.receipt_long, label: 'Invoices', on: idx == 1, onTap: onInvoices),
        Expanded(child: Center(child: GestureDetector(
          onTap: onCreate,
          child: Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                  color: AppColors.brand.withOpacity(0.35),
                  blurRadius: 14, offset: const Offset(0, 5))],
            ),
            child: const Icon(Symbols.add, color: Colors.white, size: 26),
          ),
        ))),
        _NavItem(icon: Symbols.bar_chart, label: 'Reports', on: idx == 3, onTap: onReports),
        _NavItem(icon: Symbols.person,    label: 'Me',      on: idx == 4, onTap: onMe),
      ])),
    ),
  );
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label,
    required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: AppColors.brand.withOpacity(0.08),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
              horizontal: on ? 14 : 0, vertical: on ? 4 : 0),
          decoration: BoxDecoration(
            color: on ? AppColors.brandSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, size: 22, color: on ? AppColors.brand : AppColors.t3),
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
      ]),
    ),
  );
}
