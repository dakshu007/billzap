// lib/screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashState();
}

class _SplashState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brand,
      body: FadeTransition(
        opacity: _fade,
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(child: Text('\u26a1',
              style: const TextStyle(fontSize: 42))),
          ),
          const SizedBox(height: 20),
          Text('BillZap', style: GoogleFonts.nunito(
            fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white,
            letterSpacing: -1)),
          const SizedBox(height: 6),
          Text('GST Billing Made Simple', style: GoogleFonts.dmSans(
            fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500)),
          const SizedBox(height: 60),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Colors.white54),
            strokeWidth: 2),
        ])),
      ),
    );
  }
}
