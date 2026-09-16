// lib/screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../design/tokens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashState();
}

class _SplashState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.82, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.primary,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // The mark alone, not the launcher tile — the tile's own
            // jade ground would disappear into this screen.
            ScaleTransition(
              scale: _scale,
              child: Image.asset(
                'assets/icon_foreground.png',
                // The asset carries Android's adaptive-icon padding, so
                // the mark itself is about half of this box.
                width: 260,
                height: 260,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'BillZap',
              style: AppFont.sans(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  color: AppColor.onPrimary,
                  letterSpacing: -1.2),
            ),
            const SizedBox(height: 6),
            Text(
              'GST Billing Made Simple',
              style: AppFont.sans(
                  fontSize: 14,
                  color: AppColor.onPrimary.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 56),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation(AppColor.onPrimary.withValues(alpha: 0.6)),
                strokeWidth: 2,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
