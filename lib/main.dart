// lib/main.dart — BillZap. 100% offline, no backend, no Firebase.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'design/theme.dart' as ds;
import 'design/tokens.dart';
import 'i18n/translations.dart';
import 'providers/theme_provider.dart';
import 'router/app_router.dart';
import 'services/app_lock_service.dart';
import 'services/local_storage.dart';
import 'utils/platform.dart';
import 'widgets/app_lock_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The UI face ships in assets/fonts. Left to its default,
  // google_fonts would quietly fetch it from fonts.gstatic.com on
  // first launch — a network call this app promises never to make,
  // and one that fails in exactly the shop BillZap is built for. With
  // fetching off, a missing or misnamed asset throws on startup in
  // debug instead of degrading to Roboto in the field.
  GoogleFonts.config.allowRuntimeFetching = false;

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Hive.initFlutter();
  await LocalStorage.instance.init();
  await AppLockService.instance.init();

  // Pre-open settings so theme + language resolve on the first frame
  // instead of flashing a default.
  try {
    await Hive.openBox('settings');
  } catch (_) {}
  try {
    initGlobalLanguage();
  } catch (_) {}

  runApp(const ProviderScope(child: BillZapApp()));
}

class BillZapApp extends ConsumerWidget {
  const BillZapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final platform = MediaQuery.platformBrightnessOf(context);
    final brightness = brightnessFor(themeMode, platform);

    // Custom widgets read the token getters directly, so the static
    // palette has to match the ThemeData about to be painted.
    AppTokens.setMode(brightness);
    final isDark = brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: AppColor.canvas,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    ));

    return MaterialApp.router(
      title: 'BillZap',
      debugShowCheckedModeBanner: false,
      theme: ds.AppTheme.light(),
      darkTheme: ds.AppTheme.dark(),
      themeMode: themeMode,
      // Slower than Material's 200ms default so the light/dark switch
      // reads as a deliberate transition rather than a hard cut.
      themeAnimationDuration: AppMotion.theme,
      themeAnimationCurve: AppMotion.standard,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        // Respect the user's text-size setting, but clamp it: this is a
        // dense financial UI and unbounded scaling breaks money columns.
        // Desktop sits further from the eye, so nudge it up.
        final base = mq.textScaler.scale(1.0).clamp(0.85, 1.25);
        final scale = AppPlatform.isDesktop ? base * 1.1 : base;
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(scale)),
          child: AppLockGate(child: child!),
        );
      },
    );
  }
}
