// lib/main.dart — BillZap. 100% offline, no backend, no Firebase.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'design/palette_scope.dart';
import 'personal/spending_store.dart';
import 'design/theme.dart' as ds;
import 'design/tokens.dart';
import 'i18n/dates.dart';
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
    await Hive.openBox(kSpendingBox);
  } catch (_) {}
  // Awaited: the saved language's file is read before the first frame,
  // so the app opens in it instead of flashing English.
  await initGlobalLanguage();
  await initUiDates();

  runApp(const ProviderScope(child: BillZapApp()));
}

class BillZapApp extends ConsumerWidget {
  const BillZapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final lang = currentLanguage(ref.watch(languageProvider));
    final materialLocale = materialLocaleFor(lang);
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
      // No ThemeData lerp. The custom widgets read static tokens that
      // flip in one frame, so a lerping ThemeData left Material parts
      // mid-fade beside custom parts already switched. PaletteScope
      // does the transition instead, as one cross-fade of the whole
      // screen.
      themeAnimationDuration: Duration.zero,
      // Material's built-in strings follow the language where Flutter
      // has them; where it does not, English. The reading direction is
      // set below from our own table, which knows Divehi and Sindhi
      // read right to left even where Material has no strings for them.
      locale: materialLocale,
      supportedLocales: {materialLocale, const Locale('en')}.toList(),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
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
          child: Directionality(
            textDirection: lang.rtl ? TextDirection.rtl : TextDirection.ltr,
            child: PaletteScope(
              brightness: brightness,
              language: lang.id,
              child: AppLockGate(child: child!),
            ),
          ),
        );
      },
    );
  }
}

/// The locale Material's own strings are drawn from for a language.
///
/// Flutter ships Material strings for about eighty languages. Where it
/// has the language, use it. Where the language is a script variant
/// Flutter does not have — Hindi in Latin letters, Kazakh in Arabic
/// script — English, because Devanagari or Cyrillic buttons would be
/// unreadable to exactly the person who chose the variant. Cantonese
/// borrows Chinese in its own script.
Locale materialLocaleFor(AppLocale l) {
  switch (l.id) {
    case 'zh-Hans':
    case 'yue-Hans':
      return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
    case 'zh-Hant':
      return const Locale.fromSubtags(
          languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW');
    case 'yue-Hant':
      return const Locale.fromSubtags(
          languageCode: 'zh', scriptCode: 'Hant', countryCode: 'HK');
    case 'sr-Latn':
      return const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');
  }
  if (l.script != null) return const Locale('en');
  final locale = Locale(l.language);
  return GlobalMaterialLocalizations.delegate.isSupported(locale)
      ? locale
      : const Locale('en');
}
