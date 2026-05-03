// lib/screens/lock/lock_screen.dart
// Full-screen lock UI — shown when app is locked.
// Accepts PIN entry; optionally biometric unlock.
// Has "Forgot PIN" link to recovery flow.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/app_lock_service.dart';

class LockScreen extends StatefulWidget {
  /// Called when unlock succeeds. Navigate away.
  final VoidCallback? onUnlocked;
  const LockScreen({super.key, this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';
  bool _error = false;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    // Auto-trigger biometric prompt if enabled
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    if (!AppLockService.instance.isBiometricEnabled) return;
    if (!mounted) return;
    final ok = await AppLockService.instance.authenticateBiometric();
    if (ok && mounted) {
      _onUnlocked();
    }
  }

  void _appendDigit(String d) {
    if (_processing) return;
    if (_pin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin += d;
      _error = false;
    });
    if (_pin.length == 4) {
      _verifyPin();
    }
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = false;
    });
  }

  Future<void> _verifyPin() async {
    setState(() => _processing = true);
    final ok = await AppLockService.instance.verifyPin(_pin);
    if (!mounted) return;
    if (ok) {
      HapticFeedback.mediumImpact();
      _onUnlocked();
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _error = true;
        _pin = '';
        _processing = false;
      });
    }
  }

  void _onUnlocked() {
    widget.onUnlocked?.call();
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Can't back-button out of lock screen
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Column(children: [
              // ─── Top: lock icon + brand ───
              const Spacer(flex: 2),
              Container(
                width: 76, height: 76,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.brand, Color(0xFF4070FF)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(
                    color: AppColors.brand.withOpacity(0.32),
                    blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: const Icon(Symbols.lock, color: Colors.white, size: 38),
              ),
              const Gap(18),
              Text('BillZap',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22, fontWeight: FontWeight.w900,
                  color: AppColors.t1, letterSpacing: -0.5)),
              const Gap(4),
              Text(
                _error ? 'Wrong PIN. Try again.' : 'Enter your 4-digit PIN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: _error ? AppColors.red : AppColors.t3,
                  fontWeight: _error ? FontWeight.w700 : FontWeight.w500),
              ),
              const Gap(28),

              // ─── PIN dots ───
              Row(mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _pin.length;
                  return Container(
                    width: 16, height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 9),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? (_error ? AppColors.red : AppColors.brand)
                          : AppColors.card,
                      border: Border.all(
                        color: _error ? AppColors.red : AppColors.border,
                        width: 1.5),
                    ),
                  );
                })),

              const Gap(18),

              // ─── Biometric button (if enabled) ───
              if (AppLockService.instance.isBiometricEnabled)
                TextButton.icon(
                  onPressed: _tryBiometric,
                  icon: const Icon(Symbols.fingerprint,
                    size: 22, color: AppColors.brand),
                  label: Text('Use fingerprint',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w800,
                      color: AppColors.brand)),
                ),

              const Spacer(flex: 1),

              // ─── Number pad ───
              _NumberPad(
                onDigit: _appendDigit,
                onBackspace: _backspace,
              ),
              const Gap(14),

              // ─── Forgot PIN ───
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.push('/forgot-pin');
                },
                child: Text('Forgot PIN?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.t3,
                    decoration: TextDecoration.underline)),
              ),

              const Gap(8),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// NUMBER PAD — reusable
// ═══════════════════════════════════════════════════════════════
class _NumberPad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  const _NumberPad({required this.onDigit, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _row(['1', '2', '3']),
      const Gap(10),
      _row(['4', '5', '6']),
      const Gap(10),
      _row(['7', '8', '9']),
      const Gap(10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(width: 70),  // empty slot
        const Gap(14),
        _digitButton('0'),
        const Gap(14),
        _backspaceButton(),
      ]),
    ]);
  }

  Widget _row(List<String> digits) {
    return Row(mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < digits.length; i++) ...[
          if (i > 0) const Gap(14),
          _digitButton(digits[i]),
        ],
      ]);
  }

  Widget _digitButton(String d) {
    return SizedBox(
      width: 70, height: 70,
      child: Material(
        color: AppColors.card,
        shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
        elevation: 0,
        child: InkWell(
          onTap: () => onDigit(d),
          customBorder: const CircleBorder(),
          child: Center(child: Text(d,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26, fontWeight: FontWeight.w700,
              color: AppColors.t1))),
        ),
      ),
    );
  }

  Widget _backspaceButton() {
    return SizedBox(
      width: 70, height: 70,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onBackspace,
          customBorder: const CircleBorder(),
          child: const Center(child: Icon(Symbols.backspace,
            size: 26, color: AppColors.t2)),
        ),
      ),
    );
  }
}
