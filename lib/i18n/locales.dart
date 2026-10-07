// lib/i18n/locales.dart — every language the app can be read in, and
// which of them each country is offered.
//
// SOURCE
//
// "BillZap — Global Language & Localization Specification 2026",
// supplied by the project owner on 7 Oct 2026, built on Unicode CLDR 49
// coverage data. It lists 100 core CLDR-Modern locales and 20
// country-critical extensions, and a market matrix recommending which
// to offer in each of the 177 jurisdictions the app supports. The matrix
// names six locales that are not in either tier — pap, kea, ckb, ku, rm
// and la — and they are here too, so every language the document names
// can be picked.
//
// TWO DELIBERATE DEPARTURES FROM THE DOCUMENT, both written down here
// so nobody "fixes" them back:
//
//   • Singapore. The matrix lists zh-Hant. Singapore's official Chinese
//     is Simplified (the government standardised on it in 1969), so the
//     app offers zh-Hans there, with zh-Hant still findable by search.
//   • India. The matrix omits Urdu, Konkani and Hindi (Latin). Urdu was
//     one of the app's original twelve languages and real users have it
//     selected; dropping it from India's list would hide the language
//     they are reading in. Konkani and Hindi (Latin) both have India as
//     their default region in Tier 1 itself.
//
// THE RULE THE DOCUMENT IS EMPHATIC ABOUT, and this file follows
//
// A language is not a country. The language picked here changes the
// words on the screen and nothing else: the currency, digit grouping,
// tax name and tax rules all come from the shop's country, which is set
// separately in Settings → Country & tax. A French-speaking shop in
// Canada bills in Canadian dollars with Canada's tax.
//
// IDs are BCP 47 as the document gives them. Script variants (zh-Hans /
// zh-Hant, sr / sr-Latn, hi / hi-Latn, kk / kk-Arab, yue-Hant /
// yue-Hans) are separate entries because they render differently.

class AppLocale {
  /// BCP 47 id, and the name of the translation file in assets/i18n.
  final String id;

  /// Name in English, for search and for the secondary line.
  final String englishName;

  /// The language's name for itself, which is what a speaker looks for.
  final String nativeName;

  /// Right-to-left script.
  final bool rtl;

  /// ISO 3166 region the document gives as this locale's home.
  final String defaultRegion;

  const AppLocale(
    this.id,
    this.englishName,
    this.nativeName,
    this.defaultRegion, {
    this.rtl = false,
  });

  /// The bare language subtag: 'zh' for 'zh-Hans', 'sr' for 'sr-Latn'.
  String get language => id.split('-').first;

  /// The script subtag if the id carries one: 'Hans', 'Latn', 'Arab'.
  String? get script {
    final parts = id.split('-');
    return parts.length > 1 ? parts[1] : null;
  }

  @override
  String toString() => id;
}

/// Every language, in the document's order: Tier 1, Tier 2, then the
/// six the matrix adds.
const List<AppLocale> kAppLocales = [
  // ── Tier 1: CLDR Modern ─────────────────────────────────────────
  AppLocale('af', 'Afrikaans', 'Afrikaans', 'ZA'),
  AppLocale('am', 'Amharic', 'አማርኛ', 'ET'),
  AppLocale('ar', 'Arabic', 'العربية', 'EG', rtl: true),
  AppLocale('az', 'Azerbaijani', 'Azərbaycan', 'AZ'),
  AppLocale('bn', 'Bengali', 'বাংলা', 'BD'),
  AppLocale('ca', 'Catalan', 'Català', 'ES'),
  AppLocale('el', 'Greek', 'Ελληνικά', 'GR'),
  AppLocale('en', 'English', 'English', 'US'),
  AppLocale('es', 'Spanish', 'Español', 'ES'),
  AppLocale('fil', 'Filipino', 'Filipino', 'PH'),
  AppLocale('fr', 'French', 'Français', 'FR'),
  AppLocale('gu', 'Gujarati', 'ગુજરાતી', 'IN'),
  AppLocale('he', 'Hebrew', 'עברית', 'IL', rtl: true),
  AppLocale('hi', 'Hindi', 'हिन्दी', 'IN'),
  AppLocale('id', 'Indonesian', 'Bahasa Indonesia', 'ID'),
  AppLocale('it', 'Italian', 'Italiano', 'IT'),
  AppLocale('ja', 'Japanese', '日本語', 'JP'),
  AppLocale('kk', 'Kazakh', 'Қазақ тілі', 'KZ'),
  AppLocale('kn', 'Kannada', 'ಕನ್ನಡ', 'IN'),
  AppLocale('ko', 'Korean', '한국어', 'KR'),
  AppLocale('ky', 'Kyrgyz', 'Кыргызча', 'KG'),
  AppLocale('lo', 'Lao', 'ລາວ', 'LA'),
  AppLocale('ml', 'Malayalam', 'മലയാളം', 'IN'),
  AppLocale('mr', 'Marathi', 'मराठी', 'IN'),
  AppLocale('ms', 'Malay', 'Bahasa Melayu', 'MY'),
  AppLocale('nl', 'Dutch', 'Nederlands', 'NL'),
  AppLocale('pa', 'Punjabi', 'ਪੰਜਾਬੀ', 'IN'),
  AppLocale('pt', 'Portuguese', 'Português', 'BR'),
  AppLocale('ro', 'Romanian', 'Română', 'RO'),
  AppLocale('ru', 'Russian', 'Русский', 'RU'),
  AppLocale('sv', 'Swedish', 'Svenska', 'SE'),
  AppLocale('ta', 'Tamil', 'தமிழ்', 'IN'),
  AppLocale('te', 'Telugu', 'తెలుగు', 'IN'),
  AppLocale('th', 'Thai', 'ไทย', 'TH'),
  AppLocale('uk', 'Ukrainian', 'Українська', 'UA'),
  AppLocale('ur', 'Urdu', 'اردو', 'PK', rtl: true),
  AppLocale('vi', 'Vietnamese', 'Tiếng Việt', 'VN'),
  AppLocale('zh-Hans', 'Chinese (Simplified)', '简体中文', 'CN'),
  AppLocale('pl', 'Polish', 'Polski', 'PL'),
  AppLocale('cs', 'Czech', 'Čeština', 'CZ'),
  AppLocale('sk', 'Slovak', 'Slovenčina', 'SK'),
  AppLocale('sl', 'Slovenian', 'Slovenščina', 'SI'),
  AppLocale('lt', 'Lithuanian', 'Lietuvių', 'LT'),
  AppLocale('sr', 'Serbian (Cyrillic)', 'Српски', 'RS'),
  AppLocale('hr', 'Croatian', 'Hrvatski', 'HR'),
  AppLocale('de', 'German', 'Deutsch', 'DE'),
  AppLocale('fi', 'Finnish', 'Suomi', 'FI'),
  AppLocale('hu', 'Hungarian', 'Magyar', 'HU'),
  AppLocale('da', 'Danish', 'Dansk', 'DK'),
  AppLocale('no', 'Norwegian', 'Norsk bokmål', 'NO'),
  AppLocale('tr', 'Turkish', 'Türkçe', 'TR'),
  AppLocale('ne', 'Nepali', 'नेपाली', 'NP'),
  AppLocale('or', 'Odia', 'ଓଡ଼ିଆ', 'IN'),
  AppLocale('bg', 'Bulgarian', 'Български', 'BG'),
  AppLocale('zh-Hant', 'Chinese (Traditional)', '繁體中文', 'TW'),
  AppLocale('my', 'Burmese', 'မြန်မာ', 'MM'),
  AppLocale('km', 'Khmer', 'ខ្មែរ', 'KH'),
  AppLocale('ga', 'Irish', 'Gaeilge', 'IE'),
  AppLocale('lv', 'Latvian', 'Latviešu', 'LV'),
  AppLocale('sr-Latn', 'Serbian (Latin)', 'Srpski', 'RS'),
  AppLocale('be', 'Belarusian', 'Беларуская', 'BY'),
  AppLocale('hy', 'Armenian', 'Հայերեն', 'AM'),
  AppLocale('is', 'Icelandic', 'Íslenska', 'IS'),
  AppLocale('fa', 'Persian', 'فارسی', 'IR', rtl: true),
  AppLocale('sw', 'Swahili', 'Kiswahili', 'TZ'),
  AppLocale('cy', 'Welsh', 'Cymraeg', 'GB'),
  AppLocale('bs', 'Bosnian', 'Bosanski', 'BA'),
  AppLocale('uz', 'Uzbek', 'Oʻzbekcha', 'UZ'),
  AppLocale('sq', 'Albanian', 'Shqip', 'AL'),
  AppLocale('mk', 'Macedonian', 'Македонски', 'MK'),
  AppLocale('si', 'Sinhala', 'සිංහල', 'LK'),
  AppLocale('et', 'Estonian', 'Eesti', 'EE'),
  AppLocale('ka', 'Georgian', 'ქართული', 'GE'),
  AppLocale('ps', 'Pashto', 'پښتو', 'AF', rtl: true),
  AppLocale('tk', 'Turkmen', 'Türkmençe', 'TM'),
  AppLocale('mn', 'Mongolian', 'Монгол', 'MN'),
  AppLocale('kok', 'Konkani', 'कोंकणी', 'IN'),
  AppLocale('as', 'Assamese', 'অসমীয়া', 'IN'),
  AppLocale('gl', 'Galician', 'Galego', 'ES'),
  AppLocale('zu', 'Zulu', 'isiZulu', 'ZA'),
  AppLocale('ha', 'Hausa', 'Hausa', 'NG'),
  AppLocale('ig', 'Igbo', 'Igbo', 'NG'),
  AppLocale('yo', 'Yoruba', 'Èdè Yorùbá', 'NG'),
  AppLocale('gd', 'Scottish Gaelic', 'Gàidhlig', 'GB'),
  AppLocale('sd', 'Sindhi', 'سنڌي', 'PK', rtl: true),
  AppLocale('so', 'Somali', 'Soomaali', 'SO'),
  AppLocale('hi-Latn', 'Hindi (Latin)', 'Hindi (Roman)', 'IN'),
  AppLocale('eu', 'Basque', 'Euskara', 'ES'),
  AppLocale('nn', 'Norwegian Nynorsk', 'Norsk nynorsk', 'NO'),
  AppLocale('yue-Hant', 'Cantonese (Traditional)', '粵語 (繁體)', 'HK'),
  AppLocale('pcm', 'Nigerian Pidgin', 'Naijá', 'NG'),
  AppLocale('jv', 'Javanese', 'Basa Jawa', 'ID'),
  AppLocale('qu', 'Quechua', 'Runasimi', 'PE'),
  AppLocale('chr', 'Cherokee', 'ᏣᎳᎩ', 'US'),
  AppLocale('ak', 'Akan', 'Akan', 'GH'),
  AppLocale('hsb', 'Upper Sorbian', 'Hornjoserbšćina', 'DE'),
  AppLocale('dsb', 'Lower Sorbian', 'Dolnoserbšćina', 'DE'),
  AppLocale('cv', 'Chuvash', 'Чӑвашла', 'RU'),
  AppLocale('kk-Arab', 'Kazakh (Arabic)', 'قازاق تىلى', 'CN', rtl: true),
  AppLocale('yue-Hans', 'Cantonese (Simplified)', '粤语 (简体)', 'CN'),

  // ── Tier 2: country-critical ────────────────────────────────────
  AppLocale('rw', 'Kinyarwanda', 'Ikinyarwanda', 'RW'),
  AppLocale('sm', 'Samoan', 'Gagana Sāmoa', 'WS'),
  AppLocale('fj', 'Fijian', 'Vosa Vakaviti', 'FJ'),
  AppLocale('ht', 'Haitian Creole', 'Kreyòl ayisyen', 'HT'),
  AppLocale('bi', 'Bislama', 'Bislama', 'VU'),
  AppLocale('to', 'Tongan', 'Lea faka-Tonga', 'TO'),
  AppLocale('tn', 'Tswana', 'Setswana', 'BW'),
  AppLocale('xh', 'Xhosa', 'isiXhosa', 'ZA'),
  AppLocale('ti', 'Tigrinya', 'ትግርኛ', 'ER'),
  AppLocale('tg', 'Tajik', 'Тоҷикӣ', 'TJ'),
  AppLocale('mi', 'Māori', 'Te Reo Māori', 'NZ'),
  AppLocale('wo', 'Wolof', 'Wolof', 'SN'),
  AppLocale('ceb', 'Cebuano', 'Binisaya', 'PH'),
  AppLocale('tpi', 'Tok Pisin', 'Tok Pisin', 'PG'),
  AppLocale('pis', 'Pijin', 'Pijin', 'SB'),
  AppLocale('lb', 'Luxembourgish', 'Lëtzebuergesch', 'LU'),
  AppLocale('mt', 'Maltese', 'Malti', 'MT'),
  AppLocale('dv', 'Divehi', 'ދިވެހި', 'MV', rtl: true),
  AppLocale('ay', 'Aymara', 'Aymar aru', 'BO'),
  AppLocale('gn', 'Guarani', 'Avañeʼẽ', 'PY'),

  // ── Named by the market matrix, in neither tier ─────────────────
  AppLocale('pap', 'Papiamento', 'Papiamentu', 'AW'),
  AppLocale('kea', 'Kabuverdianu', 'Kabuverdianu', 'CV'),
  AppLocale('ckb', 'Central Kurdish', 'کوردیی ناوەندی', 'IQ', rtl: true),
  AppLocale('ku', 'Kurdish (Kurmanji)', 'Kurdî', 'TR'),
  AppLocale('rm', 'Romansh', 'Rumantsch', 'CH'),
  AppLocale('la', 'Latin', 'Latina', 'VA'),
];

final Map<String, AppLocale> _byId = {for (final l in kAppLocales) l.id: l};

/// The locale for an id, or null if the app has no such language.
AppLocale? appLocaleFor(String id) => _byId[id];

/// English is the floor: every lookup ends there.
const AppLocale kEnglish = AppLocale('en', 'English', 'English', 'US');

/// The document's market matrix, in its own order. Where it names a
/// locale the app has, that locale is offered for the country, first
/// listed first.
const Map<String, List<String>> _matrix = {
  'AL': ['sq'],
  'DZ': ['ar', 'fr'],
  'AO': ['pt'],
  'AG': ['en'],
  'AR': ['es'],
  'AM': ['hy'],
  'AW': ['pap', 'nl', 'en'],
  'AU': ['en'],
  'AT': ['de'],
  'AZ': ['az'],
  'BS': ['en'],
  'BH': ['ar', 'en'],
  'BD': ['bn', 'en'],
  'BY': ['be', 'ru'],
  'BE': ['nl', 'fr', 'de'],
  'BZ': ['en', 'es'],
  'BJ': ['fr'],
  'BM': ['en'],
  'BO': ['es', 'ay', 'qu'],
  'BA': ['bs', 'sr', 'hr'],
  'BW': ['en', 'tn'],
  'BR': ['pt'],
  'VG': ['en'],
  'BG': ['bg'],
  'BF': ['fr'],
  'KH': ['km'],
  'CM': ['fr', 'en'],
  'CA': ['en', 'fr'],
  'CV': ['pt', 'kea'],
  'KY': ['en'],
  'TD': ['fr', 'ar'],
  'CL': ['es'],
  'CN': ['zh-Hans'],
  'CO': ['es'],
  'KM': ['fr', 'ar'],
  'CG': ['fr'],
  'CD': ['fr'],
  'CR': ['es'],
  'HR': ['hr'],
  'CU': ['es'],
  'CY': ['el', 'en'],
  'CZ': ['cs'],
  'CI': ['fr'],
  'DK': ['da'],
  'DJ': ['fr', 'ar'],
  'DM': ['en'],
  'DO': ['es'],
  'EC': ['es'],
  'EG': ['ar'],
  'SV': ['es'],
  'ER': ['ti', 'ar', 'en'],
  'EE': ['et'],
  'ET': ['am', 'en'],
  'FJ': ['en', 'fj'],
  'FI': ['fi', 'sv'],
  'FR': ['fr'],
  'GA': ['fr'],
  'GM': ['en'],
  'GE': ['ka'],
  'DE': ['de'],
  'GH': ['en', 'ak'],
  'GI': ['en'],
  'GR': ['el'],
  'GD': ['en'],
  'GT': ['es'],
  'GN': ['fr'],
  'GW': ['pt'],
  'HT': ['ht', 'fr'],
  'HN': ['es'],
  'HK': ['yue-Hant', 'zh-Hant', 'en'],
  'HU': ['hu'],
  'IS': ['is'],
  'IN': [
    'en', 'hi', 'bn', 'ta', 'te', 'kn', 'ml', 'mr', 'gu', 'pa', 'or', 'as',
    'ne',
    // Not in the matrix — see the note at the top of this file.
    'ur', 'kok', 'hi-Latn',
  ],
  'ID': ['id', 'jv'],
  'IR': ['fa'],
  'IQ': ['ar', 'ckb', 'ku'],
  'IE': ['en', 'ga'],
  'IL': ['he', 'ar'],
  'IT': ['it'],
  'JM': ['en'],
  'JP': ['ja'],
  'JO': ['ar'],
  'KZ': ['kk', 'ru'],
  'KE': ['sw', 'en'],
  'KW': ['ar', 'en'],
  'KG': ['ky', 'ru'],
  'LA': ['lo'],
  'LV': ['lv'],
  'LB': ['ar', 'fr'],
  'LR': ['en'],
  'LY': ['ar'],
  'LI': ['de'],
  'LT': ['lt'],
  'LU': ['lb', 'fr', 'de'],
  'MO': ['zh-Hant', 'pt'],
  'MY': ['ms', 'en'],
  'MV': ['dv', 'en'],
  'ML': ['fr'],
  'MT': ['mt', 'en'],
  'MU': ['en', 'fr'],
  'MX': ['es'],
  'FM': ['en'],
  'MD': ['ro', 'ru'],
  'MC': ['fr'],
  'MN': ['mn'],
  'MA': ['ar', 'fr'],
  'MZ': ['pt'],
  'MM': ['my', 'en'],
  'NA': ['en'],
  'NP': ['ne'],
  'NL': ['nl'],
  'NZ': ['en', 'mi'],
  'NI': ['es'],
  'NE': ['fr'],
  'NG': ['en', 'ha', 'ig', 'yo', 'pcm'],
  'MK': ['mk'],
  'NO': ['no', 'nn'],
  'OM': ['ar', 'en'],
  'PK': ['ur', 'en', 'sd'],
  'PA': ['es'],
  'PG': ['en', 'tpi'],
  'PY': ['es', 'gn'],
  'PE': ['es', 'qu'],
  'PH': ['fil', 'en', 'ceb'],
  'PL': ['pl'],
  'PT': ['pt'],
  'QA': ['ar', 'en'],
  'RO': ['ro'],
  'RU': ['ru'],
  'RW': ['rw', 'en', 'fr', 'sw'],
  'WS': ['sm', 'en'],
  'SM': ['it'],
  'SA': ['ar'],
  'SN': ['fr', 'wo'],
  'RS': ['sr', 'sr-Latn'],
  'SC': ['en', 'fr'],
  'SL': ['en'],
  // The document says zh-Hant; Singapore uses Simplified. See the top.
  'SG': ['en', 'zh-Hans', 'ms', 'ta'],
  'SK': ['sk'],
  'SI': ['sl'],
  'SB': ['en', 'pis'],
  'SO': ['so', 'ar'],
  'ZA': ['en', 'zu', 'xh', 'af', 'tn'],
  'KR': ['ko'],
  'ES': ['es', 'ca', 'eu', 'gl'],
  'LK': ['si', 'ta'],
  'KN': ['en'],
  'LC': ['en'],
  'SD': ['ar', 'en'],
  'SR': ['nl'],
  'SE': ['sv'],
  'CH': ['de', 'fr', 'it', 'rm'],
  'TW': ['zh-Hant'],
  'TJ': ['tg', 'ru'],
  'TZ': ['sw', 'en'],
  'TH': ['th', 'en'],
  'TG': ['fr'],
  'TO': ['to', 'en'],
  'TT': ['en'],
  'TN': ['ar', 'fr'],
  'TM': ['tk', 'ru'],
  'TC': ['en'],
  'TR': ['tr'],
  'UG': ['en', 'sw'],
  'UA': ['uk'],
  'AE': ['ar', 'en'],
  'GB': ['en', 'cy', 'gd'],
  'US': ['en', 'es'],
  'UY': ['es'],
  'UZ': ['uz', 'ru'],
  'VU': ['bi', 'en', 'fr'],
  'VA': ['it', 'la'],
  'VE': ['es'],
  'VN': ['vi'],
  'YE': ['ar'],
  'ZM': ['en'],
  'ZW': ['en'],
};

/// Languages to offer first for a country: the matrix's own list, then
/// any language whose home region is this country but which the matrix
/// left out (Cherokee for the US, the Sorbian pair for Germany), and
/// English last if nothing else put it there — so no country's list is
/// ever empty and no language is unreachable from its own country.
List<AppLocale> localesForCountry(String countryCode) {
  final cc = countryCode.toUpperCase();
  final ids = <String>[...?_matrix[cc]];
  for (final l in kAppLocales) {
    if (l.defaultRegion == cc && !ids.contains(l.id)) ids.add(l.id);
  }
  if (!ids.contains('en')) ids.add('en');
  return [
    for (final id in ids)
      if (_byId[id] != null) _byId[id]!,
  ];
}

/// The raw matrix entry, for the tests that check it against the
/// document. Empty for a country the document does not list.
List<String> matrixLocalesFor(String countryCode) =>
    List.unmodifiable(_matrix[countryCode.toUpperCase()] ?? const []);

/// Every country code the matrix covers.
Iterable<String> get matrixCountries => _matrix.keys;

/// Case- and accent-insensitive search over the native and English
/// names and the id, so "espanol", "Spanish", "es" and "Español" all
/// find Spanish.
List<AppLocale> searchLocales(String query, [List<AppLocale>? within]) {
  final q = foldForSearch(query.trim());
  final pool = within ?? kAppLocales;
  if (q.isEmpty) return List.of(pool);
  return pool
      .where((l) =>
          foldForSearch(l.nativeName).contains(q) ||
          foldForSearch(l.englishName).contains(q) ||
          l.id.toLowerCase().startsWith(q))
      .toList();
}

const Map<String, String> _fold = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a', 'ā': 'a',
  'ç': 'c', 'č': 'c', 'ć': 'c',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ě': 'e', 'ə': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i',
  'ñ': 'n', 'ń': 'n',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', 'ō': 'o', 'ø': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u',
  'š': 's', 'ś': 's', 'ž': 'z', 'ź': 'z', 'ż': 'z', 'ł': 'l', 'ř': 'r',
  'ý': 'y', 'ğ': 'g', 'ş': 's', 'ı': 'i', 'ő': 'o', 'ű': 'u',
  'ʻ': '', 'ʼ': '', "'": '',
};

String foldForSearch(String s) {
  final lower = s.toLowerCase();
  final b = StringBuffer();
  for (final ch in lower.split('')) {
    b.write(_fold[ch] ?? ch);
  }
  return b.toString();
}
