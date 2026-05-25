// lib/main.dart — BillZap, 100% offline, zero Firebase
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/local_storage.dart';
import 'services/app_lock_service.dart';
import 'widgets/app_lock_gate.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'router/app_router.dart';
import 'i18n/translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Hive.initFlutter();
  await LocalStorage.instance.init();
  await AppLockService.instance.init();
  // Pre-open settings box so theme + language can read synchronously.
  try { await Hive.openBox('settings'); } catch (_) {}
  // Initialize multilang cache
  try { initGlobalLanguage(); } catch (_) {}

  runApp(const ProviderScope(child: BillZapApp()));
}

class BillZapApp extends ConsumerWidget {
  const BillZapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final platform  = MediaQuery.platformBrightnessOf(context);
    final brightness = brightnessFor(themeMode, platform);
    // Make sure the static AppColors palette matches the theme that
    // MaterialApp is about to paint. Custom widgets read these tokens
    // directly, so they need to be in sync with `themeMode`.
    syncAppColors(brightness);

    final isDark = brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: AppColors.bg,
      systemNavigationBarIconBrightness:
        isDark ? Brightness.light : Brightness.dark,
    ));

    return MaterialApp.router(
      title: 'BillZap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      // Stretch the default 200ms theme tween → 360ms with an ease curve so
      // the dark/light switch reads as a deliberate transition rather than
      // a hard cut. Scaffold, AppBar, dividers, switches, button themes
      // and the BottomNav (which now reads from theme) all crossfade in
      // lockstep.
      themeAnimationDuration: const Duration(milliseconds: 360),
      themeAnimationCurve: Curves.easeInOut,
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
