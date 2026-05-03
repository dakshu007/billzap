// lib/main.dart — BillZap, 100% offline, zero Firebase
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/local_storage.dart';
import 'services/app_lock_service.dart';
import 'widgets/app_lock_gate.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';
import 'i18n/translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  await Hive.initFlutter();
  await LocalStorage.instance.init();
  await AppLockService.instance.init();
  // Initialize multilang cache
  try { initGlobalLanguage(); } catch (_) {}

  runApp(const ProviderScope(child: BillZapApp()));
}

class BillZapApp extends ConsumerWidget {
  const BillZapApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'BillZap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(
            MediaQuery.of(context).textScaler.scale(1.0).clamp(0.85, 1.15)),
        ),
        child: AppLockGate(child: child!),
      ),
    );
  }
}
