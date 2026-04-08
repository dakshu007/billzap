// lib/router/app_router.dart
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

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      ShellRoute(
        builder: (context, state, child) {
          final location = state.uri.path;
          return ShellScreen(location: location, child: child);
        },
        routes: [
          GoRoute(path: '/home', builder: (c, s) => const DashboardScreen()),
          GoRoute(path: '/invoices', builder: (c, s) => const InvoicesScreen()),
          GoRoute(path: '/customers', builder: (c, s) => const CustomersScreen()),
          GoRoute(path: '/products', builder: (c, s) => const ProductsScreen()),
          GoRoute(path: '/expenses', builder: (c, s) => const ExpensesScreen()),
          GoRoute(path: '/reports', builder: (c, s) => const ReportsScreen()),
          GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
        ],
      ),
      GoRoute(path: '/create', builder: (c, s) => const CreateInvoiceScreen()),
      GoRoute(path: '/preview', builder: (c, s) => const InvoicePreviewScreen()),
    ],
  );
});
