// lib/screens/main/shell_screen.dart
//
// The tab shell. Behaviour is unchanged from before the redesign:
//   • Native MainActivity forwards the back press to Flutter over a
//     MethodChannel, and Flutter decides pop / snap-to-home / exit.
//   • Tapping a tab jumps straight to it; swiping pages between them.
// What changed is the chrome: phones get the floating ink nav dock, and
// wide windows get a flat, borderless sidebar instead of the frosted one.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:billzap/theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../../i18n/translations.dart';
import '../../providers/providers.dart';
import '../../utils/platform.dart';
import '../../widgets/app_nav_dock.dart';
import '../../widgets/ui_kit.dart';
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
          Icon(Symbols.exit_to_app, color: AppColors.onBrand, size: 18),
          const SizedBox(width: 10),
          Text(trGlobal('toast.exit_again'),
              style: AppFont.sans(
                  fontWeight: FontWeight.w500,
                  fontSize: 13.5,
                  color: AppColors.onBrand)),
        ]),
        duration: const Duration(milliseconds: 1900),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.brand,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 96),
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

  void _create() {
    HapticFeedback.mediumImpact();
    context.push('/create');
  }

  AppNavDock _dock(WidgetRef ref, {required bool floating}) => AppNavDock(
        idx: _idx,
        floating: floating,
        onHome: () => _tapTab(0),
        onInvoices: () => _tapTab(1),
        onCreate: _create,
        onReports: () => _tapTab(2),
        onMe: () => _tapTab(3),
        homeIcon: Symbols.home,
        invoicesIcon: Symbols.receipt_long,
        createIcon: Symbols.add,
        reportsIcon: Symbols.bar_chart,
        meIcon: Symbols.person,
        homeLabel: tr('nav.home', ref),
        invoicesLabel: tr('nav.invoices', ref),
        createLabel: tr('dash.new_invoice', ref),
        reportsLabel: tr('nav.reports', ref),
        meLabel: tr('nav.me', ref),
      );

  @override
  Widget build(BuildContext context) {
    // Responsive: anything wider than 900 logical pixels gets the
    // desktop sidebar layout. macOS / Windows / Linux start above this
    // threshold by default; a phone in portrait stays well under.
    final width = MediaQuery.of(context).size.width;
    final wide = width >= 900;

    if (wide) {
      // Desktop layout — a flat sidebar on the left, content on the right.
      // PageView still owns the page state so swipe physics continue to
      // work if the window gets narrowed back down.
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Row(children: [
          _Sidebar(
            idx: _idx,
            onHome: () => _tapTab(0),
            onInvoices: () => _tapTab(1),
            onCreate: _create,
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

    // Phones (both platforms now) — the floating ink dock overlaid on the
    // content via a Stack, so the page scrolls underneath it. Every page
    // reserves `AppSpacing.bottomNavSafe` at its tail, so the dock never
    // covers the last row.
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(children: [
        PageView(
          controller: _pc,
          physics: AppPlatform.isIOS
              ? const PageScrollPhysics(parent: BouncingScrollPhysics())
              : const PageScrollPhysics(parent: ClampingScrollPhysics()),
          onPageChanged: _onPageChanged,
          children: _pages,
        ),
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Consumer(
            builder: (_, ref, __) => _dock(ref, floating: true)),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// SIDEBAR — shown on desktop / wide windows (≥ 900 px)
// ════════════════════════════════════════════════════════════════════
//
// Flat and borderless: the page tone on the left, card-white content on
// the right, an ink CTA at the top and an ink pill marking the active
// destination. No blur, no gradients — the same language as the phone.

class _Sidebar extends ConsumerWidget {
  final int idx;
  final VoidCallback onHome, onInvoices, onCreate, onReports, onMe;
  const _Sidebar({
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

    return Container(
      width: 268,
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Column(children: [
          // ─── Brand header ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
            child: Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(11)),
                child: Icon(Symbols.bolt, color: AppColors.onBrand, size: 19),
              ),
              const SizedBox(width: 11),
              Text('BillZap',
                style: AppFont.sans(
                  fontSize: 19, fontWeight: FontWeight.w700,
                  color: AppColors.t1,
                  letterSpacing: -0.5)),
            ]),
          ),
          // ─── Primary CTA — New Invoice ────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: AppInkButton(
              label: tr('dash.new_invoice', ref),
              icon: Symbols.add,
              onPressed: onCreate),
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
                color: AppColors.inset,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(children: [
                AppBadge(initial: bizName, size: 34),
                const SizedBox(width: 11),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bizName,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: AppFont.sans(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: AppColors.t1)),
                    Text(biz?.gstin.isNotEmpty == true
                        ? biz!.gstin
                        : 'No GSTIN',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: AppFont.sans(
                        fontSize: 11, color: AppColors.t3)),
                  ])),
              ]),
            ),
          ),
        ]),
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
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: on
                ? AppColors.brand
                : _hover ? AppColors.inset : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(children: [
              Icon(widget.icon,
                size: 20,
                color: on ? AppColors.onBrand : AppColors.t2),
              const SizedBox(width: 13),
              Text(widget.label,
                style: AppFont.sans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: on ? AppColors.onBrand : AppColors.t1)),
            ]),
          ),
        ),
      ),
    );
  }
}
