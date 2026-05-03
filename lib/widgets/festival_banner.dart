// lib/widgets/festival_banner.dart
// Shown on dashboard 1 day before and on day of any major festival.
// Tap → opens FestivalGreetingScreen for batch WhatsApp send.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../utils/festival_data.dart';

class FestivalBanner extends ConsumerWidget {
  const FestivalBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biz = ref.watch(businessProvider);
    // Try to derive state code from business state name (best effort)
    final stateCode = _stateCodeFor((biz?.state as String?) ?? '');
    final festival = FestivalData.upcoming(userStateCode: stateCode);

    if (festival == null) return const SizedBox.shrink();

    // Determine label
    final String prefix;
    if (festival.isToday) {
      prefix = "It's ${festival.name} today!";
    } else if (festival.isTomorrow) {
      prefix = "${festival.name} is tomorrow";
    } else {
      prefix = festival.name;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/festival-greet/${festival.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6F00), Color(0xFFFFB300)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: const Color(0xFFFF6F00).withOpacity(0.35),
            blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(festival.emoji,
              style: const TextStyle(fontSize: 26))),
          ),
          const Gap(13),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(prefix,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
              const Gap(2),
              Text('Send greetings to your customers in one tap',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5, color: Colors.white.withOpacity(0.92))),
            ]),
          ),
          const Icon(Symbols.arrow_forward, color: Colors.white, size: 20),
        ]),
      ),
    );
  }

  // Map business state name to region code for festival filtering.
  // Best-effort. Default to null = show all pan-India festivals.
  String? _stateCodeFor(String state) {
    final lc = state.toLowerCase().trim();
    if (lc.contains('tamil')) return 'TN';
    if (lc.contains('kerala')) return 'KL';
    if (lc.contains('punjab')) return 'PB';
    if (lc.contains('karnataka')) return 'KA';
    if (lc.contains('andhra')) return 'AP';
    if (lc.contains('telangana')) return 'TS';
    if (lc.contains('maharashtra')) return 'MH';
    if (lc.contains('gujarat')) return 'GJ';
    if (lc.contains('west bengal') || lc.contains('bengal')) return 'WB';
    return null;
  }
}
