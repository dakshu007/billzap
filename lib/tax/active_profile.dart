// lib/tax/active_profile.dart — the shop's profile, without a WidgetRef.
//
// Most of the app reads the tax profile through taxProfileProvider, and
// should keep doing so: that is the version Riverpod rebuilds on.
//
// But a handful of call sites genuinely cannot hold a ref — a static
// bottom-sheet helper, a PDF builder, a pure-Dart formatter on the hot
// path of every list row. Before this file they hardcoded "GST" and the
// rupee, which is what made the app India-only in places nobody had
// looked. They now read from here.
//
// This mirrors the shape money.dart and the i18n layer already use: a
// module-level value that one provider keeps current. The default is
// India, so an install that never reaches the provider behaves as it
// always did.

import 'profiles.dart';
import 'tax_profile.dart';

TaxProfile _active = indiaProfile;

/// Called by taxProfileProvider. Not for screens to call directly —
/// a screen that has a ref should watch the provider instead.
void setActiveProfile(TaxProfile profile) => _active = profile;

/// The profile the shop is trading under right now.
TaxProfile get activeProfile => _active;

/// What this country calls its tax: 'GST', 'VAT', 'Sales Tax'. The one
/// string that used to be hardcoded in a dozen labels.
String get activeTaxName => _active.taxName;

/// What this country calls a tax registration number: 'GSTIN', 'TRN',
/// 'VAT number'.
String get activeTaxIdLabel => _active.taxIdLabel;

/// What this country calls an item code: 'HSN' in India, and nothing at
/// all in most places — null means do not ask for one.
String? get activeItemCodeLabel => _active.itemCodeLabel;
