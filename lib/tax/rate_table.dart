// lib/tax/rate_table.dart — standard rates for the main VAT/GST economies.
//
// READ THIS BEFORE TRUSTING ANY NUMBER IN HERE.
//
// Nothing in this file is verified. Every rate is my best recollection of
// a country's standard rate, which is not a standard anybody should hold
// tax law to. Rates move, and they move fast: Singapore went 7 to 8 to 9
// per cent inside two years, and Saudi Arabia tripled 5 to 15 overnight
// in 2020. I could not check any of these — every tax authority and rate
// API is blocked from the environment this was written in.
//
// So the app treats them as a STARTING POINT, not an answer. A country
// sourced from this table shows the shopkeeper a "confirm this rate"
// notice, and the rate stays editable. That is the difference between
// saving somebody a minute of typing and telling them a number they will
// print on a legal document.
//
// Reduced rates, zero-rated categories, registration thresholds, reverse
// charge, place-of-supply rules and e-invoicing mandates are all OUT OF
// SCOPE here. This is one standard rate per country. A shop that needs
// more than that needs a researched profile, which is profiles.dart.
//
// To promote a country: check it against the authority named below, move
// it into profiles.dart with verified: true, and put the evidence in the
// commit message.
//
// A row with a single 0 rate is not a gap in the table — it is the
// answer. Hong Kong, Macau, Qatar, Kuwait, Libya and Bermuda levy no
// consumption tax, so the app offers nothing but zero and the tax rows
// never print. It says "Tax" rather than "No VAT" because the word
// appears in the UI as "Apply {tax}", and "Apply No VAT" is nonsense.
//
// The USA is the other shape of the same problem: sales tax is real but
// set per state and often per city, so a single national figure would
// be a fiction. Its row offers the common combined bands so a
// shopkeeper can pick theirs, and defaults to 0 because we do not know
// which state they are in and must not guess.
//
// FORMAT  code|taxName|taxIdLabel|rates(/-separated)|default
const String _rates = r'''
GB|VAT|VAT number|0/5/20|20
IE|VAT|VAT number|0/9/13.5/23|23
DE|VAT|USt-IdNr.|0/7/19|19
FR|VAT|No. TVA|0/5.5/10/20|20
IT|VAT|P. IVA|0/4/10/22|22
ES|VAT|NIF-IVA|0/4/10/21|21
NL|VAT|Btw-nummer|0/9/21|21
BE|VAT|BTW-nummer|0/6/12/21|21
PT|VAT|NIF|0/6/13/23|23
AT|VAT|UID|0/10/13/20|20
PL|VAT|NIP|0/5/8/23|23
SE|VAT|Momsnr.|0/6/12/25|25
NO|VAT|Org.nr.|0/12/15/25|25
DK|VAT|CVR|0/25|25
FI|VAT|ALV-numero|0/10/14/25.5|25.5
CH|VAT|MWST-Nr.|0/2.6/3.8/8.1|8.1
GR|VAT|AFM|0/6/13/24|24
CZ|VAT|DIC|0/12/21|21
RO|VAT|CUI|0/5/9/19|19
HU|VAT|Adoszam|0/5/18/27|27
TR|VAT|Vergi No|0/1/10/20|20
AU|GST|ABN|0/10|10
NZ|GST|GST number|0/15|15
ZA|VAT|VAT number|0/15|15
NG|VAT|TIN|0/7.5|7.5
KE|VAT|PIN|0/8/16|16
EG|VAT|Tax ID|0/14|14
MA|VAT|ICE|0/10/20|20
JP|Consumption tax|Invoice number|0/8/10|10
KR|VAT|Business number|0/10|10
CN|VAT|USCC|0/6/9/13|13
TW|Business tax|Tax ID|0/5|5
TH|VAT|Tax ID|0/7|7
VN|VAT|MST|0/5/10|10
PH|VAT|TIN|0/12|12
ID|VAT|NPWP|0/11|11
MY|SST|SST number|0/6/10|6
PK|GST|NTN|0/18|18
BD|VAT|BIN|0/15|15
LK|VAT|VAT number|0/18|18
NP|VAT|PAN|0/13|13
BH|VAT|VAT number|0/10|10
OM|VAT|VATIN|0/5|5
QA|Tax|Tax card|0|0
KW|Tax|Tax number|0|0
MX|IVA|RFC|0/8/16|16
AR|IVA|CUIT|0/10.5/21|21
CL|IVA|RUT|0/19|19
CO|IVA|NIT|0/5/19|19
PE|IGV|RUC|0/18|18
RU|VAT|INN|0/10/20|20
UA|VAT|Tax number|0/7/14/20|20
IL|VAT|Osek number|0/18|18
BR|Tax|CNPJ|0/7/12/18|18
UY|IVA|RUT|0/10/22|22
PY|IVA|RUC|0/5/10|10
BO|IVA|NIT|0/13|13
EC|IVA|RUC|0/5/15|15
VE|IVA|RIF|0/8/16|16
CR|IVA|Cedula juridica|0/1/2/4/13|13
PA|ITBMS|RUC|0/7/10/15|7
GT|IVA|NIT|0/12|12
HN|ISV|RTN|0/15/18|15
SV|IVA|NIT|0/13|13
NI|IVA|RUC|0/15|15
DO|ITBIS|RNC|0/16/18|18
JM|GCT|TRN|0/15|15
TT|VAT|BIR number|0/12.5|12.5
BS|VAT|TIN|0/10|10
US|Sales Tax|EIN|0/4/5/6/6.25/7/7.25/8/8.25/9/9.5/10|0
CA|GST/HST|BN|0/5/13/15|5
BM|Tax|Tax number|0|0
BZ|GST|TIN|0/12.5|12.5
SR|VAT|FIN|0/10|10
HT|TCA|NIF|0/10|10
CU|Tax|NIT|0/10|10
IS|VAT|VSK|0/11/24|24
EE|VAT|KMKR|0/9/22|22
LV|VAT|PVN|0/5/12/21|21
LT|VAT|PVM kodas|0/5/9/21|21
SK|VAT|DIC|0/5/19/23|23
SI|VAT|ID za DDV|0/5/9.5/22|22
HR|VAT|OIB|0/5/13/25|25
BG|VAT|EIK|0/9/20|20
RS|VAT|PIB|0/10/20|20
BA|VAT|JIB|0/17|17
MK|VAT|EDB|0/5/10/18|18
AL|VAT|NIPT|0/6/20|20
MD|VAT|IDNO|0/8/20|20
BY|VAT|UNP|0/10/20|20
LU|VAT|No. TVA|0/3/8/17|17
MT|VAT|VAT number|0/5/7/18|18
CY|VAT|VAT number|0/5/9/19|19
MC|VAT|No. TVA|0/5.5/10/20|20
LI|VAT|MWST-Nr.|0/2.6/3.8/8.1|8.1
SM|VAT|COE|0/17|17
GE|VAT|Tax ID|0/18|18
AM|VAT|TIN|0/20|20
AZ|VAT|VOEN|0/18|18
KZ|VAT|BIN|0/12|12
UZ|VAT|INN|0/12|12
KG|VAT|INN|0/12|12
TJ|VAT|TIN|0/15|15
TM|VAT|Tax number|0/15|15
MN|VAT|Register number|0/10|10
IR|VAT|National ID|0/10|10
IQ|Sales Tax|Tax number|0/15|15
JO|GST|Tax number|0/4/10/16|16
LB|VAT|VAT number|0/11|11
YE|Sales Tax|Tax number|0/5|5
DZ|VAT|NIF|0/9/19|19
TN|VAT|Matricule fiscal|0/7/13/19|19
LY|Tax|Tax number|0|0
SD|VAT|Tax number|0/17|17
ET|VAT|TIN|0/15|15
GH|VAT|TIN|0/3/15|15
CI|VAT|CC|0/9/18|18
SN|VAT|NINEA|0/18|18
CM|VAT|NIU|0/19.25|19.25
TZ|VAT|TIN|0/18|18
UG|VAT|TIN|0/18|18
RW|VAT|TIN|0/18|18
ZM|VAT|TPIN|0/16|16
ZW|VAT|BP number|0/15|15
BW|VAT|TIN|0/14|14
NA|VAT|VAT number|0/15|15
MZ|VAT|NUIT|0/16|16
AO|VAT|NIF|0/7/14|14
MU|VAT|VAT number|0/15|15
BF|VAT|IFU|0/18|18
ML|VAT|NIF|0/18|18
NE|VAT|NIF|0/19|19
TD|VAT|NIF|0/18|18
BJ|VAT|IFU|0/18|18
TG|VAT|NIF|0/18|18
GN|VAT|NIF|0/18|18
GA|VAT|NIF|0/18|18
CG|VAT|NIU|0/18|18
CD|VAT|NIF|0/16|16
LR|GST|TIN|0/10|10
SL|GST|TIN|0/15|15
GM|VAT|TIN|0/15|15
CV|VAT|NIF|0/15|15
SC|VAT|TIN|0/15|15
SO|Sales Tax|Tax number|0/5|5
DJ|VAT|NIF|0/10|10
ER|Sales Tax|TIN|0/5|5
KH|VAT|VAT TIN|0/10|10
LA|VAT|TIN|0/7|7
MM|Commercial Tax|TIN|0/5|5
MV|GST|TIN|0/8/16|8
MO|Tax|Tax number|0|0
HK|Tax|BR number|0|0
PG|GST|TIN|0/10|10
FJ|VAT|TIN|0/15|15
VU|VAT|VAT number|0/15|15
WS|VAGST|TIN|0/15|15
TO|CT|TIN|0/15|15
SB|GST|TIN|0/10|10
''';

/// One row of the table above.
class RateRow {
  const RateRow(this.code, this.taxName, this.taxIdLabel, this.rates,
      this.defaultRate);

  final String code;

  /// What the country calls it: VAT, GST, IVA, Consumption tax.
  final String taxName;

  /// The local term for the seller's registration number. Shown as the
  /// field label, so it has to be the word the shopkeeper recognises —
  /// a UK trader does not have a GSTIN and a Spanish one does not have
  /// a VAT number, they have a NIF-IVA.
  final String taxIdLabel;

  final List<double> rates;
  final double defaultRate;
}

Map<String, RateRow>? _cache;

Map<String, RateRow> get _table {
  final cached = _cache;
  if (cached != null) return cached;
  final out = <String, RateRow>{};
  for (final line in _rates.split('\n')) {
    if (line.trim().isEmpty) continue;
    final f = line.split('|');
    if (f.length != 5) continue;
    final rates = f[3]
        .split('/')
        .map(double.tryParse)
        .whereType<double>()
        .toList()
      ..sort();
    final def = double.tryParse(f[4]);
    if (rates.isEmpty || def == null) continue;
    // A default that is not one of the offered rates would leave the
    // dropdown with nothing selected, so the row is dropped rather than
    // shipped half-working. rate_table_test.dart asserts none are.
    if (!rates.contains(def)) continue;
    out[f[0]] = RateRow(f[0], f[1], f[2], rates, def);
  }
  return _cache = out;
}

/// The row for an ISO country code, or null if the table has none.
RateRow? rateRowFor(String countryCode) => _table[countryCode.toUpperCase()];

/// Every country the table covers. Used by tests and by the picker to
/// show which countries arrive with a rate already filled in.
Iterable<String> get rateTableCountries => _table.keys;
