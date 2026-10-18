// lib/i18n/dates.dart — dates on screen, in the language on screen.
//
// For the app's own screens only. The invoice PDF, the CSV exports and
// the GSTR-1 file keep their fixed English formats, because those are
// read by accountants, spreadsheets and a tax portal — and a date in
// Bengali digits in a GSTR-1 upload is a rejected return.
//
// Digits stay Latin in every language. intl would otherwise write
// Arabic-Indic, Persian, Bengali or Devanagari digits for some
// locales, and the amounts beside the date are Latin; a row that mixes
// two digit systems is harder to read than either.

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'translations.dart';

bool _ready = false;

/// Loads intl's month and weekday names. Called once from main().
Future<void> initUiDates() async {
  try {
    await initializeDateFormatting();
    _ready = true;
  } catch (_) {
    _ready = false;
  }
}

/// The intl locale for one of our language ids, or null for English.
String? _intlLocaleFor(String id) {
  const special = {
    'zh-Hans': 'zh_CN',
    'yue-Hans': 'zh_CN',
    'zh-Hant': 'zh_TW',
    'yue-Hant': 'zh_HK',
    'sr-Latn': 'sr_Latn',
    'no': 'nb',
  };
  final candidate = special[id] ?? (id.contains('-') ? null : id);
  if (candidate == null || candidate == 'en') return null;
  try {
    return DateFormat.localeExists(candidate) ? candidate : null;
  } catch (_) {
    return null;
  }
}

/// A date for the screen: `uiDate('d MMM', d)`.
String uiDate(String pattern, DateTime date) {
  if (_ready) {
    final loc = _intlLocaleFor(currentLangCode);
    if (loc != null) {
      try {
        final f = DateFormat(pattern, loc)..useNativeDigits = false;
        return f.format(date);
      } catch (_) {}
    }
  }
  return DateFormat(pattern).format(date);
}
