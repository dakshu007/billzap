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
import '../design/components.dart';
import '../design/tokens.dart';
import '../providers/providers.dart';
import '../utils/profile_completeness.dart';

// Tracks whether the modal has been shown this session (per-app-launch
// state). Riverpod 3 removed the simple value-provider, so this is a
// minimal Notifier with an explicit setter.
class _ModalShownNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void markShown() => state = true;
}

final _modalShownThisSession =
    NotifierProvider<_ModalShownNotifier, bool>(_ModalShownNotifier.new);

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
      ref.read(_modalShownThisSession.notifier).markShown();
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
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: false, // the buttons are the way out, not a stray tap
    barrierLabel: 'Welcome',
    barrierColor: Colors.black.withValues(alpha: AppTokens.pick(0.34, 0.62)),
    transitionDuration: AppMotion.slow,
    pageBuilder: (ctx, _, __) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      // Rises and settles with a little overshoot rather than popping in
      // at full size — a first impression is worth animating properly.
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      return Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 40 * (1 - curved.value)),
          child: Transform.scale(
            scale: 0.92 + 0.08 * curved.value,
            child: _WelcomeSheet(onClose: () => Navigator.pop(ctx)),
          ),
        ),
      );
    },
  );
}

class _WelcomeSheet extends StatelessWidget {
  final VoidCallback onClose;
  const _WelcomeSheet({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final features = <(IconData, String, String)>[
      (Symbols.receipt_long, 'GST-compliant invoices',
          'CGST, SGST and IGST worked out for you'),
      (Symbols.qr_code_2, 'UPI QR on every bill',
          'Customers pay by scanning, straight away'),
      (Symbols.picture_as_pdf, 'Your name on every PDF',
          'Shared to WhatsApp with your branding'),
      (Symbols.wifi_off, 'Works with no signal',
          'Everything stays on this phone'),
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.gutter),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.fromLTRB(
                AppSpace.xl, AppSpace.xxl, AppSpace.xl, AppSpace.xl),
            decoration: BoxDecoration(
              color: AppColor.surface,
              borderRadius: AppRadius.all(AppRadius.sheet),
              border: Border.all(color: AppColor.hairline),
              boxShadow: AppElevation.lifted,
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Hero mark — jade, glowing, the same language as the
              // primary action it is asking for.
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColor.primary,
                  borderRadius: AppRadius.all(24),
                  boxShadow: AppElevation.glow(AppColor.primary),
                ),
                child: Icon(Symbols.storefront,
                    color: AppColor.onPrimary, size: 34),
              ),
              const Gap(AppSpace.xl),
              Text('Set up your shop',
                  textAlign: TextAlign.center,
                  style: AppFont.style(AppType.titleL,
                      color: AppColor.textPrimary)),
              const Gap(AppSpace.sm),
              Text(
                'A minute now, and every bill you send carries your name, '
                'your GSTIN and your UPI.',
                textAlign: TextAlign.center,
                style:
                    AppFont.style(AppType.bodyM, color: AppColor.textTertiary),
              ),
              const Gap(AppSpace.xl),

              for (var i = 0; i < features.length; i++) ...[
                if (i > 0) const Gap(AppSpace.md),
                _Feature(
                  icon: features[i].$1,
                  title: features[i].$2,
                  detail: features[i].$3,
                ),
              ],

              const Gap(AppSpace.xxl),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Set up profile',
                  trailingIcon: Symbols.arrow_forward,
                  onPressed: () {
                    onClose();
                    GoRouter.of(context).go('/settings');
                  },
                ),
              ),
              const Gap(AppSpace.sm),
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onClose();
                },
                child: Text('Not now',
                    style: AppFont.style(AppType.labelM,
                        color: AppColor.textTertiary)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String title, detail;
  const _Feature({required this.icon, required this.title, required this.detail});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColor.wash(AppColor.primary),
              borderRadius: AppRadius.all(AppRadius.sm),
            ),
            child: Icon(icon, size: 17, color: AppColor.primary),
          ),
          const Gap(AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: AppFont.style(AppType.labelL,
                        color: AppColor.textPrimary)),
                const Gap(2),
                Text(detail,
                    style: AppFont.style(AppType.bodyS,
                        color: AppColor.textTertiary)),
              ],
            ),
          ),
        ],
      );
}

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
          AppAvatar(icon: Symbols.warning, tone: AppColors.orange, size: 42),
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
                valueColor: AlwaysStoppedAnimation(AppColors.orange),
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
