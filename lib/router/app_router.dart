// lib/router/app_router.dart
// ✅ Each tab route is wrapped with PopScope at router level
// ✅ Back gesture on any tab → Home
// ✅ Back on Home → double-tap to exit
// ✅ Smooth transitions
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';

// ── Back-to-home wrapper for tab screens ─────────────────────
class _BackToHome extends StatelessWidget {
  final Widget child;
  const _BackToHome({required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        HapticFeedback.lightImpact();
        context.go('/home');
      },
      child: child,
    );
  }
}

// ── Home handler: double-back to exit ────────────────────────
class _HomeBackHandler extends StatefulWidget {
  final Widget child;
  const _HomeBackHandler({required this.child});

  @override
  State<_HomeBackHandler> createState() => _HomeBackHandlerState();
}

class _HomeBackHandlerState extends State<_HomeBackHandler> {
  DateTime? _lastPress;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastPress == null ||
            now.difference(_lastPress!) > const Duration(seconds: 2)) {
          _lastPress = now;
          HapticFeedback.lightImpact();
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
        } else {
          SystemNavigator.pop();
        }
      },
      child: widget.child,
    );
  }
}

// ── Transitions ──────────────────────────────────────────────
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

      // Shell — each tab has its own back handler
      ShellRoute(
        builder: (ctx, st, child) => ShellScreen(
          location: st.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (c, s) => _none(c, s,
              const _HomeBackHandler(child: DashboardScreen())),
          ),
          GoRoute(
            path: '/invoices',
            pageBuilder: (c, s) => _none(c, s,
              const _BackToHome(child: InvoicesScreen())),
          ),
          GoRoute(
            path: '/customers',
            pageBuilder: (c, s) => _none(c, s,
              const _BackToHome(child: CustomersScreen())),
          ),
          GoRoute(
            path: '/products',
            pageBuilder: (c, s) => _none(c, s,
              const _BackToHome(child: ProductsScreen())),
          ),
          GoRoute(
            path: '/expenses',
            pageBuilder: (c, s) => _none(c, s,
              const _BackToHome(child: ExpensesScreen())),
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (c, s) => _none(c, s,
              const _BackToHome(child: ReportsScreen())),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (c, s) => _none(c, s,
              const _BackToHome(child: SettingsScreen())),
          ),
        ],
      ),

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
