// lib/tax/countries.dart — the country picker's list.
//
// GENERATED-ish: a flat table rather than 173 const objects, because at
// this length the objects are unreadable and the table is not.
//
// WHAT THIS IS AND IS NOT
//
// Country names, ISO 3166-1 alpha-2 codes and ISO 4217 currencies are
// public, stable reference data. They are not tax law, which is why
// they can live here while rates cannot — see profiles.dart.
//
// The currency is a sensible DEFAULT for the picker, not an assertion.
// A shop can change its symbol, and for the four researched countries
// the profile's own currency wins. Nothing here decides what anyone is
// taxed.
//
// Only AE, IN, SA and SG have researched tax profiles. Every other row
// resolves to customProfile, where the shopkeeper sets their own rate
// and label. That is the honest position for a country nobody has
// checked, and it is why this list can be long without being a lie.

class Country {
  const Country(this.code, this.name, this.currencyCode, this.currencySymbol);

  /// ISO 3166-1 alpha-2.
  final String code;
  final String name;

  /// ISO 4217, and a symbol for display.
  final String currencyCode;
  final String currencySymbol;

  @override
  String toString() => '$code $name';
}

/// code|name|currencyCode|symbol, one per line.
const String _table = '''
AL|Albania|ALL|L
DZ|Algeria|DZD|د.ج
AO|Angola|AOA|Kz
AG|Antigua & Barbuda|XCD|$
AR|Argentina|ARS|$
AM|Armenia|AMD|֏
AW|Aruba|AWG|ƒ
AU|Australia|AUD|$
AT|Austria|EUR|€
AZ|Azerbaijan|AZN|₼
BS|Bahamas|BSD|$
BH|Bahrain|BHD|.د.ب
BD|Bangladesh|BDT|৳
BY|Belarus|BYN|Br
BE|Belgium|EUR|€
BZ|Belize|BZD|$
BJ|Benin|XOF|CFA
BM|Bermuda|BMD|$
BO|Bolivia|BOB|Bs.
BA|Bosnia & Herzegovina|BAM|KM
BW|Botswana|BWP|P
BR|Brazil|BRL|R$
VG|British Virgin Islands|USD|$
BG|Bulgaria|BGN|лв
BF|Burkina Faso|XOF|CFA
KH|Cambodia|KHR|៛
CM|Cameroon|XAF|FCFA
CA|Canada|CAD|$
CV|Cape Verde|CVE|$
KY|Cayman Islands|KYD|$
TD|Chad|XAF|FCFA
CL|Chile|CLP|$
CN|China|CNY|¥
CO|Colombia|COP|$
KM|Comoros|KMF|CF
CG|Congo - Brazzaville|XAF|FCFA
CD|Congo - Kinshasa|CDF|FC
CR|Costa Rica|CRC|₡
HR|Croatia|EUR|€
CU|Cuba|CUP|$
CY|Cyprus|EUR|€
CZ|Czechia|CZK|Kč
CI|Côte d'Ivoire|XOF|CFA
DK|Denmark|DKK|kr
DJ|Djibouti|DJF|Fdj
DM|Dominica|XCD|$
DO|Dominican Republic|DOP|RD$
EC|Ecuador|USD|$
EG|Egypt|EGP|E£
SV|El Salvador|USD|$
ER|Eritrea|ERN|Nfk
EE|Estonia|EUR|€
ET|Ethiopia|ETB|Br
FJ|Fiji|FJD|$
FI|Finland|EUR|€
FR|France|EUR|€
GA|Gabon|XAF|FCFA
GM|Gambia|GMD|D
GE|Georgia|GEL|₾
DE|Germany|EUR|€
GH|Ghana|GHS|₵
GI|Gibraltar|GIP|£
GR|Greece|EUR|€
GD|Grenada|XCD|$
GT|Guatemala|GTQ|Q
GN|Guinea|GNF|FG
GW|Guinea-Bissau|XOF|CFA
HT|Haiti|HTG|G
HN|Honduras|HNL|L
HK|Hong Kong|HKD|HK$
HU|Hungary|HUF|Ft
IS|Iceland|ISK|kr
ID|Indonesia|IDR|Rp
IR|Iran|IRR|﷼
IQ|Iraq|IQD|ع.د
IE|Ireland|EUR|€
IL|Israel|ILS|₪
IT|Italy|EUR|€
JM|Jamaica|JMD|$
JP|Japan|JPY|¥
JO|Jordan|JOD|د.ا
KZ|Kazakhstan|KZT|₸
KE|Kenya|KES|KSh
KW|Kuwait|KWD|د.ك
KG|Kyrgyzstan|KGS|с
LA|Laos|LAK|₭
LV|Latvia|EUR|€
LB|Lebanon|LBP|ل.ل
LR|Liberia|LRD|$
LY|Libya|LYD|ل.د
LI|Liechtenstein|CHF|CHF
LT|Lithuania|EUR|€
LU|Luxembourg|EUR|€
MO|Macao|MOP|MOP$
MY|Malaysia|MYR|RM
MV|Maldives|MVR|Rf
ML|Mali|XOF|CFA
MT|Malta|EUR|€
MU|Mauritius|MUR|₨
MX|Mexico|MXN|$
FM|Micronesia|USD|$
MD|Moldova|MDL|L
MC|Monaco|EUR|€
MN|Mongolia|MNT|₮
MA|Morocco|MAD|د.م.
MZ|Mozambique|MZN|MT
MM|Myanmar (Burma)|MMK|K
NA|Namibia|NAD|$
NP|Nepal|NPR|₨
NL|Netherlands|EUR|€
NZ|New Zealand|NZD|$
NI|Nicaragua|NIO|C$
NE|Niger|XOF|CFA
NG|Nigeria|NGN|₦
MK|North Macedonia|MKD|ден
NO|Norway|NOK|kr
OM|Oman|OMR|ر.ع.
PK|Pakistan|PKR|₨
PA|Panama|PAB|B/.
PG|Papua New Guinea|PGK|K
PY|Paraguay|PYG|₲
PE|Peru|PEN|S/
PH|Philippines|PHP|₱
PL|Poland|PLN|zł
PT|Portugal|EUR|€
QA|Qatar|QAR|ر.ق
RO|Romania|RON|lei
RU|Russia|RUB|₽
RW|Rwanda|RWF|FRw
WS|Samoa|WST|T
SM|San Marino|EUR|€
SN|Senegal|XOF|CFA
RS|Serbia|RSD|дин
SC|Seychelles|SCR|₨
SL|Sierra Leone|SLE|Le
SK|Slovakia|EUR|€
SI|Slovenia|EUR|€
SB|Solomon Islands|SBD|$
SO|Somalia|SOS|Sh
ZA|South Africa|ZAR|R
KR|South Korea|KRW|₩
ES|Spain|EUR|€
LK|Sri Lanka|LKR|₨
KN|St. Kitts & Nevis|XCD|$
LC|St. Lucia|XCD|$
SD|Sudan|SDG|ج.س
SR|Suriname|SRD|$
SE|Sweden|SEK|kr
CH|Switzerland|CHF|CHF
TW|Taiwan|TWD|NT$
TJ|Tajikistan|TJS|SM
TZ|Tanzania|TZS|TSh
TH|Thailand|THB|฿
TG|Togo|XOF|CFA
TO|Tonga|TOP|T$
TT|Trinidad & Tobago|TTD|$
TN|Tunisia|TND|د.ت
TM|Turkmenistan|TMT|m
TC|Turks & Caicos Islands|USD|$
TR|Türkiye|TRY|₺
UG|Uganda|UGX|USh
UA|Ukraine|UAH|₴
GB|United Kingdom|GBP|£
US|United States|USD|$
UY|Uruguay|UYU|$U
UZ|Uzbekistan|UZS|so'm
VU|Vanuatu|VUV|VT
VA|Vatican City|EUR|€
VE|Venezuela|VES|Bs.
VN|Vietnam|VND|₫
YE|Yemen|YER|﷼
ZM|Zambia|ZMW|ZK
ZW|Zimbabwe|ZWG|Z$''';

List<Country>? _cache;

/// Every country the app offers, alphabetical by name.
///
/// Parsed once on first use. A malformed row would be a silent gap in
/// the picker, so countries_test.dart asserts the shape, the codes'
/// uniqueness and that India is present with its real profile.
List<Country> get allCountries {
  final cached = _cache;
  if (cached != null) return cached;
  final out = <Country>[];
  for (final line in _table.split('\n')) {
    if (line.trim().isEmpty) continue;
    final f = line.split('|');
    if (f.length != 4) continue;
    out.add(Country(f[0], f[1], f[2], f[3]));
  }
  out.sort((a, b) => a.name.compareTo(b.name));
  return _cache = out;
}

/// Look up one country, or null if the code is not in the list.
Country? countryFor(String code) {
  final up = code.toUpperCase();
  for (final c in allCountries) {
    if (c.code == up) return c;
  }
  return null;
}
