# main.dart patch

Add the import at the top:

```dart
import 'i18n/translations.dart';
```

If your `MaterialApp.router` doesn't already wrap with `Directionality`, replace it with this so Urdu (RTL) works correctly:

```dart
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final lang = ref.watch(languageProvider);
    
    return MaterialApp.router(
      title: 'BillZap',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      routerConfig: router,
      builder: (context, child) {
        return Directionality(
          textDirection: lang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
    );
  }
}
```

The default language is already 'en' (English) — set in `LanguageNotifier()` constructor in translations.dart. When a user picks a language, it's saved to Hive and persists across app restarts.
