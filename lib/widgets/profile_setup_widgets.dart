// lib/widgets/profile_setup_widgets.dart
// Two related widgets:
// 1. WelcomeProfileModal — shown automatically on first home visit if profile is empty
// 2. ProfileIncompleteBanner — persistent banner on home if profile <80% complete
//
// Both route to /settings when user taps "Set up profile".

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:billzap/theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'ui_kit.dart';
import '../providers/providers.dart';
import '../utils/profile_completeness.dart';

// Tracks whether the modal has been shown this session (per-app-launch state)
final _modalShownThisSession = StateProvider<bool>((_) => false);

/// Call this from dashboard's build to auto-show the welcome modal once
/// per session if the business profile is empty.
class WelcomeProfileModalTrigger extends ConsumerStatefulWidget {
  const WelcomeProfileModalTrigger({super.key});

  @override
  ConsumerState<WelcomeProfileModalTrigger> createState() =>
      _WelcomeProfileModalTriggerState();
}

class _WelcomeProfileModalTriggerState
    extends ConsumerState<WelcomeProfileModalTrigger> {
  @override
  void initState() {
    super.initState();
    // Schedule modal to appear after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowModal());
  }

  void _maybeShowModal() {
    if (!mounted) return;
    final biz = ref.read(businessProvider);
    final shown = ref.read(_modalShownThisSession);

    // Only show if business is essentially empty AND we haven't shown this session
    if (!shown && ProfileCompleteness.isEmpty(biz)) {
      ref.read(_modalShownThisSession.notifier).state = true;
      // Slight delay so it doesn't pop instantly on app launch
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _showWelcomeModal(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

void _showWelcomeModal(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: false, // Forces user to use the buttons (not tap outside)
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        decoration: BoxDecoration(
          // Use the theme-aware card color so the modal flips with dark mode.
          color: AppColors.card,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(AppColors.isDark ? 0.5 : 0.15),
            blurRadius: 28, offset: const Offset(0, 10))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Hero icon
          Container(
            width: 76, height: 76,
            decoration: BoxDecoration(
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [BoxShadow(
                color: AppColors.brand.withOpacity(0.35),
                blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Icon(Symbols.storefront, color: AppColors.onBrand, size: 40),
          ),
          const Gap(20),
          Text('Welcome to BillZap! 👋',
            textAlign: TextAlign.center,
            style: AppFont.sans(
              fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.t1)),
          const Gap(6),
          Text('Set up your business profile to create professional invoices',
            textAlign: TextAlign.center,
            style: AppFont.sans(
              fontSize: 13, color: AppColors.t3, height: 1.4)),
          const Gap(20),
          // Feature checklist
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Feature('🧾', 'Your business name on every PDF'),
              const Gap(8),
              _Feature('✓', 'GST-compliant invoices'),
              const Gap(8),
              _Feature('📱', 'UPI QR for instant payments'),
              const Gap(8),
              _Feature('💬', 'WhatsApp share with branding'),
            ]),
          ),
          const Gap(20),
          // Primary action
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx);
              GoRouter.of(context).go('/settings');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
              elevation: 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Set up profile',
                style: AppFont.sans(
                  fontSize: 15, fontWeight: FontWeight.w600)),
              const Gap(8),
              const Icon(Symbols.arrow_forward, size: 18),
            ]),
          )),
          const Gap(8),
          // Secondary (dismissible)
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(ctx);
            },
            child: Text('Maybe later',
              style: AppFont.sans(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.t3)),
          ),
          const Gap(4),
          Text('You can always set this up from Settings',
            textAlign: TextAlign.center,
            style: AppFont.sans(
              fontSize: 10.5, color: AppColors.t4, fontStyle: FontStyle.italic)),
        ]),
      ),
    ),
  );
}

class _Feature extends StatelessWidget {
  final String emoji;
  final String text;
  const _Feature(this.emoji, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(width: 24,
        child: Text(emoji, style: const TextStyle(fontSize: 16))),
      const Gap(8),
      Expanded(child: Text(text,
        style: AppFont.sans(
          fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.t1))),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════
// PERSISTENT BANNER ON HOME
// ═══════════════════════════════════════════════════════════════
class ProfileIncompleteBanner extends ConsumerWidget {
  const ProfileIncompleteBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biz = ref.watch(businessProvider);
    final score = ProfileCompleteness.score(biz);

    // Hide if profile is sufficiently complete
    if (score >= 80) return const SizedBox.shrink();

    final missingText = ProfileCompleteness.topMissing(biz);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.go('/settings');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          // The last coloured panel on the dashboard — now a plain card
          // with an orange accent badge, matching every other row.
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadow.card,
          border: AppColors.isDark ? Border.all(color: AppColors.border) : null,
        ),
        child: Row(children: [
          AppBadge(icon: Symbols.warning, tone: AppColors.orange, size: 42),
          const Gap(13),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Profile incomplete',
                style: AppFont.sans(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  letterSpacing: -0.2, color: AppColors.t1)),
              const Gap(8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(99)),
                child: Text('$score%',
                  style: AppFont.sans(
                    fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ]),
            const Gap(2),
            Text(missingText,
              style: AppFont.sans(
                fontSize: 12.5, color: AppColors.t3)),
            const Gap(6),
            // Progress bar — track adapts so it doesn't flash bright white
            // against the dark amber panel in dark mode.
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 4,
                backgroundColor: AppColors.inset,
                valueColor: const AlwaysStoppedAnimation(AppColors.orange),
              ),
            ),
          ])),
          const Gap(8),
          Icon(Symbols.chevron_right, color: AppColors.t4, size: 20),
        ]),
      ),
    );
  }
}
