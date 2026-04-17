// lib/router/app_router.dart
// ✅ ShellScreen is a single page with PageView inside
// ✅ /home, /invoices, /reports, /settings all show ShellScreen
// ✅ /create and /preview are separate pages with custom transitions
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/main/shell_screen.dart';
import '../screens/invoice/create_invoice_screen.dart';
import '../screens/invoice/invoice_preview_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/main/customers_screen.dart';
import '../screens/main/products_screen.dart';
import '../screens/main/expenses_screen.dart';

CustomTransitionPage<void> _slideRight(BuildContext c, GoRouterState s, Widget w) {
  return CustomTransitionPage<void>(
    key: s.pageKey, child: w,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (c, a, sa, child) {
      final f = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(f),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.4, end: 1.0).animate(f),
          child: child));
    },
  );
}

CustomTransitionPage<void> _slideUp(BuildContext c, GoRouterState s, Widget w) {
  return CustomTransitionPage<void>(
    key: s.pageKey, child: w,
    transitionDuration: const Duration(milliseconds: 340),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (c, a, sa, child) {
      final f = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(f),
        child: FadeTransition(opacity: f, child: child));
    },
  );
}

CustomTransitionPage<void> _fade(BuildContext c, GoRouterState s, Widget w) {
  return CustomTransitionPage<void>(
    key: s.pageKey, child: w,
    transitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (c, a, _, child) =>
        FadeTransition(opacity: a, child: child),
  );
}

CustomTransitionPage<void> _none(BuildContext c, GoRouterState s, Widget w) {
  return CustomTransitionPage<void>(
    key: s.pageKey, child: w,
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
      // All tab routes show the same ShellScreen (PageView switches internally)
      GoRoute(
        path: '/home',
        pageBuilder: (c, s) => _none(c, s,
          ShellScreen(location: s.uri.path)),
      ),
      GoRoute(
        path: '/invoices',
        pageBuilder: (c, s) => _none(c, s,
          ShellScreen(location: s.uri.path)),
      ),
      GoRoute(
        path: '/reports',
        pageBuilder: (c, s) => _none(c, s,
          ShellScreen(location: s.uri.path)),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (c, s) => _none(c, s,
          ShellScreen(location: s.uri.path)),
      ),
      // Separate utility routes (dashboard quick actions)
      GoRoute(
        path: '/customers',
        pageBuilder: (c, s) => _slideRight(c, s, const CustomersScreen()),
      ),
      GoRoute(
        path: '/products',
        pageBuilder: (c, s) => _slideRight(c, s, const ProductsScreen()),
      ),
      GoRoute(
        path: '/expenses',
        pageBuilder: (c, s) => _slideRight(c, s, const ExpensesScreen()),
      ),
      // Full-screen routes
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
