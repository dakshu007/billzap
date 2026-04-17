// lib/router/app_router.dart
// ✅ BMW-grade smooth route transitions
// ✅ Slide from right for detail screens (iOS-like)
// ✅ Fade for shell routes
// ✅ Slide up from bottom for modals (create invoice)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/main/shell_screen.dart';
import '../screens/main/dashboard_screen.dart';
import '../screens/main/invoices_screen.dart';
import '../screens/main/customers_screen.dart';
import '../screens/main/products_screen.dart';
import '../screens/main/expenses_screen.dart';
import '../screens/main/reports_screen.dart';
import '../screens/main/settings_screen.dart';
import '../screens/invoice/create_invoice_screen.dart';
import '../screens/invoice/invoice_preview_screen.dart';
import '../screens/splash/splash_screen.dart';

// ── Slide from right (iOS-like, premium feel) ────────────────
CustomTransitionPage<void> _slideRight(BuildContext ctx, GoRouterState st, Widget child) {
  return CustomTransitionPage<void>(
    key: st.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (ctx, anim, secAnim, child) {
      final fwd = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      final rev = CurvedAnimation(parent: secAnim, curve: Curves.easeInCubic);
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(fwd),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.4, end: 1.0).animate(fwd),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.25, 0),
            ).animate(rev),
            child: child,
          ),
        ),
      );
    },
  );
}

// ── Slide up from bottom (modal sheet style) ─────────────────
CustomTransitionPage<void> _slideUp(BuildContext ctx, GoRouterState st, Widget child) {
  return CustomTransitionPage<void>(
    key: st.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 340),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (ctx, anim, secAnim, child) {
      final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curve),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curve),
          child: child,
        ),
      );
    },
  );
}

// ── Clean fade (splash → home) ───────────────────────────────
CustomTransitionPage<void> _fade(BuildContext ctx, GoRouterState st, Widget child) {
  return CustomTransitionPage<void>(
    key: st.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (ctx, anim, _, child) =>
        FadeTransition(opacity: anim, child: child),
  );
}

// ── No transition (shell handles its own animations) ─────────
CustomTransitionPage<void> _noTransition(BuildContext ctx, GoRouterState st, Widget child) {
  return CustomTransitionPage<void>(
    key: st.pageKey,
    child: child,
    transitionDuration: Duration.zero,
    transitionsBuilder: (_, __, ___, child) => child,
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (c, s) => _fade(c, s, const SplashScreen()),
      ),

      // Shell — all tabs use no-transition (shell animates internally)
      ShellRoute(
        builder: (ctx, st, child) => ShellScreen(
          location: st.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(path: '/home',      pageBuilder: (c, s) => _noTransition(c, s, const DashboardScreen())),
          GoRoute(path: '/invoices',  pageBuilder: (c, s) => _noTransition(c, s, const InvoicesScreen())),
          GoRoute(path: '/customers', pageBuilder: (c, s) => _noTransition(c, s, const CustomersScreen())),
          GoRoute(path: '/products',  pageBuilder: (c, s) => _noTransition(c, s, const ProductsScreen())),
          GoRoute(path: '/expenses',  pageBuilder: (c, s) => _noTransition(c, s, const ExpensesScreen())),
          GoRoute(path: '/reports',   pageBuilder: (c, s) => _noTransition(c, s, const ReportsScreen())),
          GoRoute(path: '/settings',  pageBuilder: (c, s) => _noTransition(c, s, const SettingsScreen())),
        ],
      ),

      // Full-screen overlays
      GoRoute(
        path: '/create',
        pageBuilder: (c, s) => _slideUp(c, s, const CreateInvoiceScreen()),
      ),
      GoRoute(
        path: '/preview',
        pageBuilder: (c, s) => _slideRight(c, s, const InvoicePreviewScreen()),
      ),
    ],
  );
});
