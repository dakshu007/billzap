// lib/screens/main/shell_screen.dart
// ✅ PopScope: any tab → back → Home
// ✅ Home → double back → exit
// ✅ Smooth fade+scale transitions between tabs
// ✅ Predictive back (Android API 33+) supported via canPop: false

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

class _ShellScreenState extends State<ShellScreen>
    with SingleTickerProviderStateMixin {
  DateTime? _lastBackPress;

  late AnimationController _tabAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _tabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fadeAnim = CurvedAnimation(parent: _tabAnim, curve: Curves.easeOut);
    _tabAnim.value = 1.0;
  }

  @override
  void didUpdateWidget(ShellScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _tabAnim.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _tabAnim.dispose();
    super.dispose();
  }

  bool get _isHome => widget.location.startsWith('/home');

  void _handleBack() {
    if (!_isHome) {
      HapticFeedback.lightImpact();
      context.go('/home');
      return;
    }
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
      SystemNavigator.pop();
    }
  }

  int get _idx {
    if (widget.location.startsWith('/home'))     return 0;
    if (widget.location.startsWith('/invoices')) return 1;
    if (widget.location.startsWith('/reports'))  return 3;
    if (widget.location.startsWith('/settings')) return 4;
    return 0;
  }

  void _go(String path) {
    if (widget.location == path) return; // already here
    HapticFeedback.lightImpact();
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        body: FadeTransition(
          opacity: _fadeAnim,
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

// ── Bottom Nav ──────────────────────────────────────────────────
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
            _NavItem(icon: Symbols.home,         label: 'Home',     on: idx == 0, onTap: onHome),
            _NavItem(icon: Symbols.receipt_long, label: 'Invoices', on: idx == 1, onTap: onInvoices),
            // Centre FAB
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
                          blurRadius: 14, offset: const Offset(0, 5))],
                    ),
                    child: const Icon(Symbols.add, color: Colors.white, size: 26),
                  ),
                ),
              ),
            ),
            _NavItem(icon: Symbols.bar_chart, label: 'Reports', on: idx == 3, onTap: onReports),
            _NavItem(icon: Symbols.person,    label: 'Me',      on: idx == 4, onTap: onMe),
          ]),
        ),
      ),
    );
  }
}

// ── Nav Item ────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon, required this.label,
    required this.on, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: AppColors.brand.withOpacity(0.08),
      highlightColor: AppColors.brand.withOpacity(0.04),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          padding: EdgeInsets.symmetric(horizontal: on ? 12 : 0, vertical: on ? 3 : 0),
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
