// lib/widgets/country_picker.dart
// Where the shop trades, which decides its tax rules.
//
// Two honest states, and the difference is visible to the shopkeeper:
//
//   researched   the country has a checked tax profile — rates, the
//                local name for the tax and for the tax ID, and any
//                regional split are all known
//   custom       no profile exists, so the shopkeeper sets the rate and
//                the label themselves and the app claims nothing
//
// The second is not a degraded mode, it is the truthful one for the
// ~169 countries nobody has researched. Showing it as such beats
// inventing a VAT rate and letting someone print it on an invoice.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../tax/countries.dart';
import '../tax/profiles.dart';
import '../theme/app_theme.dart';

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

  List<Country> get _visible {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return allCountries;
    return allCountries
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.code.toLowerCase() == q ||
            c.currencyCode.toLowerCase() == q)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _visible;
    // Countries with a checked profile float to the top of an empty
    // search, because they are the ones the app can do most for.
    final researched = allProfiles
        .where((p) => p.countryCode != 'XX')
        .map((p) => p.countryCode)
        .toSet();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Where do you trade?'),
        backgroundColor: AppColors.bg,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search country or currency',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                final c = list[i];
                final isVerified = researched.contains(c.code);
                final isSelected = c.code == widget.selected;
                return ListTile(
                  title: Text(c.name),
                  subtitle: Text(
                    isVerified
                        ? '${c.currencyCode} · tax rules built in'
                        : '${c.currencyCode} · you set the tax rate',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isVerified ? AppColors.brand : AppColors.t3,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: AppColors.brand)
                      : null,
                  onTap: () => Navigator.of(context).pop(c),
                );
              },
            ),
          ),
        ],
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
