// lib/router/app_router.dart
// ✅ Custom smooth transitions for all routes
// ✅ Shell tabs: fade+slide transition
// ✅ Full pages (create/preview): slide-up from bottom
// ✅ Splash: fade

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

// ── Slide-up from bottom (for modal-style screens) ──────────────
CustomTransitionPage<void> _slideUp(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final revCurve = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInCubic);
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(curve),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curve),
          child: SlideTransition(
            position: Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.06))
                .animate(revCurve),
            child: child,
          ),
        ),
      );
    },
  );
}

// ── Slide from right (for detail screens) ───────────────────────
CustomTransitionPage<void> _slideRight(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final revCurve = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInCubic);
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(curve),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.3, end: 1.0).animate(curve),
          child: SlideTransition(
            position: Tween<Offset>(begin: Offset.zero, end: const Offset(-0.1, 0))
                .animate(revCurve),
            child: child,
          ),
        ),
      );
    },
  );
}

// ── Fade only (for splash) ───────────────────────────────────────
CustomTransitionPage<void> _fade(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      // Splash
      GoRoute(
        path: '/splash',
        pageBuilder: (c, s) => _fade(c, s, const SplashScreen()),
      ),

      // Shell (bottom nav tabs) — transitions handled inside ShellScreen
      ShellRoute(
        builder: (context, state, child) =>
            ShellScreen(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/home',      builder: (c, s) => const DashboardScreen()),
          GoRoute(path: '/invoices',  builder: (c, s) => const InvoicesScreen()),
          GoRoute(path: '/customers', builder: (c, s) => const CustomersScreen()),
          GoRoute(path: '/products',  builder: (c, s) => const ProductsScreen()),
          GoRoute(path: '/expenses',  builder: (c, s) => const ExpensesScreen()),
          GoRoute(path: '/reports',   builder: (c, s) => const ReportsScreen()),
          GoRoute(path: '/settings',  builder: (c, s) => const SettingsScreen()),
        ],
      ),

      // Full-screen pages — slide up (modal feel)
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
