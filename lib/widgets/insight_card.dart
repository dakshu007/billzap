// lib/widgets/insight_card.dart
// Beautiful daily insight card shown on the dashboard.
// Auto-generates from local data, rotates by day of week.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:material_symbols_icons/symbols.dart';
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border, width: 0.6),
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
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  color: colors.tagText,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ]),
          const Gap(8),
          // Main message
          Text(
            insight.message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      insight.actionLabel!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('WhatsApp not available'),
            backgroundColor: AppColors.red));
        }
      }
    } catch (_) {}
  }

  _InsightColors _colorsFor(InsightTone tone) {
    switch (tone) {
      case InsightTone.celebration:
        return _InsightColors(
          gradient: [const Color(0xFFFFF4E5), const Color(0xFFFFFAF0)],
          border: const Color(0xFFFFB84D).withOpacity(0.5),
          tagBg: const Color(0xFFFF9800),
          tagText: Colors.white,
          btnBg: const Color(0xFFFF9800),
          btnText: Colors.white,
        );
      case InsightTone.positive:
        return _InsightColors(
          gradient: [const Color(0xFFE8F5E9), const Color(0xFFF1F8E9)],
          border: const Color(0xFF4CAF50).withOpacity(0.4),
          tagBg: const Color(0xFF2E7D32),
          tagText: Colors.white,
          btnBg: const Color(0xFF2E7D32),
          btnText: Colors.white,
        );
      case InsightTone.warning:
        return _InsightColors(
          gradient: [const Color(0xFFFFF3E0), const Color(0xFFFFFAF0)],
          border: const Color(0xFFFF9800).withOpacity(0.4),
          tagBg: const Color(0xFFE65100),
          tagText: Colors.white,
          btnBg: const Color(0xFFE65100),
          btnText: Colors.white,
        );
      case InsightTone.neutral:
        return _InsightColors(
          gradient: [AppColors.brandSoft, Colors.white],
          border: AppColors.brand.withOpacity(0.3),
          tagBg: AppColors.brand,
          tagText: Colors.white,
          btnBg: AppColors.brand,
          btnText: Colors.white,
        );
    }
  }
}

class _InsightColors {
  final List<Color> gradient;
  final Color border;
  final Color tagBg;
  final Color tagText;
  final Color btnBg;
  final Color btnText;
  _InsightColors({
    required this.gradient,
    required this.border,
    required this.tagBg,
    required this.tagText,
    required this.btnBg,
    required this.btnText,
  });
}
