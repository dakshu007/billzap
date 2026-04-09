// lib/screens/main/shell_screen.dart
// ✅ PopScope with double-back-to-exit
// ✅ On any tab except home → back goes to home
// ✅ On home → first back shows toast, second back exits
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class ShellScreen extends StatefulWidget {
  final Widget child;
  final String location;
  const ShellScreen({super.key, required this.child, required this.location});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  // ✅ Timestamp of last back press (for double-back-to-exit)
  DateTime? _lastBackPress;

  /// Returns true if app should exit, false otherwise
  Future<bool> _handleBackPress() async {
    final isHome = widget.location.startsWith('/home');

    if (!isHome) {
      // ✅ Not on home → navigate to home instead of exiting
      context.go('/home');
      return false;
    }

    // ✅ On home page → double back to exit
    final now = DateTime.now();
    final lastPress = _lastBackPress;

    if (lastPress == null || now.difference(lastPress) > const Duration(seconds: 2)) {
      // First press → show toast and record timestamp
      _lastBackPress = now;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.exit_to_app_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text('Press back again to exit',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.t1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 20),
        ),
      );
      return false; // don't exit yet
    }

    // Second press within 2 seconds → exit app
    return true;
  }

  int get _idx {
    if (widget.location.startsWith('/home'))      return 0;
    if (widget.location.startsWith('/invoices'))  return 1;
    if (widget.location.startsWith('/reports'))   return 3;
    if (widget.location.startsWith('/settings'))  return 4;
    return 0;
  }

  void _go(BuildContext context, String path) {
    HapticFeedback.lightImpact();
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // ✅ Never allow default pop — we handle it ourselves
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldExit = await _handleBackPress();
        if (shouldExit && context.mounted) {
          SystemNavigator.pop(); // exit the app
        }
      },
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: KeyedSubtree(
            key: ValueKey(widget.location),
            child: widget.child,
          ),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
            boxShadow: [BoxShadow(
              color: Color(0x0D1557FF), blurRadius: 20, offset: Offset(0, -4))],
          ),
          child: SafeArea(
            child: SizedBox(height: 62, child: Row(children: [
              _NavItem(icon: Icons.home_rounded, label: 'Home',
                on: _idx == 0, onTap: () => _go(context, '/home')),
              _NavItem(icon: Icons.receipt_long_rounded, label: 'Invoices',
                on: _idx == 1, onTap: () => _go(context, '/invoices')),
              // Centre FAB
              Expanded(child: Center(child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  context.push('/create');
                },
                child: Container(
                  width: 54, height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(
                      color: AppColors.brand.withOpacity(0.35),
                      blurRadius: 14, offset: const Offset(0, 5))],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                ),
              ))),
              _NavItem(icon: Icons.bar_chart_rounded, label: 'Reports',
                on: _idx == 3, onTap: () => _go(context, '/reports')),
              _NavItem(icon: Icons.person_rounded, label: 'Me',
                on: _idx == 4, onTap: () => _go(context, '/settings')),
            ])),
          ),
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
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedScale(
          scale: on ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: Icon(icon, size: 22, color: on ? AppColors.brand : AppColors.t3),
        ),
        const SizedBox(height: 2),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: on ? FontWeight.w700 : FontWeight.w500,
            color: on ? AppColors.brand : AppColors.t3),
          child: Text(label),
        ),
      ]),
    ),
  );
}
