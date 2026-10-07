// lib/screens/invoice/voice_invoice_screen.dart
// Voice-driven invoice entry. Tap mic, speak, see extracted items, confirm.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:billzap/theme/app_icons.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../design/money.dart';
import '../../tax/active_profile.dart';
import '../../theme/app_theme.dart';
import '../../design/components.dart';
import '../../i18n/translations.dart';
import '../../utils/voice_parser.dart';

class VoiceInvoiceScreen extends ConsumerStatefulWidget {
  const VoiceInvoiceScreen({super.key});
  @override
  ConsumerState<VoiceInvoiceScreen> createState() => _VoiceInvoiceState();
}

// ── Speech locale selection ───────────────────────────────────
// The app language's own speech pack. Every one of the twelve is an
// Indian locale because every one of the twelve is an Indian language;
// that is not the India assumption this file used to have.
const Map<String, String> _langToLocale = {
  'en': 'en_IN',
  'hi': 'hi_IN',
  'ta': 'ta_IN',
  'te': 'te_IN',
  'kn': 'kn_IN',
  'ml': 'ml_IN',
  'mr': 'mr_IN',
  'gu': 'gu_IN',
  'bn': 'bn_IN',
  'pa': 'pa_IN',
  'or': 'or_IN',
  'ur': 'ur_IN',
};

/// Speech locales to try, best first.
///
/// The old chain was language -> an `_IN` locale -> `en_IN`, which is
/// right in India and wrong everywhere else: an English-speaking
/// shopkeeper in Nairobi was dictating into a recogniser tuned for
/// Indian English phonetics and Indian number words, which produces a
/// worse transcript than en_KE for no reason at all.
///
/// So the shop's country comes first. `en` + `KE` tries en_KE ahead of
/// everything; only if the device has no such pack does it walk down
/// the chain. India's behaviour is unchanged, and not as a special
/// case — for a shop in India the country-specific candidate simply IS
/// the `_IN` one.
///
/// Public because it is the part that can be wrong, and it has been
/// wrong twice. See test/voice_locale_test.dart.
List<String> voiceLocaleCandidates(String lang, String country) {
  final c = country.toUpperCase();
  // Speech packs are named by bare language: 'zh_CN', not 'zh-Hans_CN'.
  final base = lang.split('-').first;
  final home = appLocaleFor(lang)?.defaultRegion;
  return <String>[
    // The language as spoken in this country. Hindi in Fiji, Tamil in
    // Singapore, Arabic in the UAE — all real cases.
    '${base}_$c',
    // The language's own home pack, which is the one that exists.
    _langToLocale[lang] ?? (home != null ? '${base}_$home' : ''),
    // English where the shop is, then the big English packs almost
    // every device carries.
    'en_$c',
    'en_US',
    'en_GB',
    'en_IN',
  ].where((l) => l.isNotEmpty).toSet().toList();
}

class _VoiceInvoiceState extends ConsumerState<VoiceInvoiceScreen>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _listening = false;
  String _transcript = '';
  String? _speechError;
  ParsedInvoice? _parsed;
  late final AnimationController _pulseCtrl;
  String _selectedLocaleId = 'en_IN';



  static const Map<String, String> _localeDisplay = {
    'en_IN': 'English',
    'hi_IN': 'हिन्दी (Hindi)',
    'ta_IN': 'தமிழ் (Tamil)',
    'te_IN': 'తెలుగు (Telugu)',
    'kn_IN': 'ಕನ್ನಡ (Kannada)',
    'ml_IN': 'മലയാളം (Malayalam)',
    'mr_IN': 'मराठी (Marathi)',
    'gu_IN': 'ગુજરાતી (Gujarati)',
    'bn_IN': 'বাংলা (Bengali)',
    'pa_IN': 'ਪੰਜਾਬੀ (Punjabi)',
    'or_IN': 'ଓଡ଼ିଆ (Odia)',
    'ur_IN': 'اردو (Urdu)',
  };

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (e) {
          if (mounted) {
            setState(() {
              _listening = false;
              _speechError = e.errorMsg;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(trGlobal('voice.speech_error', {'e': e.errorMsg})),
                backgroundColor: AppColors.red));
          }
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() => _listening = false);
              // Auto-process the transcript when speech ends naturally
              if (_transcript.trim().isNotEmpty && _parsed == null) {
                _processTranscript();
              }
            }
          }
        },
      );

      // Pick the speech locale from the app's current language.
      //
      // This used to read trGlobal('__lang_code'), which is not a
      // translation key. trGlobal hands back the key when it misses, so
      // appLang was always the literal '__lang_code', _langToLocale
      // never matched it, and every user got en_IN no matter which of
      // the twelve languages they had chosen. _langToLocale was
      // correct the whole time; nothing could reach it.
      final appLang = currentLangCode;
      final available = await _speech.locales();
      final ids = available.map((l) => l.localeId).toSet();
      for (final candidate
          in voiceLocaleCandidates(appLang, activeProfile.countryCode)) {
        if (ids.contains(candidate)) {
          _selectedLocaleId = candidate;
          break;
        }
      }
      // Nothing matched at all — take whatever the device has rather
      // than listen in a locale it does not support.
      if (!ids.contains(_selectedLocaleId) && available.isNotEmpty) {
        _selectedLocaleId = available.first.localeId;
      }

      if (mounted) setState(() {});
    } catch (e) {
      _speechAvailable = false;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    if (_listening) _speech.stop();
    super.dispose();
  }

  void _toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(trGlobal('voice.not_available')),
        backgroundColor: AppColors.red));
      return;
    }

    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      _processTranscript();
    } else {
      HapticFeedback.mediumImpact();
      setState(() {
        _transcript = '';
        _parsed = null;
        _listening = true;
        _speechError = null;
      });
      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _transcript = result.recognizedWords;
            });
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: _selectedLocaleId,
        cancelOnError: true,
      );
    }
  }

  void _processTranscript() {
    if (_transcript.trim().isEmpty) return;
    final result = VoiceParser.parse(_transcript);
    setState(() => _parsed = result);
  }

  void _retry() {
    setState(() {
      _transcript = '';
      _parsed = null;
    });
  }

  void _proceedToCreate() {
    if (_parsed == null || _parsed!.items.isEmpty) return;
    HapticFeedback.lightImpact();
    // Pass parsed data to /create via go_router extra
    GoRouter.of(context).push('/create', extra: _parsed);
  }

  void _pickLocale() async {
    final available = await _speech.locales();
    final supportedIds = available.map((l) => l.localeId).toSet();

    // The list used to be the twelve Indian locales and nothing else,
    // so a shopkeeper in Nairobi whose phone has en_KE installed could
    // not choose it: the only English on offer was en_IN. The device's
    // own installed locales are now listed too, named by the plugin.
    //
    // Order: the twelve first, because that is what most users want
    // and the labels are in their own script; then everything else the
    // phone actually has, alphabetically.
    final extra = available
        .where((l) => !_localeDisplay.containsKey(l.localeId))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final entries = <({String id, String label})>[
      for (final e in _localeDisplay.entries) (id: e.key, label: e.value),
      for (final l in extra) (id: l.localeId, label: l.name),
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        // AppColors.card, not Colors.white. The labels in this sheet
        // are AppColors.t1, which is near-white in dark mode, so a
        // hardcoded white sheet rendered every enabled language
        // invisible — only the greyed-out "not installed" rows showed.
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99)))),
            const Gap(16),
            Text(trGlobal('voice.choose_lang'),
              style: AppFont.sans(
                fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.t1)),
            const Gap(12),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.55),
              child: SingleChildScrollView(
                child: Column(children: entries.map((entry) {
                  final installed = supportedIds.contains(entry.id);
                  final isSelected = _selectedLocaleId == entry.id;
                  return ListTile(
                    title: Text(entry.label,
                      style: AppFont.sans(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: installed ? AppColors.t1 : AppColors.t4)),
                    subtitle: !installed
                      ? Text(trGlobal('voice.not_installed'),
                          style: AppFont.sans(fontSize: 11, color: AppColors.t4))
                      : null,
                    trailing: isSelected
                      ? Icon(Symbols.check, color: AppColors.brand)
                      : null,
                    enabled: installed,
                    onTap: installed ? () {
                      setState(() => _selectedLocaleId = entry.id);
                      Navigator.pop(ctx);
                    } : null,
                  );
                }).toList()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: AppColors.bg, borderRadius: BorderRadius.circular(14)),
            child: Icon(Symbols.close, size: 19, color: AppColors.t1)),
          onPressed: () => context.go('/home')),
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(
            child: Text(trGlobal('voice.title'),
              overflow: TextOverflow.ellipsis,
              style: AppFont.sans(
                fontSize: 21, fontWeight: FontWeight.w700,
              letterSpacing: -0.5, color: AppColors.t1)),
          ),
          const SizedBox(width: 8),
          BetaBadge(trGlobal('common.beta')),
        ]),
        actions: [
          TextButton.icon(
            onPressed: _pickLocale,
            icon: Icon(Symbols.language, size: 18, color: AppColors.brand),
            label: Text(
              // Unknown locale: show its language code rather than a
              // hardcoded 'EN' that may well be a lie.
              _localeDisplay[_selectedLocaleId]?.split(' ').first ??
                  _selectedLocaleId.split('_').first.toUpperCase(),
              style: AppFont.sans(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brand)),
          ),
        ],
      ),
      body: Column(children: [
        // Top hint card — gradient endpoint follows the theme so the
        // 'Try: "For Ravi..."' tip is readable in dark mode.
        Container(
          margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.brand.withOpacity(
              AppColors.isDark ? 0.4 : 0.2)),
          ),
          child: Row(children: [
            Icon(Symbols.tips_and_updates, color: AppColors.brand, size: 22),
            const Gap(10),
            Expanded(child: Text(
              // The example stays in English: it shows the phrasing the
              // parser understands, and a translated sentence would
              // promise support for words it does not know. Rupees only
              // where rupees are the currency.
              '${trGlobal('voice.try')} ${activeProfile.countryCode == 'IN'
                  ? '"For Ravi 2 kg sugar 50 rupees and 1 kg salt 20 rupees"'
                  : '"For Ravi 2 kg sugar 50 and 1 kg salt 20"'}',
              style: AppFont.sans(
                fontSize: 12.5, color: AppColors.t2, height: 1.4))),
          ]),
        ),

        // Inline error card (visible until user retries)
        if (_speechError != null && !_listening)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.redSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.red.withOpacity(0.3)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Symbols.error, size: 20, color: AppColors.red),
                const Gap(10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(trGlobal('voice.no_audio'),
                      style: AppFont.sans(
                        fontSize: 13.5, fontWeight: FontWeight.w600,
                        color: AppColors.t1)),
                    const Gap(2),
                    Text(_speechError!,
                      style: AppFont.sans(
                        fontSize: 11.5, color: AppColors.t3)),
                ])),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _speechError = null);
                    _toggleListening();
                  },
                  icon: const Icon(Symbols.refresh, size: 16),
                  label: Text(trGlobal('voice.retry'),
                    style: AppFont.sans(
                      fontSize: 12, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ]),
            ),
          ),

        // Main content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            children: [
              // Mic button area
              Container(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Column(children: [
                  // Animated pulsing mic
                  GestureDetector(
                    onTap: _toggleListening,
                    child: AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) {
                        final pulseSize = _listening
                          ? 1.0 + (_pulseCtrl.value * 0.15)
                          : 1.0;
                        return Stack(alignment: Alignment.center, children: [
                          // Outer glow ring (only when listening)
                          if (_listening)
                            Container(
                              width: 120 * pulseSize, height: 120 * pulseSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.red.withOpacity(0.15 * (2 - pulseSize)),
                              ),
                            ),
                          // Inner button
                          Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _listening
                                ? AppColors.red
                                : AppColors.brand,
                              boxShadow: AppShadow.float,
                            ),
                            child: Icon(
                              _listening ? Symbols.stop : Symbols.mic,
                              color: _listening
                                ? Colors.white
                                : AppColors.onBrand,
                              size: 42,
                            ),
                          ),
                        ]);
                      },
                    ),
                  ),
                  const Gap(16),
                  Text(
                    _listening
                      ? trGlobal('voice.listening')
                      : (_transcript.isEmpty ? trGlobal('voice.tap_speak') : trGlobal('voice.tap_again')),
                    style: AppFont.sans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _listening ? AppColors.red : AppColors.t2),
                  ),
                ]),
              ),

              // Live transcription
              if (_transcript.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Symbols.hearing, size: 16, color: AppColors.t3),
                      const Gap(6),
                      Text(trGlobal('voice.heard'),
                        style: AppFont.sans(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppColors.t3, letterSpacing: 0.5)),
                    ]),
                    const Gap(8),
                    Text(_transcript,
                      style: AppFont.sans(
                        fontSize: 14.5, color: AppColors.t1, height: 1.5,
                        fontStyle: FontStyle.italic)),
                  ]),
                ),
                const Gap(12),
              ],

              // Parsed items preview
              if (_parsed != null && !_listening) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.greenSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.green.withOpacity(0.3)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Symbols.auto_awesome, size: 18, color: AppColors.green),
                      const Gap(8),
                      Text(trGlobal('voice.extracted'),
                        style: AppFont.sans(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: AppColors.green, letterSpacing: 0.5)),
                    ]),
                    const Gap(10),
                    if (_parsed!.customerName != null) ...[
                      _kvRow(Symbols.person, trGlobal('inv.customer'), _parsed!.customerName!),
                      const Gap(8),
                    ],
                    if (_parsed!.items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(trGlobal('voice.no_items'),
                          style: AppFont.sans(
                            fontSize: 12.5, color: AppColors.t3, fontStyle: FontStyle.italic)),
                      )
                    else ...[
                      Text(trGlobal('voice.items'),
                        style: AppFont.sans(
                          fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.t3, letterSpacing: 0.5)),
                      const Gap(6),
                      ..._parsed!.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          // Same bug as the sheet above: a white card
                          // under near-white text hid every parsed
                          // item name and quantity in dark mode.
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.brandSoft, borderRadius: BorderRadius.circular(7)),
                              child: Icon(Symbols.shopping_basket,
                                size: 16, color: AppColors.brand)),
                            const Gap(10),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(item.name,
                                style: AppFont.sans(
                                  fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.t1)),
                              Text('${item.qty.toStringAsFixed(item.qty.truncateToDouble() == item.qty ? 0 : 1)} ${item.unit}',
                                style: AppFont.sans(
                                  fontSize: 11, color: AppColors.t3)),
                            ])),
                            Text(formatActiveMoney(item.price, decimals: 0),
                              style: AppFont.sans(
                                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.brand)),
                          ]),
                        ),
                      )),
                    ],
                  ]),
                ),
                const Gap(14),

                // Action buttons
                Row(children: [
                  Expanded(child: OutlinedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Symbols.refresh, size: 18),
                    label: Text(trGlobal('voice.try_again'),
                      style: AppFont.sans(fontWeight: FontWeight.w700, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.t2,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  )),
                  const Gap(10),
                  Expanded(flex: 2, child: ElevatedButton.icon(
                    onPressed: _parsed!.items.isEmpty ? null : _proceedToCreate,
                    icon: const Icon(Symbols.arrow_forward, size: 18),
                    label: Text(trGlobal('common.continue'),
                      style: AppFont.sans(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      foregroundColor: AppColors.onBrand,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  )),
                ]),
              ],

              // Tips block
              if (_transcript.isEmpty && !_listening) ...[
                const Gap(20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(trGlobal('voice.tips'),
                      style: AppFont.sans(
                        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.t1)),
                    const Gap(10),
                    _tip(trGlobal('voice.tip1')),
                    _tip(trGlobal('voice.tip2')),
                    _tip(trGlobal('voice.tip3')),
                    _tip(trGlobal('voice.tip4')),
                    _tip(trGlobal('voice.tip5')),
                  ]),
                ),
              ],
            ],
          ),
        ),
      ]),
    );
  }

  Widget _tip(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: EdgeInsets.only(top: 5),
        child: Icon(Symbols.fiber_manual_record, size: 6, color: AppColors.t3)),
      const Gap(8),
      Expanded(child: Text(text,
        style: AppFont.sans(fontSize: 12.5, color: AppColors.t2, height: 1.4))),
    ]));

  Widget _kvRow(IconData icon, String label, String value) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.card, borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Icon(icon, size: 16, color: AppColors.t3),
      const Gap(8),
      Text('$label:', style: AppFont.sans(
        fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.t3)),
      const Gap(8),
      Text(value, style: AppFont.sans(
        fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.t1)),
    ]));
}
