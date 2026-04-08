// lib/screens/main/shell_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class ShellScreen extends StatelessWidget {
  final Widget child;
  final String location;
  const ShellScreen({super.key, required this.child, required this.location});

  int get _idx {
    if (location.startsWith('/home'))      return 0;
    if (location.startsWith('/invoices'))  return 1;
    if (location.startsWith('/reports'))   return 3;
    if (location.startsWith('/settings'))  return 4;
    return 0;
  }

  void _go(BuildContext context, String path) {
    HapticFeedback.lightImpact();
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: child,
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
      onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 22, color: on ? AppColors.brand : AppColors.t3),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: on ? FontWeight.w700 : FontWeight.w500,
          color: on ? AppColors.brand : AppColors.t3)),
      ]),
    ),
  );
}
