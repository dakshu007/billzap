// lib/widgets/insight_card.dart
// Beautiful daily insight card shown on the dashboard.
// Auto-generates from local data, rotates by day of week.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:billzap/theme/app_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../utils/insight_engine.dart';

class InsightCard extends ConsumerWidget {
  const InsightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = ref.watch(invoiceProvider);
    final customers = ref.watch(customerProvider);
    final biz = ref.watch(businessProvider);

    final insight = InsightEngine.generate(
      invoices: invoices,
      customers: customers,
    );

    if (insight == null) return const SizedBox.shrink();

    return _InsightContainer(insight: insight, biz: biz);
  }
}

class _InsightContainer extends StatelessWidget {
  final Insight insight;
  final dynamic biz;
  const _InsightContainer({required this.insight, this.biz});

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(insight.tone);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: emoji + title tag
          Row(children: [
            Text(insight.emoji, style: const TextStyle(fontSize: 18)),
            const Gap(8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.tagBg,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                insight.title,
                style: AppFont.sans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colors.tagText,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ]),
          const Gap(8),
          // Main message
          Text(
            insight.message,
            style: AppFont.sans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.t1,
              height: 1.45,
            ),
          ),
          // Optional action button
          if (insight.actionLabel != null && insight.action != null) ...[
            const Gap(10),
            Row(children: [
              GestureDetector(
                onTap: () => _handleAction(context, insight, biz),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: colors.btnBg,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      insight.actionLabel!,
                      style: AppFont.sans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: colors.btnText,
                      ),
                    ),
                    const Gap(4),
                    Icon(
                      Symbols.arrow_forward,
                      size: 13,
                      color: colors.btnText,
                    ),
                  ]),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, Insight insight, dynamic biz) {
    HapticFeedback.lightImpact();
    final action = insight.action!;

    // Special case: top customer "send thanks" via WhatsApp
    if (insight.type == InsightType.topCustomer && action.customerName != null) {
      _sendThanksWhatsApp(context, action.customerName!, biz);
      return;
    }

    // Special case: inactive customer → create invoice with name pre-filled
    if (insight.type == InsightType.inactiveCustomer && action.customerName != null) {
      GoRouter.of(context).push('/create');
      return;
    }

    // Default: navigate to the route
    if (action.route.startsWith('/')) {
      // Filter invoices route to show overdue
      if (insight.type == InsightType.pendingPayments) {
        GoRouter.of(context).go('/invoices');
      } else {
        GoRouter.of(context).go(action.route);
      }
    }
  }

  Future<void> _sendThanksWhatsApp(BuildContext context, String customerName, dynamic biz) async {
    final bizName = (biz?.name as String?)?.isNotEmpty == true ? biz!.name : 'BillZap';
    final msg = Uri.encodeComponent(
      'Hi $customerName,\n\n'
      'Thank you so much for your continued business this month! 🙏\n'
      'It means a lot. Looking forward to serving you again soon.\n\n'
      '— $bizName');

    final url = Uri.parse('https://wa.me/?text=$msg');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('WhatsApp not available'),
            backgroundColor: AppColors.red));
        }
      }
    } catch (_) {}
  }

  /// Accent for the tone's tag and action chip. The panel itself is a
  /// plain card in both themes, so only these two elements carry colour.
  _InsightColors _colorsFor(InsightTone tone) {
    switch (tone) {
      case InsightTone.celebration:
        return _InsightColors(
          tagBg: const Color(0xFFFF9800),
          tagText: Colors.white,
          btnBg: const Color(0xFFFF9800),
          btnText: Colors.white,
        );
      case InsightTone.positive:
        return _InsightColors(
          tagBg: const Color(0xFF2E7D32),
          tagText: Colors.white,
          btnBg: const Color(0xFF2E7D32),
          btnText: Colors.white,
        );
      case InsightTone.warning:
        return _InsightColors(
          tagBg: const Color(0xFFE65100),
          tagText: Colors.white,
          btnBg: const Color(0xFFE65100),
          btnText: Colors.white,
        );
      case InsightTone.neutral:
        return _InsightColors(
          tagBg: AppColors.brand,
          tagText: AppColors.onBrand,
          btnBg: AppColors.brand,
          btnText: AppColors.onBrand,
        );
    }
  }
}

class _InsightColors {
  final Color tagBg;
  final Color tagText;
  final Color btnBg;
  final Color btnText;
  _InsightColors({
    required this.tagBg,
    required this.tagText,
    required this.btnBg,
    required this.btnText,
  });
}
