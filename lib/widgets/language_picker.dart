// lib/widgets/language_picker.dart — choose the language the app is read in.
//
// Two fields, as the owner specified:
//
//   1. Country. Narrows the list to the languages the localisation spec
//      recommends for that country (lib/i18n/locales.dart). It starts on
//      the shop's own country. It is ONLY a filter: it does not change
//      where the shop trades, its currency or its tax — that is
//      Settings → Country & tax, and the field says so.
//   2. Language, with search. Search spans every language, not just the
//      country's, so a Tamil speaker in Dubai still finds Tamil.
//
// Picking a row selects it; Apply switches the whole app to it at once.
//
// A "Beta" tag marks languages whose strings were machine-translated
// and have not been checked by a native speaker — today, every language
// but English. The tag is there because a wrong word is likely
// somewhere in those files and the shopkeeper deserves to know that
// before relying on one.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:billzap/theme/app_icons.dart';
import '../design/components.dart';
import '../i18n/locales.dart';
import '../i18n/translations.dart';
import '../providers/providers.dart';
import '../tax/countries.dart';
import '../theme/app_theme.dart';

/// Every language but English wears a Beta tag until a native speaker
/// has checked it. That includes the twelve the app launched with: the
/// worldwide build added about 470 strings to each of them, and those
/// were machine-translated like every other new language. When someone
/// fluent signs a language off, add its id here — and say who in the
/// commit.
const Set<String> kReviewedLanguages = {'en'};

bool isBetaLanguage(String id) => !kReviewedLanguages.contains(id);

/// Open the language picker.
Future<void> openLanguagePicker(BuildContext context,
    {bool isFirstLaunch = false}) {
  HapticFeedback.lightImpact();
  return Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => LanguagePickerScreen(isFirstLaunch: isFirstLaunch),
  ));
}

class LanguagePickerScreen extends ConsumerStatefulWidget {
  final bool isFirstLaunch;
  const LanguagePickerScreen({super.key, this.isFirstLaunch = false});

  @override
  ConsumerState<LanguagePickerScreen> createState() =>
      _LanguagePickerScreenState();
}

class _LanguagePickerScreenState extends ConsumerState<LanguagePickerScreen> {
  final _search = TextEditingController();
  String _query = '';
  late String _country;
  late String _selected;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    final shop = ref.read(businessProvider)?.countryCode ?? 'IN';
    _country = countryFor(shop) != null ? shop : 'IN';
    _selected = ref.read(languageProvider);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    if (_applying) return;
    setState(() => _applying = true);
    HapticFeedback.mediumImpact();
    await ref.read(languageProvider.notifier).setLanguage(_selected);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _pickCountry() async {
    HapticFeedback.lightImpact();
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CountryFilterSheet(selected: _country),
    );
    if (picked != null && mounted) setState(() => _country = picked);
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(languageProvider);
    final forCountry = localesForCountry(_country);
    final searching = _query.trim().isNotEmpty;

    final rows = <Object>[];
    if (searching) {
      final hits = searchLocales(_query);
      // The country's own languages first among the hits.
      hits.sort((a, b) {
        final ia = forCountry.indexWhere((l) => l.id == a.id);
        final ib = forCountry.indexWhere((l) => l.id == b.id);
        if (ia >= 0 && ib >= 0) return ia.compareTo(ib);
        if (ia >= 0) return -1;
        if (ib >= 0) return 1;
        return a.englishName.compareTo(b.englishName);
      });
      rows.addAll(hits);
    } else {
      rows
        ..add(_Header(trGlobal('lang.spoken_in',
            {'country': countryDisplayName(_country)})))
        ..addAll(forCountry);
      final rest = kAppLocales
          .where((l) => !forCountry.any((f) => f.id == l.id))
          .toList()
        ..sort((a, b) => a.englishName.compareTo(b.englishName));
      rows
        ..add(_Header(trGlobal('lang.all_languages')))
        ..addAll(rest);
    }

    final changed = _selected != current;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        title: Text(
          trGlobal('set.language'),
          style: AppFont.sans(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: AppColors.t1),
        ),
      ),
      body: SafeArea(
        child: Column(children: [
          // ── Country ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _FieldLabel(trGlobal('lang.country')),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: _DropdownField(
              leading: Text(countryFlag(_country),
                  style: const TextStyle(fontSize: 20)),
              label: countryDisplayName(_country),
              onTap: _pickCountry,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(trGlobal('lang.country_hint'),
                  style: AppFont.sans(fontSize: 12, color: AppColors.t3)),
            ),
          ),

          // ── Language ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _FieldLabel(trGlobal('lang.language')),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              style: AppFont.sans(fontSize: 15, color: AppColors.t1),
              decoration: InputDecoration(
                hintText: trGlobal('lang.search'),
                hintStyle: AppFont.sans(fontSize: 14.5, color: AppColors.t3),
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
          Expanded(
            child: rows.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                          trGlobal('lang.no_match', {'q': _query.trim()}),
                          textAlign: TextAlign.center,
                          style: AppFont.sans(
                              fontSize: 14, color: AppColors.t3)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                    itemCount: rows.length + 1,
                    itemBuilder: (_, i) {
                      if (i == rows.length) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BetaBadge(trGlobal('common.beta')),
                              const Gap(8),
                              Expanded(
                                child: Text(trGlobal('lang.beta_note'),
                                    style: AppFont.sans(
                                        fontSize: 12, color: AppColors.t3)),
                              ),
                            ],
                          ),
                        );
                      }
                      final row = rows[i];
                      if (row is _Header) {
                        return Padding(
                          padding: EdgeInsetsDirectional.only(
                              start: 4, top: i == 0 ? 6 : 18, bottom: 8),
                          child: Text(row.label.toUpperCase(),
                              style: AppFont.sans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: AppColors.t3)),
                        );
                      }
                      final l = row as AppLocale;
                      return _LangTile(
                        locale: l,
                        selected: l.id == _selected,
                        current: l.id == current,
                        beta: isBetaLanguage(l.id),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selected = l.id);
                        },
                      );
                    },
                  ),
          ),

          // ── Apply ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (changed || widget.isFirstLaunch) && !_applying
                    ? (changed ? _apply : () => Navigator.of(context).pop())
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: AppColors.onBrand,
                  disabledBackgroundColor: AppColors.inset,
                  disabledForegroundColor: AppColors.t3,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: _applying
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.2, color: AppColors.onBrand))
                    : Text(
                        changed
                            ? trGlobal('lang.apply_named', {
                                'lang': appLocaleFor(_selected)?.nativeName ??
                                    _selected,
                              })
                            : trGlobal('lang.apply'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFont.sans(
                            fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Header {
  const _Header(this.label);
  final String label;
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(text.toUpperCase(),
            style: AppFont.sans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.t3)),
      );
}

class _DropdownField extends StatelessWidget {
  final Widget leading;
  final String label;
  final VoidCallback onTap;
  const _DropdownField(
      {required this.leading, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.inset,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              leading,
              const Gap(12),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFont.sans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.t1)),
              ),
              Icon(Symbols.expand_more, size: 22, color: AppColors.t3),
            ]),
          ),
        ),
      );
}

class _LangTile extends StatelessWidget {
  final AppLocale locale;
  final bool selected;
  final bool current;
  final bool beta;
  final VoidCallback onTap;

  const _LangTile({
    required this.locale,
    required this.selected,
    required this.current,
    required this.beta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(
                          locale.nativeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          // The name is in its own script and direction,
                          // whatever the app is currently showing.
                          textDirection: locale.rtl
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          style: AppFont.sans(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: selected ? AppColors.brand : AppColors.t1,
                          ),
                        ),
                      ),
                      if (beta) ...[
                        const Gap(8),
                        BetaBadge(trGlobal('common.beta')),
                      ],
                    ]),
                    const Gap(2),
                    Text(
                      current
                          ? '${locale.englishName} · ${trGlobal('lang.in_use')}'
                          : locale.englishName,
                      style: AppFont.sans(fontSize: 12, color: AppColors.t3),
                    ),
                  ],
                ),
              ),
              const Gap(8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: selected ? 24 : 20,
                height: selected ? 24 : 20,
                decoration: BoxDecoration(
                  color: selected ? AppColors.brand : Colors.transparent,
                  border: Border.all(
                    color: selected ? AppColors.brand : AppColors.border,
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                ),
                child: selected
                    ? Icon(Symbols.check,
                        color: AppColors.onBrand, size: 16, weight: 800)
                    : null,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// A searchable list of countries that returns a code. Not the tax
/// country picker: no rate notes, because choosing here changes no tax.
class _CountryFilterSheet extends StatefulWidget {
  final String selected;
  const _CountryFilterSheet({required this.selected});

  @override
  State<_CountryFilterSheet> createState() => _CountryFilterSheetState();
}

class _CountryFilterSheetState extends State<_CountryFilterSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = foldForSearch(_query.trim());
    final list = allCountries.where((c) {
      if (q.isEmpty) return true;
      return foldForSearch(countryDisplayName(c.code)).contains(q) ||
          foldForSearch(c.name).contains(q) ||
          c.code.toLowerCase() == q;
    }).toList()
      ..sort((a, b) =>
          countryDisplayName(a.code).compareTo(countryDisplayName(b.code)));

    final h = MediaQuery.of(context).size.height;
    return Container(
      height: h * 0.85,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(children: [
        const Gap(10),
        Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: TextField(
            autofocus: false,
            onChanged: (v) => setState(() => _query = v),
            style: AppFont.sans(fontSize: 15, color: AppColors.t1),
            decoration: InputDecoration(
              hintText: trGlobal('lang.search_country'),
              hintStyle: AppFont.sans(fontSize: 14.5, color: AppColors.t3),
              prefixIcon: Icon(Symbols.search, size: 19, color: AppColors.t3),
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
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final c = list[i];
              final sel = c.code == widget.selected;
              return ListTile(
                onTap: () => Navigator.of(context).pop(c.code),
                leading: Text(countryFlag(c.code),
                    style: const TextStyle(fontSize: 22)),
                title: Text(countryDisplayName(c.code),
                    style: AppFont.sans(
                        fontSize: 15,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        color: sel ? AppColors.brand : AppColors.t1)),
                trailing: sel
                    ? Icon(Symbols.check_circle,
                        color: AppColors.brand, size: 22)
                    : null,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              );
            },
          ),
        ),
      ]),
    );
  }
}

/// Compact language button — the one in the top corner of Settings, so
/// the language is findable without knowing which tab hides it.
class LanguagePill extends ConsumerWidget {
  const LanguagePill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = currentLanguage(ref.watch(languageProvider));

    return Semantics(
      button: true,
      label: trGlobal('set.language'),
      child: GestureDetector(
        onTap: () => openLanguagePicker(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          constraints: const BoxConstraints(maxWidth: 160),
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.brand.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Symbols.translate, size: 16, color: AppColors.brand),
              const Gap(6),
              Flexible(
                child: Text(
                  lang.nativeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFont.sans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
