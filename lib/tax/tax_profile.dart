// lib/tax/tax_profile.dart — what one country's sales tax looks like.
//
// BillZap started as an Indian GST app, and India was baked into the
// domain model: GstType.cgstSgst, gstin, stateCode, hsnCode, a default
// of Tamil Nadu. Going global means that knowledge has to move out of
// the model and into data, so that adding a country is a new profile
// rather than a new branch in every screen.
//
// WHAT IS DELIBERATELY NOT HERE
//
// There is no table of 180 countries' rates in this repository, and
// there should not be one until somebody has checked each entry. A
// wrong VAT rate is not a cosmetic bug: the shopkeeper issues a legally
// invalid invoice and under-collects tax they remain liable for. Rates
// also move — they are not a constant you write once.
//
// So every profile carries its own provenance: `verified` says whether
// a human checked it, `source` says against what, and `effectiveFrom`
// says as of when. Unverified profiles exist, but the app can tell the
// difference and say so. The honest default for a country nobody has
// researched is TaxProfile.custom, where the shopkeeper sets the rate
// and the app claims nothing.

import 'package:flutter/foundation.dart';

/// How a tax amount is broken into the named lines a bill has to show.
///
/// India splits one GST rate into CGST + SGST for a supply inside the
/// seller's own state, and shows it as a single IGST line across state
/// lines. Most countries have one line and one label. The split is a
/// presentation rule over the same total, so each component carries the
/// fraction of the tax it represents rather than its own rate.
@immutable
class TaxComponent {
  const TaxComponent(this.label, this.share);

  /// What the bill calls it: 'CGST', 'SGST', 'IGST', 'VAT', 'GST'.
  final String label;

  /// Fraction of the total tax on the line. The components of one
  /// supply must sum to 1.
  final double share;

  @override
  bool operator ==(Object other) =>
      other is TaxComponent && other.label == label && other.share == share;

  @override
  int get hashCode => Object.hash(label, share);

  @override
  String toString() => '$label(${(share * 100).toStringAsFixed(0)}%)';
}

/// Whether a supply stays inside the seller's own tax region.
///
/// Only meaningful where [TaxProfile.regionMatters]; elsewhere every
/// supply is [intra] and the distinction never reaches the UI.
enum SupplyScope { intra, inter }

/// How a currency groups digits.
///
/// India groups the last three then in twos — 12,34,567 — and a shop
/// owner reads 1,234,567 as wrong. Everywhere else groups in threes.
enum NumberGrouping { western, indian }

@immutable
class TaxProfile {
  const TaxProfile({
    required this.countryCode,
    required this.countryName,
    required this.currencyCode,
    required this.currencySymbol,
    required this.taxName,
    required this.taxIdLabel,
    required this.rates,
    required this.defaultRate,
    required this.intraComponents,
    required this.verified,
    required this.source,
    required this.effectiveFrom,
    this.interComponents = const [],
    this.regionMatters = false,
    this.regionLabel = '',
    this.itemCodeLabel,
    this.grouping = NumberGrouping.western,
  });

  /// ISO 3166-1 alpha-2, or 'XX' for the custom profile.
  final String countryCode;
  final String countryName;

  /// ISO 4217.
  final String currencyCode;
  final String currencySymbol;
  final NumberGrouping grouping;

  /// What this country calls the tax: 'GST', 'VAT', 'Sales Tax'.
  final String taxName;

  /// What it calls the seller's registration number: 'GSTIN', 'TRN',
  /// 'VAT number'. Shown as the field label, so it has to be the local
  /// term or the shopkeeper will not recognise it.
  final String taxIdLabel;

  /// 'HSN' in India, 'HS' where customs codes are used, null where no
  /// per-item code belongs on the bill.
  final String? itemCodeLabel;

  /// The rates a shopkeeper can pick from, as percentages.
  final List<double> rates;
  final double defaultRate;

  /// Components for a supply inside the seller's region, and across it.
  /// [interComponents] is ignored unless [regionMatters].
  final List<TaxComponent> intraComponents;
  final List<TaxComponent> interComponents;

  /// Whether this country taxes differently inside and outside the
  /// seller's own region. True for India; false for a flat national VAT.
  final bool regionMatters;

  /// 'State', 'Province', 'Emirate' — the label for the place-of-supply
  /// field. Empty when [regionMatters] is false.
  final String regionLabel;

  /// Whether a person has checked these numbers against the source
  /// below. False means the app must not present them as authoritative.
  final bool verified;

  /// Where the rates came from, so the next person can re-check them.
  final String source;

  /// The date these rates took effect. A rate change is a new profile
  /// with a later date, not an edit to this one.
  final DateTime effectiveFrom;

  /// Components to apply for [scope].
  List<TaxComponent> componentsFor(SupplyScope scope) =>
      (regionMatters && scope == SupplyScope.inter)
          ? interComponents
          : intraComponents;

  /// Whether the components of both scopes each sum to 1, within a
  /// tolerance for binary floating point. A profile that fails this
  /// would silently lose or invent tax, so the tests assert it for
  /// every registered profile.
  bool get componentsAreWellFormed {
    bool ok(List<TaxComponent> cs) {
      if (cs.isEmpty) return false;
      final sum = cs.fold<double>(0, (s, c) => s + c.share);
      return (sum - 1.0).abs() < 1e-9;
    }

    if (!ok(intraComponents)) return false;
    if (regionMatters && !ok(interComponents)) return false;
    return true;
  }

  @override
  String toString() => 'TaxProfile($countryCode, $taxName, '
      '${verified ? "verified" : "UNVERIFIED"})';
}
