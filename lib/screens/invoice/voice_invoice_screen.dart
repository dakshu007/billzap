// lib/screens/invoice/voice_invoice_screen.dart
// Voice-driven invoice entry. Tap mic, speak, see extracted items, confirm.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../theme/app_theme.dart';
import '../../i18n/translations.dart';
import '../../utils/voice_parser.dart';

class VoiceInvoiceScreen extends ConsumerStatefulWidget {
  const VoiceInvoiceScreen({super.key});
  @override
  ConsumerState<VoiceInvoiceScreen> createState() => _VoiceInvoiceState();
}

class _VoiceInvoiceState extends ConsumerState<VoiceInvoiceScreen>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _listening = false;
  String _transcript = '';
  ParsedInvoice? _parsed;
  late final AnimationController _pulseCtrl;
  String _selectedLocaleId = 'en_IN';

  // Maps app language code → speech-to-text locale ID
  // Checked at runtime — fall back to en_IN if device doesn't have it
  static const Map<String, String> _langToLocale = {
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
            setState(() => _listening = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Speech error: ${e.errorMsg}'),
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

      // Pick best matching locale based on app's current language
      final appLang = trGlobal('__lang_code') ?? 'en';
      final preferredLocale = _langToLocale[appLang] ?? 'en_IN';
      
      // Verify the device has this locale, else fall back
      final available = await _speech.locales();
      final ids = available.map((l) => l.localeId).toSet();
      if (ids.contains(preferredLocale)) {
        _selectedLocaleId = preferredLocale;
      } else if (ids.contains('en_IN')) {
        _selectedLocaleId = 'en_IN';
      } else if (available.isNotEmpty) {
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
        content: Text(trGlobal('voice.not_available') ?? 'Voice not available on this device'),
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

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
            Text('Choose Language',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.t1)),
            const Gap(12),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.55),
              child: SingleChildScrollView(
                child: Column(children: _localeDisplay.entries.map((entry) {
                  final available = supportedIds.contains(entry.key);
                  final isSelected = _selectedLocaleId == entry.key;
                  return ListTile(
                    title: Text(entry.value,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                        color: available ? AppColors.t1 : AppColors.t4)),
                    subtitle: !available
                      ? Text('Not installed on this device',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.t4))
                      : null,
                    trailing: isSelected
                      ? const Icon(Symbols.check, color: AppColors.brand)
                      : null,
                    enabled: available,
                    onTap: available ? () {
                      setState(() => _selectedLocaleId = entry.key);
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
        backgroundColor: AppColors.card,
        leading: IconButton(
          icon: Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Symbols.close, size: 19, color: AppColors.t1)),
          onPressed: () => context.go('/home')),
        title: Text('Voice Invoice',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.t1)),
        actions: [
          TextButton.icon(
            onPressed: _pickLocale,
            icon: const Icon(Symbols.language, size: 18, color: AppColors.brand),
            label: Text(
              _localeDisplay[_selectedLocaleId]?.split(' ').first ?? 'EN',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brand)),
          ),
        ],
      ),
      body: Column(children: [
        // Top hint card
        Container(
          margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.brandSoft, Colors.white],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.brand.withOpacity(0.2)),
          ),
          child: Row(children: [
            const Icon(Symbols.tips_and_updates, color: AppColors.brand, size: 22),
            const Gap(10),
            Expanded(child: Text(
              'Try: "For Ravi 2 kg sugar 50 rupees and 1 kg salt 20 rupees"',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5, color: AppColors.t2, height: 1.4))),
          ]),
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
                              gradient: LinearGradient(
                                colors: _listening
                                  ? [AppColors.red, const Color(0xFFD53A3A)]
                                  : [AppColors.brand, const Color(0xFF4070FF)],
                                begin: Alignment.topLeft, end: Alignment.bottomRight,
                              ),
                              boxShadow: [BoxShadow(
                                color: (_listening ? AppColors.red : AppColors.brand).withOpacity(0.45),
                                blurRadius: 22,
                                offset: const Offset(0, 8))],
                            ),
                            child: Icon(
                              _listening ? Symbols.stop : Symbols.mic,
                              color: Colors.white,
                              size: 44,
                            ),
                          ),
                        ]);
                      },
                    ),
                  ),
                  const Gap(16),
                  Text(
                    _listening
                      ? 'Listening...'
                      : (_transcript.isEmpty ? 'Tap mic and speak' : 'Tap mic to record again'),
                    style: GoogleFonts.plusJakartaSans(
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
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Symbols.hearing, size: 16, color: AppColors.t3),
                      const Gap(6),
                      Text('I heard:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppColors.t3, letterSpacing: 0.5)),
                    ]),
                    const Gap(8),
                    Text(_transcript,
                      style: GoogleFonts.plusJakartaSans(
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
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.green.withOpacity(0.3)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Symbols.auto_awesome, size: 18, color: AppColors.green),
                      const Gap(8),
                      Text('Extracted',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, fontWeight: FontWeight.w800,
                          color: AppColors.green, letterSpacing: 0.5)),
                    ]),
                    const Gap(10),
                    if (_parsed!.customerName != null) ...[
                      _kvRow(Symbols.person, 'Customer', _parsed!.customerName!),
                      const Gap(8),
                    ],
                    if (_parsed!.items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('No items detected. Try speaking again with clearer pricing.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5, color: AppColors.t3, fontStyle: FontStyle.italic)),
                      )
                    else ...[
                      Text('Items',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.t3, letterSpacing: 0.5)),
                      const Gap(6),
                      ..._parsed!.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8)),
                          child: Row(children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.brandSoft, borderRadius: BorderRadius.circular(7)),
                              child: const Icon(Symbols.shopping_basket,
                                size: 16, color: AppColors.brand)),
                            const Gap(10),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(item.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.t1)),
                              Text('${item.qty.toStringAsFixed(item.qty.truncateToDouble() == item.qty ? 0 : 1)} ${item.unit}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11, color: AppColors.t3)),
                            ])),
                            Text('₹${item.price.toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.brand)),
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
                    label: Text('Try again',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.t2,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
                  )),
                  const Gap(10),
                  Expanded(flex: 2, child: ElevatedButton.icon(
                    onPressed: _parsed!.items.isEmpty ? null : _proceedToCreate,
                    icon: const Icon(Symbols.arrow_forward, size: 18),
                    label: Text('Continue',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
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
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Voice Tips',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.t1)),
                    const Gap(10),
                    _tip('Speak slowly and clearly'),
                    _tip('Mention quantity, item name, and price'),
                    _tip('Say "for [Customer Name]" at the start'),
                    _tip('Separate items with "and" or pause'),
                    _tip('You can edit everything in the next step'),
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
      const Padding(
        padding: EdgeInsets.only(top: 5),
        child: Icon(Symbols.fiber_manual_record, size: 6, color: AppColors.t3)),
      const Gap(8),
      Expanded(child: Text(text,
        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.t2, height: 1.4))),
    ]));

  Widget _kvRow(IconData icon, String label, String value) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(8)),
    child: Row(children: [
      Icon(icon, size: 16, color: AppColors.t3),
      const Gap(8),
      Text('$label:', style: GoogleFonts.plusJakartaSans(
        fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.t3)),
      const Gap(8),
      Text(value, style: GoogleFonts.plusJakartaSans(
        fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.t1)),
    ]));
}
