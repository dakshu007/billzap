// lib/screens/main/shell_screen.dart
// ✅ PageView-based tabs: swipe left/right between pages
// ✅ Single PopScope at shell root — catches ALL back gestures
// ✅ BMW-style smooth transitions
// ✅ Bottom nav with animated pill indicator
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'invoices_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class ShellScreen extends StatefulWidget {
  final Widget? child;
  final String location;
  const ShellScreen({super.key, this.child, required this.location});
  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  late final PageController _pc;
  int _idx = 0;
  DateTime? _lastBack;

  // The four tab screens — home + 3 others (skip index 2, that's the FAB)
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
      _idx = newIdx;
      _pc.animateToPage(newIdx,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  int _indexFor(String loc) {
    if (loc.startsWith('/invoices')) return 1;
    if (loc.startsWith('/reports'))  return 2;
    if (loc.startsWith('/settings')) return 3;
    return 0;
  }

  String _pathFor(int idx) {
    switch (idx) {
      case 1: return '/invoices';
      case 2: return '/reports';
      case 3: return '/settings';
      default: return '/home';
    }
  }

  void _onPageChanged(int i) {
    if (i == _idx) return;
    setState(() => _idx = i);
    HapticFeedback.selectionClick();
    // Sync URL without triggering animation
    final newPath = _pathFor(i);
    if (widget.location != newPath) {
      // Use replaceNamed-like behavior by directly updating router
      GoRouter.of(context).go(newPath);
    }
  }

  void _tapTab(int i) {
    if (i == _idx) return;
    HapticFeedback.lightImpact();
    _pc.animateToPage(i,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic);
  }

  Future<bool> _handleBack() async {
    // If not on home, animate back to home
    if (_idx != 0) {
      HapticFeedback.lightImpact();
      _pc.animateToPage(0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic);
      return false; // Block system back
    }

    // On home: first press shows toast, second exits within 2s
    final now = DateTime.now();
    if (_lastBack == null ||
        now.difference(_lastBack!) > const Duration(seconds: 2)) {
      _lastBack = now;
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 20),
        ));
      }
      return false; // Block exit
    }
    // Second press — allow system back (exits app)
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldExit = await _handleBack();
        if (shouldExit) {
          // Use SystemNavigator to properly exit
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: PageView(
          controller: _pc,
          onPageChanged: _onPageChanged,
          physics: const BouncingScrollPhysics(),
          children: _pages,
        ),
        bottomNavigationBar: _BmwNav(
          idx: _idx,
          onHome:     () => _tapTab(0),
          onInvoices: () => _tapTab(1),
          onCreate: () {
            HapticFeedback.mediumImpact();
            context.push('/create');
          },
          onReports: () => _tapTab(2),
          onMe:      () => _tapTab(3),
        ),
      ),
    );
  }
}

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
                  child: Container(
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
                    child: const Icon(Symbols.add, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
            _NavItem(icon: Symbols.bar_chart, label: 'Reports', on: idx == 2, onTap: onReports),
            _NavItem(icon: Symbols.person,    label: 'Me',      on: idx == 3, onTap: onMe),
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
            child: Icon(icon, size: 23,
                color: on ? AppColors.brand : AppColors.t3),
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
