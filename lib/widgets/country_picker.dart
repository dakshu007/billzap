// lib/widgets/country_picker.dart
// Where the shop trades, which decides its tax rules.
//
// Three honest states, and the difference is visible on every row,
// because a shopkeeper about to print a tax rate on a legal document
// deserves to know how much the app actually knows:
//
//   verified      someone checked this country's rates against its tax
//                 authority — rates, the local name for the tax and
//                 for the tax ID, and any regional split
//   pre-filled    a standard rate is offered from rate_table.dart and
//                 has NOT been confirmed. The app says so here and
//                 says so again in Settings, and the rate is editable
//   you set it    no data at all, so the shopkeeper names their tax
//                 and sets its rate, and the app claims nothing
//
// The third is not a degraded mode. For a handful of jurisdictions it
// is the only truthful answer, and offering it beats inventing a VAT
// rate and letting someone file it.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:billzap/theme/app_icons.dart';
import '../tax/countries.dart';
import '../tax/profiles.dart';
import '../tax/rate_table.dart';
import '../tax/tax_profile.dart';
import '../theme/app_theme.dart';

/// How much the app knows about a country, for the row's badge.
enum _Known { verified, prefilled, unknown }

_Known _knownFor(String code) {
  final p = profileFor(code);
  if (p.countryCode != 'XX') {
    return p.confidence == TaxConfidence.verified
        ? _Known.verified
        : _Known.prefilled;
  }
  return rateRowFor(code) != null ? _Known.prefilled : _Known.unknown;
}

class CountryPickerScreen extends ConsumerStatefulWidget {
  const CountryPickerScreen({super.key, this.selected});

  /// Currently selected ISO alpha-2 code, if any.
  final String? selected;

  @override
  ConsumerState<CountryPickerScreen> createState() =>
      _CountryPickerScreenState();
}

class _CountryPickerScreenState extends ConsumerState<CountryPickerScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Matches the name, the ISO code, the currency code and the currency
  /// symbol — somebody who knows they want dirhams can type AED, and
  /// somebody who knows the flag can type AE.
  List<Country> _matching() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return allCountries;
    return allCountries.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.code.toLowerCase() == q ||
          c.currencyCode.toLowerCase().contains(q) ||
          c.currencySymbol.toLowerCase() == q;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final matching = _matching();
    final searching = _query.trim().isNotEmpty;

    // While searching, one flat list of hits — sectioning results by
    // how much we know about them buries the match the person typed.
    // Otherwise: their own country first, then the researched ones,
    // then everywhere else alphabetically.
    final rows = <Object>[];
    if (searching) {
      rows.addAll(matching);
    } else {
      // Null, not "the first country", when the stored code is one
      // the picker does not list — labelling an arbitrary country
      // "Your country" would be worse than showing no such section.
      Country? current;
      for (final c in matching) {
        if (c.code == widget.selected) {
          current = c;
          break;
        }
      }
      final researched = matching
          .where((c) =>
              _knownFor(c.code) == _Known.verified && c.code != current?.code)
          .toList();
      final rest = matching
          .where((c) =>
              c.code != current?.code &&
              !researched.any((r) => r.code == c.code))
          .toList();
      if (current != null) {
        rows..add(_Header('Your country'))..add(current);
      }
      if (researched.isNotEmpty) {
        rows..add(_Header('Rates checked'))..addAll(researched);
      }
      rows..add(_Header('All countries'))..addAll(rest);
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        title: Text('Where do you trade?',
            style: AppFont.sans(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: AppColors.t1)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                style: AppFont.sans(fontSize: 15, color: AppColors.t1),
                decoration: InputDecoration(
                  hintText: 'Country, currency or code',
                  hintStyle:
                      AppFont.sans(fontSize: 14.5, color: AppColors.t3),
                  prefixIcon:
                      Icon(Symbols.search, size: 19, color: AppColors.t3),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(Symbols.close,
                              size: 18, color: AppColors.t3),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                  filled: true,
                  fillColor: AppColors.inset,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.brand, width: 1.5),
                  ),
                ),
              ),
            ),
            if (searching)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                      matching.length == 1
                          ? '1 country'
                          : '${matching.length} countries',
                      style:
                          AppFont.sans(fontSize: 12.5, color: AppColors.t3)),
                ),
              ),
            Expanded(
              child: rows.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                            'No country matches "${_query.trim()}".\n'
                            'Try the currency code instead — AED, KES, BRL.',
                            textAlign: TextAlign.center,
                            style: AppFont.sans(
                                fontSize: 14, color: AppColors.t3)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                      itemCount: rows.length,
                      itemBuilder: (_, i) {
                        final row = rows[i];
                        if (row is _Header) {
                          return Padding(
                            padding: EdgeInsets.only(
                                left: 4, top: i == 0 ? 4 : 18, bottom: 8),
                            child: Text(row.label.toUpperCase(),
                                style: AppFont.sans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: AppColors.t3)),
                          );
                        }
                        final c = row as Country;
                        return _CountryRow(
                          country: c,
                          known: _knownFor(c.code),
                          selected: c.code == widget.selected,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop(c);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A section label in the list. A marker type rather than a widget so
/// the ListView stays lazy over 177 rows.
class _Header {
  const _Header(this.label);
  final String label;
}

class _CountryRow extends StatelessWidget {
  const _CountryRow({
    required this.country,
    required this.known,
    required this.selected,
    required this.onTap,
  });

  final Country country;
  final _Known known;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // The wording is the whole point of this screen: it is what tells
    // the shopkeeper whether to trust the rate the app is about to
    // offer them.
    final (note, tint) = switch (known) {
      _Known.verified => ('tax rules built in', AppColors.brand),
      _Known.prefilled => ('rate offered — confirm it', AppColors.orange),
      _Known.unknown => ('you set the tax rate', AppColors.t3),
    };
    final flag = countryFlag(country.code);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.brandSoft : AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? AppColors.brand : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.inset,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: flag.isEmpty
                    // No flag for this code: the two letters are still
                    // a legible answer, and better than an empty box.
                    ? Text(country.code,
                        style: AppFont.sans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.t3))
                    : Text(flag, style: const TextStyle(fontSize: 22)),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(country.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFont.sans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.t1)),
                    const Gap(2),
                    Row(children: [
                      Text(
                          '${country.currencySymbol.trim()} '
                          '${country.currencyCode}',
                          style: AppFont.sans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.t3)),
                      const Gap(6),
                      Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                              color: AppColors.t3,
                              borderRadius: BorderRadius.circular(2))),
                      const Gap(6),
                      Expanded(
                        child: Text(note,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFont.sans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: tint)),
                      ),
                    ]),
                  ],
                ),
              ),
              if (selected) ...[
                const Gap(8),
                Icon(Symbols.check_circle, color: AppColors.brand, size: 22),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

/// Open the picker and return the chosen country, or null if dismissed.
Future<Country?> pickCountry(BuildContext context, {String? selected}) {
  return Navigator.of(context).push<Country>(
    MaterialPageRoute(
      builder: (_) => CountryPickerScreen(selected: selected),
    ),
  );
}
