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
QA|No VAT|Tax card|0|0
KW|No VAT|Tax number|0|0
MX|IVA|RFC|0/8/16|16
AR|IVA|CUIT|0/10.5/21|21
CL|IVA|RUT|0/19|19
CO|IVA|NIT|0/5/19|19
PE|IGV|RUC|0/18|18
RU|VAT|INN|0/10/20|20
UA|VAT|Tax number|0/7/14/20|20
IL|VAT|Osek number|0/18|18
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
