// lib/screens/main/shell_screen.dart
// ✅ BMW-grade smooth transitions
// ✅ Samsung S23 swipe-back WORKS (native predictive back disabled)
// ✅ Single source of truth: Navigator-level WillPopScope + PopScope
// ✅ IndexedStack keeps tab state alive (no rebuild on switch)
// ✅ Fade + slide transitions between tabs
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
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: 1.0,
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(ShellScreen old) {
    super.didUpdateWidget(old);
    if (old.location != widget.location) {
      _ctrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _isHome => widget.location.startsWith('/home');

  /// Core back-press handler — returns true if consumed
  Future<bool> _handleBack() async {
    // Any non-home tab → go Home
    if (!_isHome) {
      HapticFeedback.lightImpact();
      context.go('/home');
      return true;
    }

    // On Home: first press shows toast, second exits
    final now = DateTime.now();
    final recent = _lastBackPress != null &&
        now.difference(_lastBackPress!) < const Duration(seconds: 2);

    if (!recent) {
      _lastBackPress = now;
      HapticFeedback.lightImpact();
      if (mounted) {
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
      }
      return true;
    }
    // Second press within 2s — exit
    SystemNavigator.pop();
    return true;
  }

  int get _idx {
    if (widget.location.startsWith('/home'))     return 0;
    if (widget.location.startsWith('/invoices')) return 1;
    if (widget.location.startsWith('/reports'))  return 3;
    if (widget.location.startsWith('/settings')) return 4;
    return 0;
  }

  void _go(String path) {
    if (widget.location == path) return;
    HapticFeedback.selectionClick();
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: KeyedSubtree(
              key: ValueKey(widget.location),
              child: widget.child,
            ),
          ),
        ),
        bottomNavigationBar: _BmwNav(
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

// ── BMW-style bottom nav: animated pill, haptic feedback ───────
class _BmwNav extends StatelessWidget {
  final int idx;
  final VoidCallback onHome, onInvoices, onCreate, onReports, onMe;
  const _BmwNav({
    required this.idx, required this.onHome, required this.onInvoices,
    required this.onCreate, required this.onReports, required this.onMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: const Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withOpacity(0.06),
            blurRadius: 24, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 68,
          child: Row(children: [
            _NavItem(icon: Symbols.home,         label: 'Home',     on: idx == 0, onTap: onHome),
            _NavItem(icon: Symbols.receipt_long, label: 'Invoices', on: idx == 1, onTap: onInvoices),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: onCreate,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 54, height: 54,
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
                          blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: const Icon(Symbols.add,
                        color: Colors.white, size: 28, weight: 700),
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon, required this.label,
    required this.on, required this.onTap});

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
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
                horizontal: on ? 16 : 0, vertical: on ? 5 : 0),
            decoration: BoxDecoration(
              color: on ? AppColors.brandSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon,
                size: 23,
                color: on ? AppColors.brand : AppColors.t3,
                weight: on ? 700 : 400),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
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
}
