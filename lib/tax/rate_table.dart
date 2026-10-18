// lib/tax/rate_table.dart — standard rates, from a sourced reference.
//
// WHERE THESE NUMBERS COME FROM, AND HOW FAR TO TRUST THEM
//
// Every rate below is taken from "BillZap - Global VAT / GST / Sales
// Tax Reference 2026", a reference document prepared 7 Oct 2026 and
// supplied by the project owner. It cites PwC Worldwide Tax Summaries
// 2026 country reviews, official tax authorities, the VATupdate 2026
// change tracker and the TaxAtlas 2026 dataset, and it marks which
// source backs each row.
//
// That is a genuine step up from what this file held before, which was
// recollection. It is still NOT the same as a rate checked against the
// tax authority for a particular sale, and the document says so itself
// in as many words:
//
//   "Do not implement this table as a universal 'one country = one tax
//    rate' formula... The headline rate below is a reference starting
//    point, not a substitute for a tax-determination engine."
//
// So every row here is still TaxConfidence.unconfirmed, the app still
// shows the shopkeeper a "confirm this rate" notice, and the rate
// stays editable. What changed is the quality of the starting point,
// not the promise the app makes about it.
//
// WHAT IS DELIBERATELY NOT MODELLED
//
// Reduced-rate categories, exemptions, zero-rating, registration
// thresholds, reverse charge, place-of-supply rules beyond India's
// state split, digital-services regimes and local or state taxes. The
// rates list offers the bands a country publishes; which one applies
// to a given sale is the shopkeeper's call, as it has to be.
//
// SPECIFIC ROWS THE DOCUMENT SINGLES OUT
//
//   Brazil        2026 is a transition year (IBS/CBS alongside legacy
//                 ICMS/ISS/PIS/COFINS). No single rate, so none is
//                 offered — the shopkeeper sets it.
//   United States no national rate; sales tax is state and local. The
//                 common combined bands are offered and the default is
//                 nothing, because guessing a state would be worse.
//   Liberia       13% GST in 2026. The 15% VAT is scheduled for 1 Jan
//                 2027 and must NOT be used as the 2026 invoice rate —
//                 the document is explicit about this one.
//   Indonesia     12% statutory applied to an 11/12 base, so 11% is
//                 the effective rate for most supplies.
//   Thailand      rose from 7% to 10% effective 1 Oct 2026.
//   Ghana         20% effective: 15% VAT + 2.5% NHIL + 2.5% GETFund on
//                 the same taxable base.
//   Gibraltar     a 15% transaction tax from 1 Aug 2026, where there
//                 was historically no VAT at all.
//   Canada, China, Malaysia, Pakistan
//                 publish several rates by category or province; the
//                 bands are offered and the default is the headline.
//
// A row of a single 0 is not a gap — it is the answer. Bermuda, the
// British Virgin Islands, the Cayman Islands, Hong Kong, Macao,
// Kuwait, Qatar, Libya, Micronesia and Vatican City levy no general
// consumption tax, and Iraq has no broad standard rate. The row says
// "Tax" rather than naming the absence, because the word reaches the
// UI as "Apply {tax}" and "Apply No VAT" is nonsense.
//
// India is NOT in this table. It has a researched profile in
// profiles.dart carrying the CGST/SGST/IGST split and the GST state
// codes, and tax_golden_test.dart asserts its arithmetic is unchanged.
//
// TO PROMOTE A COUNTRY TO VERIFIED: check it against that country's
// tax authority, move it into profiles.dart with
// TaxConfidence.verified, and put the evidence in the commit message.
//
// FORMAT  code|taxName|taxIdLabel|rates(/-separated)|default
const String _rates = r'''
AE|VAT|TRN|0/5|5
AG|ABST|TIN|0/17|17
AL|VAT|NIPT|0/20|20
AM|VAT|TIN|0/20|20
AO|VAT|NIF|0/14|14
AR|VAT|CUIT|0/21|21
AT|VAT|UID|0/20|20
AU|GST|ABN|0/10|10
AW|Turnover Tax|Tax number|0/7|7
AZ|VAT|VOEN|0/18|18
BA|VAT|JIB|0/17|17
BD|VAT|BIN|0/15|15
BE|VAT|BTW-nummer|0/21|21
BF|VAT|IFU|0/18|18
BG|VAT|EIK|0/20|20
BH|VAT|VAT number|0/10|10
BJ|VAT|IFU|0/18|18
BM|Tax|Tax number|0|0
BO|VAT|NIT|0/13|13
BR|Tax|CNPJ|0|0
BS|VAT|TIN|0/10|10
BW|VAT|TIN|0/14|14
BY|VAT|UNP|0/20|20
BZ|GST|TIN|0/12.5|12.5
CA|GST/HST|BN|0/5/13/15|5
CD|VAT|NIF|0/16|16
CG|VAT|NIU|0/18.9|18.9
CH|VAT|MWST-Nr.|0/8.1|8.1
CI|VAT|CC|0/18|18
CL|VAT|RUT|0/19|19
CM|VAT|NIU|0/19.25|19.25
CN|VAT|USCC|0/6/9/13|13
CO|VAT|NIT|0/19|19
CR|VAT|Cedula juridica|0/13|13
CU|Sales Tax|NIT|0/10|10
CV|VAT|NIF|0/15|15
CY|VAT|VAT number|0/19|19
CZ|VAT|DIC|0/21|21
DE|VAT|USt-IdNr.|0/19|19
DJ|VAT|NIF|0/7|7
DK|VAT|CVR|0/25|25
DM|VAT|TIN|0/15|15
DO|ITBIS|RNC|0/18|18
DZ|VAT|NIF|0/19|19
EC|VAT|RUC|0/15|15
EE|VAT|KMKR|0/24|24
EG|VAT|Tax registration number|0/14|14
ER|Sales Tax|TIN|0/5/10/12|12
ES|VAT|NIF-IVA|0/21|21
ET|VAT|TIN|0/15|15
FI|VAT|ALV-numero|0/25.5|25.5
FJ|VAT|TIN|0/15|15
FM|Tax|Tax ID|0|0
FR|VAT|No. TVA|0/20|20
GA|VAT|NIF|0/18|18
GB|VAT|VAT number|0/20|20
GD|VAT|TIN|0/15|15
GE|VAT|Tax ID|0/18|18
GH|VAT|TIN|0/20|20
GI|Transaction Tax|Tax ID|0/15|15
GM|VAT|TIN|0/15|15
GN|VAT|NIF|0/18|18
GR|VAT|AFM|0/24|24
GT|VAT|NIT|0/12|12
GW|VAT|NIF|0/19|19
HK|Tax|BR number|0|0
HN|Sales Tax|RTN|0/15|15
HR|VAT|OIB|0/25|25
HT|Turnover Tax|NIF|0/10|10
HU|VAT|Adoszam|0/27|27
ID|VAT|NPWP|0/11/12|11
IE|VAT|VAT number|0/23|23
IL|VAT|Osek number|0/18|18
IQ|Tax|Tax number|0|0
IR|VAT|National ID|0/9|9
IS|VAT|VSK|0/24|24
IT|VAT|P. IVA|0/22|22
JM|GCT|TRN|0/15|15
JO|Sales Tax|Tax number|0/16|16
JP|Consumption Tax|Invoice number|0/10|10
KE|VAT|PIN|0/16|16
KG|VAT|INN|0/12|12
KH|VAT|VAT TIN|0/10|10
KM|Consumption Tax|NIF|0/10|10
KN|VAT|TIN|0/17|17
KR|VAT|Business number|0/10|10
KW|Tax|Tax number|0|0
KY|Tax|Tax number|0|0
KZ|VAT|BIN|0/16|16
LA|VAT|TIN|0/10|10
LB|VAT|VAT number|0/11|11
LC|VAT|TIN|0/12.5|12.5
LI|VAT|MWST-Nr.|0/8.1|8.1
LK|VAT|VAT number|0/18|18
LR|GST|TIN|0/13/15|13
LT|VAT|PVM kodas|0/21|21
LU|VAT|No. TVA|0/17|17
LV|VAT|PVN|0/21|21
LY|Tax|Tax number|0|0
MA|VAT|ICE|0/20|20
MC|VAT|No. TVA|0/20|20
MD|VAT|IDNO|0/20|20
MK|VAT|EDB|0/18|18
ML|VAT|NIF|0/18|18
MM|Commercial Tax|TIN|0/5|5
MN|VAT|Register number|0/10|10
MO|Tax|Tax number|0|0
MT|VAT|VAT number|0/18|18
MU|VAT|VAT number|0/15|15
MV|GST|TIN|0/8|8
MX|VAT|RFC|0/16|16
MY|SST|SST number|0/5/6/8/10|10
MZ|VAT|NUIT|0/16|16
NA|VAT|VAT number|0/15|15
NE|VAT|NIF|0/19|19
NG|VAT|TIN|0/7.5|7.5
NI|VAT|RUC|0/15|15
NL|VAT|Btw-nummer|0/21|21
NO|VAT|Org.nr.|0/25|25
NP|VAT|PAN|0/13|13
NZ|GST|GST number|0/15|15
OM|VAT|VATIN|0/5|5
PA|ITBMS|RUC|0/7|7
PE|IGV|RUC|0/18|18
PG|GST|TIN|0/10|10
PH|VAT|TIN|0/12|12
PK|GST|NTN|0/15/16/18|18
PL|VAT|NIP|0/23|23
PT|VAT|NIF|0/23|23
PY|VAT|RUC|0/10|10
QA|Tax|Tax card|0|0
RO|VAT|CUI|0/21|21
RS|VAT|PIB|0/20|20
RU|VAT|INN|0/20|20
RW|VAT|TIN|0/18|18
SA|VAT|VAT number|0/15|15
SB|Goods Tax|TIN|0/10/15|10
SC|VAT|TIN|0/15|15
SD|VAT|Tax number|0/17|17
SE|VAT|Momsnr.|0/25|25
SG|GST|GST registration number|0/9|9
SI|VAT|ID za DDV|0/22|22
SK|VAT|DIC|0/23|23
SL|GST|TIN|0/15|15
SM|Import Tax|COE|0/17|17
SN|VAT|NINEA|0/18|18
SO|Sales Tax|Tax number|0/5|5
SR|VAT|FIN|0/10|10
SV|VAT|NIT|0/13|13
TC|Tax|Tax ID|0/12|0
TD|VAT|NIF|0/18|18
TG|VAT|NIF|0/18|18
TH|VAT|Tax ID|0/10|10
TJ|VAT|TIN|0/14|14
TM|VAT|Tax number|0/15|15
TN|VAT|Matricule fiscal|0/19|19
TO|VAT|TIN|0/15|15
TR|VAT|Vergi No|0/20|20
TT|VAT|BIR number|0/12.5|12.5
TW|VAT|Tax ID|0/5|5
TZ|VAT|TIN|0/18|18
UA|VAT|Tax number|0/20|20
UG|VAT|TIN|0/18|18
US|Sales Tax|EIN|0/4/5/6/6.25/7/7.25/8/8.25/9/9.5/10|0
UY|VAT|RUT|0/22|22
UZ|VAT|INN|0/12|12
VA|Tax|Tax number|0|0
VE|VAT|RIF|0/16|16
VG|Tax|Tax number|0|0
VN|VAT|MST|0/10|10
VU|VAT|VAT number|0/15|15
WS|GST|TIN|0/15|15
YE|Sales Tax|Tax number|0/5/10|5
ZA|VAT|VAT number|0/15|15
ZM|VAT|TPIN|0/16|16
ZW|VAT|BP number|0/15.5|15.5
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
