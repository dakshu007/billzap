// lib/tax/profiles.dart — the registered countries.
//
// READ THIS BEFORE ADDING A COUNTRY.
//
// Every rate in this file is a claim about somebody's tax law, and a
// shopkeeper will print it on a legal document. So each profile states
// where its numbers came from and whether a person has checked them.
//
//   TaxConfidence.verified      someone checked these against `source`
//   TaxConfidence.unconfirmed   pre-filled from rate_table.dart, which is
//                               now sourced from a 2026 reference citing
//                               PwC, official authorities, VATupdate and
//                               TaxAtlas — a real source, but still not a
//                               rate checked for a particular sale. The
//                               app says so and keeps the rate editable.
//   TaxConfidence.selfDeclared  the shopkeeper typed it; no claim at all
//
// Only India is verified here, and only because it is the arithmetic
// the app has already been shipping; nothing about it changed when it
// moved into this file, and tax_golden_test.dart proves that.
//
// The other three are marked unverified on purpose. I am reasonably
// confident of them, but "reasonably confident" is not a standard to
// hold tax law to, and rates move — Singapore's GST went 7% → 8% → 9%
// inside two years, and Saudi's VAT tripled from 5% to 15% overnight in
// 2020. Confirm each against the revenue authority, promote it to
// in the same commit as the evidence, and bump effectiveFrom if the
// rate has moved since.
//
// For every country with no profile here — which is most of them —
// the answer is `custom`, below. The shopkeeper sets their own rate and
// label and the app claims nothing. That is honest, works everywhere
// on day one, and is a far better position than a table of 180
// half-remembered percentages.

import 'countries.dart';
import 'rate_table.dart';
import 'tax_profile.dart';

/// Where a country has no researched profile, the shopkeeper tells the
/// app what their tax is called and what it costs. No compliance claim
/// is made or implied, which is exactly why this is the safe default.
final TaxProfile customProfile = TaxProfile(
  countryCode: 'XX',
  countryName: 'Other',
  currencyCode: 'USD',
  currencySymbol: r'$',
  taxName: 'Tax',
  taxIdLabel: 'Tax ID',
  rates: const [0, 5, 10, 15, 20],
  defaultRate: 0,
  intraComponents: const [TaxComponent('Tax', 1.0)],
  confidence: TaxConfidence.selfDeclared,
  source: 'No tax data. The shopkeeper sets the rate and the label.',
  effectiveFrom: DateTime.utc(2020, 1, 1),
);

/// India. The slabs are the ones create_invoice_screen.dart already
/// offers, including the 0.25% stone/diamond rate and the 40% rate;
/// this profile did not invent or drop any of them.
///
/// Intra-state splits one rate into CGST + SGST at half each; inter-
/// state shows the whole thing as IGST. That is the behaviour
/// Invoice.totalCgst/totalSgst/totalIgst has always had.
final TaxProfile indiaProfile = TaxProfile(
  countryCode: 'IN',
  countryName: 'India',
  currencyCode: 'INR',
  currencySymbol: '₹',
  grouping: NumberGrouping.indian,
  taxName: 'GST',
  taxIdLabel: 'GSTIN',
  itemCodeLabel: 'HSN',
  rates: const [0, 0.25, 5, 12, 18, 28, 40],
  defaultRate: 18,
  regionMatters: true,
  regionLabel: 'State',
  intraComponents: const [TaxComponent('CGST', 0.5), TaxComponent('SGST', 0.5)],
  interComponents: const [TaxComponent('IGST', 1.0)],
  confidence: TaxConfidence.verified,
  source: 'The rates and the CGST/SGST/IGST split BillZap already '
      'shipped, moved here unchanged. tax_golden_test.dart asserts the '
      'arithmetic is identical to lib/models/models.dart.',
  effectiveFrom: DateTime.utc(2025, 9, 22),
);

/// UNVERIFIED — confirm against the Federal Tax Authority before use.
final TaxProfile uaeProfile = TaxProfile(
  countryCode: 'AE',
  countryName: 'United Arab Emirates',
  currencyCode: 'AED',
  currencySymbol: 'AED ',
  taxName: 'VAT',
  taxIdLabel: 'TRN',
  rates: const [0, 5],
  defaultRate: 5,
  intraComponents: const [TaxComponent('VAT', 1.0)],
  confidence: TaxConfidence.unconfirmed,
  source: 'The 2026 global tax reference gives 5% standard VAT, '
      'sourced to PwC and VATupdate, which corroborates what this '
      'profile already held. Still not verified against the Federal '
      'Tax Authority for a particular supply — check tax.gov.ae and '
      'promote it with the evidence.',
  effectiveFrom: DateTime.utc(2018, 1, 1),
);

/// UNVERIFIED — confirm against ZATCA before use.
final TaxProfile saudiProfile = TaxProfile(
  countryCode: 'SA',
  countryName: 'Saudi Arabia',
  currencyCode: 'SAR',
  currencySymbol: 'SAR ',
  taxName: 'VAT',
  taxIdLabel: 'VAT number',
  rates: const [0, 15],
  defaultRate: 15,
  intraComponents: const [TaxComponent('VAT', 1.0)],
  confidence: TaxConfidence.unconfirmed,
  source: 'The 2026 global tax reference gives 15% standard VAT, '
      'sourced to PwC and VATupdate, corroborating this profile. '
      'Still not verified against ZATCA for a particular supply, and '
      'e-invoicing (Fatoora) has its own mandatory requirements this '
      'profile does NOT cover.',
  effectiveFrom: DateTime.utc(2020, 7, 1),
);

/// UNVERIFIED — confirm against IRAS before use.
final TaxProfile singaporeProfile = TaxProfile(
  countryCode: 'SG',
  countryName: 'Singapore',
  currencyCode: 'SGD',
  currencySymbol: r'S$',
  taxName: 'GST',
  taxIdLabel: 'GST registration number',
  rates: const [0, 9],
  defaultRate: 9,
  intraComponents: const [TaxComponent('GST', 1.0)],
  confidence: TaxConfidence.unconfirmed,
  source: 'The 2026 global tax reference gives 9% GST, sourced to '
      'PwC and VATupdate, corroborating this profile. Still not '
      'verified against IRAS for a particular supply — and this rate '
      'moved twice in two years (7% → 8% → 9%), so it is worth '
      'rechecking rather than assuming.',
  effectiveFrom: DateTime.utc(2024, 1, 1),
);

/// Every profile the app knows, including the custom fallback.
final List<TaxProfile> allProfiles = [
  indiaProfile,
  uaeProfile,
  saudiProfile,
  singaporeProfile,
  customProfile,
];

/// The profile for an ISO country code, or [customProfile] if there is
/// no researched one. Returning custom rather than null or a guess is
/// the point: an unknown country is a working app with a rate the
/// shopkeeper sets, not an error and not a fabricated percentage.
TaxProfile profileFor(String countryCode) {
  final code = countryCode.toUpperCase();
  for (final p in allProfiles) {
    if (p.countryCode == code) return p;
  }
  return customProfile;
}

/// Profiles a person has checked. The UI uses this to decide whether to
/// show the "rates not verified — confirm with your tax authority"
/// notice, so it must stay honest.
List<TaxProfile> get verifiedProfiles =>
    allProfiles.where((p) => p.verified).toList();

/// A profile built from rate_table.dart, or null if that country has no
/// row there.
///
/// Always [TaxConfidence.unconfirmed]: the table is recollection, not
/// research. The currency comes from countries.dart, which is reference
/// data and can be relied on in a way the rates cannot.
TaxProfile? tableProfileFor(String countryCode) {
  final row = rateRowFor(countryCode);
  if (row == null) return null;
  final c = countryFor(row.code);
  return TaxProfile(
    countryCode: row.code,
    countryName: c?.name ?? row.code,
    currencyCode: c?.currencyCode ?? 'USD',
    currencySymbol: c?.currencySymbol ?? r'$',
    grouping: groupingFor(row.code),
    taxName: row.taxName,
    taxIdLabel: row.taxIdLabel,
    rates: row.rates,
    defaultRate: row.defaultRate,
    intraComponents: [TaxComponent(row.taxName, 1.0)],
    confidence: TaxConfidence.unconfirmed,
    source: 'Standard rate from rate_table.dart, sourced from the 2026 '
        'global tax reference (PwC Worldwide Tax Summaries, official '
        'authorities, VATupdate, TaxAtlas). NOT confirmed for a '
        'particular sale: reduced rates, exemptions and zero-rating '
        'are not modelled. The app says so and the rate stays editable '
        'in Settings.',
    effectiveFrom: DateTime.utc(2026, 10, 7),
  );
}

/// The profile a shop actually trades under.
///
/// For a researched country this is simply that country's profile. For
/// every other country it is [customProfile] with the shopkeeper's own
/// rate, label and currency filled in — which is why an unresearched
/// country is a working app rather than a blocked one.
///
/// [customRate] is folded into the rate list so the picker offers it,
/// and 0 is always offered because an exempt line exists everywhere.
TaxProfile resolveProfile({
  required String countryCode,
  String customTaxName = 'Tax',
  double customTaxRate = 0,
  String customCurrencySymbol = r'$',
  String customCurrencyCode = 'USD',
  String? countryName,
}) {
  final base = profileFor(countryCode);
  if (base.countryCode != 'XX') return base;

  // A researched profile wins; then the rate table, unless the
  // shopkeeper has set their own rate, which always wins over a
  // recollection. Only then does the blank custom profile apply.
  if (customTaxRate == 0) {
    final table = tableProfileFor(countryCode);
    if (table != null) return table;
  }

  final rates = <double>{0, customTaxRate}.toList()..sort();
  final label = customTaxName.trim().isEmpty ? 'Tax' : customTaxName.trim();

  return TaxProfile(
    // Keep the real country code even though the rules are custom, so
    // the setting round-trips and the UI can name the country.
    countryCode: countryCode.toUpperCase(),
    countryName: countryName ?? customProfile.countryName,
    currencyCode: customCurrencyCode,
    currencySymbol: customCurrencySymbol,
    grouping: groupingFor(countryCode),
    taxName: label,
    taxIdLabel: 'Tax ID',
    rates: rates,
    defaultRate: customTaxRate,
    intraComponents: [TaxComponent(label, 1.0)],
    // selfDeclared, not unconfirmed. The difference is what the app
    // tells the shopkeeper: "unconfirmed" means BillZap pre-filled a
    // rate it has not checked, which deserves a warning. This rate is
    // the shopkeeper's own, so warning them about it would be absurd —
    // the app simply makes no claim either way.
    confidence: TaxConfidence.selfDeclared,
    source: 'Set by the shopkeeper. No tax authority was consulted and '
        'the app makes no claim that this rate is correct.',
    effectiveFrom: DateTime.utc(2020, 1, 1),
  );
}
