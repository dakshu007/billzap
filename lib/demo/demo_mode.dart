// lib/demo/demo_mode.dart — the browser demo at billzap.app/try.
//
// The demo is the real app, built from lib/main_demo.dart and run in a
// browser so a visitor can try it before installing. It exists to send
// people to the Play Store, so three things differ from the app:
//
//   - What a browser cannot do, or what only makes sense on a phone
//     (WhatsApp, backups, app lock, voice billing, file import), says
//     "that is in the app" and offers the download instead of failing.
//   - The PDF carries a SAMPLE mark, so the demo is not a free web
//     version that people keep billing from.
//   - The first bill a visitor makes ends on a prompt to install.
//
// Strings here are English only: the demo page around the app is
// English, and keeping them out of the i18n tables keeps the 125
// language files free of words the app itself never shows.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

/// True only in the build made from lib/main_demo.dart.
bool kDemoMode = false;

/// Set when a visitor saves a bill, read once by the preview screen.
bool demoJustMadeBill = false;

const _play = 'https://play.google.com/store/apps/details?id=com.billzap.app';

/// The Play Store page, tagged so Play Console's acquisition report
/// shows which part of the demo sent the install.
Uri playStoreUri(String content) => Uri.parse('$_play&referrer=${Uri.encodeComponent(
    'utm_source=billzap.app&utm_medium=try_demo&utm_content=$content')}');

/// Routes that do nothing useful in a browser. In the demo they open
/// [DemoOnlyInAppScreen] instead.
const demoBlockedRoutes = {
  '/backup': 'Backup and restore',
  '/lock-setup': 'App lock',
  '/forgot-pin': 'App lock',
  '/voice': 'Voice billing',
};

/// In the demo, explains that [feature] is in the app and returns true,
/// so the caller stops. Outside the demo returns false and does nothing.
bool demoBlocked(BuildContext context, String feature) {
  if (!kDemoMode) return false;
  showDemoAppSheet(context,
      title: '$feature is in the app',
      body: 'This is a demo running in your browser. Install BillZap free on '
          'your Android phone to use $feature with your own shop.',
      content: feature.toLowerCase().replaceAll(' ', '_'));
  return true;
}

/// The prompt after a visitor's first bill.
void showFirstBillPrompt(BuildContext context) {
  showDemoAppSheet(context,
      title: 'Your bill is ready',
      body: 'That took seconds. Make bills like this for your own customers, '
          'share them on WhatsApp with a UPI QR, and work offline. Free, '
          'no sign-up.',
      cta: 'Get BillZap free',
      content: 'first_bill');
}

Future<void> showDemoAppSheet(BuildContext context,
    {required String title,
    required String body,
    String cta = 'Download free on Google Play',
    String content = 'demo'}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.border, borderRadius: BorderRadius.circular(99))),
        const Gap(20),
        Text(title,
            textAlign: TextAlign.center,
            style: AppFont.sans(
                fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.t1)),
        const Gap(8),
        Text(body,
            textAlign: TextAlign.center,
            style: AppFont.sans(fontSize: 14, height: 1.5, color: AppColors.t2)),
        const Gap(20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: () {
              launchUrl(playStoreUri(content), mode: LaunchMode.externalApplication);
              Navigator.pop(ctx);
            },
            child: Text(cta,
                style: AppFont.sans(
                    fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
        const Gap(6),
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Keep exploring the demo',
                style: AppFont.sans(fontSize: 13.5, color: AppColors.t2))),
      ]),
    ),
  );
}

/// Shown in place of a screen the browser demo cannot run.
class DemoOnlyInAppScreen extends StatelessWidget {
  const DemoOnlyInAppScreen({super.key, required this.feature});
  final String feature;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(feature),
        leading: BackButton(
            onPressed: () => context.canPop() ? context.pop() : context.go('/home')),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.phone_android_rounded, size: 56, color: AppColors.brand),
            const Gap(16),
            Text('$feature is in the app',
                textAlign: TextAlign.center,
                style: AppFont.sans(
                    fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.t1)),
            const Gap(8),
            Text('This demo runs in your browser. Install BillZap free on your '
                'Android phone to use $feature with your own shop.',
                textAlign: TextAlign.center,
                style: AppFont.sans(fontSize: 14, height: 1.5, color: AppColors.t2)),
            const Gap(22),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: () => launchUrl(
                  playStoreUri(feature.toLowerCase().replaceAll(' ', '_')),
                  mode: LaunchMode.externalApplication),
              child: Text('Download free on Google Play',
                  style: AppFont.sans(
                      fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ]),
        ),
      ),
    );
  }
}
