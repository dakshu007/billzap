// lib/screens/lock/lock_setup_screen.dart
// Multi-step setup flow for enabling app lock:
//  Step 1: Warning + create backup
//  Step 2: Optional share backup (WhatsApp/Email/Skip)
//  Step 3: Set 4-digit PIN
//  Step 4: Confirm PIN
//  Step 5: Optional fingerprint enrollment
//  Step 6: Done

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/app_lock_service.dart';
import '../../utils/backup_service.dart';

class LockSetupScreen extends StatefulWidget {
  const LockSetupScreen({super.key});
  @override
  State<LockSetupScreen> createState() => _LockSetupState();
}

class _LockSetupState extends State<LockSetupScreen> {
  int _step = 0;
  String? _backupFilePath;
  String _pin = '';
  String _confirmPin = '';
  bool _busy = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final ok = await AppLockService.instance.canUseBiometric();
    if (mounted) setState(() => _biometricAvailable = ok);
  }

  // ─────────── Step 1: Create backup ───────────
  Future<void> _createBackup() async {
    setState(() => _busy = true);
    try {
      final result = await BackupService.createBackup();
      if (!mounted) return;
      if (result.success && result.filePath != null) {
        setState(() {
          _backupFilePath = result.filePath;
          _step = 1;
          _busy = false;
        });
      } else {
        setState(() => _busy = false);
        _showError(result.error ?? 'Backup failed. Cannot enable lock.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showError('Backup failed: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.red));
  }

  // ─────────── Step 2: Share backup ───────────
  Future<void> _shareBackup() async {
    if (_backupFilePath == null) return;
    try {
      await Share.shareXFiles([XFile(_backupFilePath!)],
        subject: 'BillZap Backup — Keep this safe',
        text: 'My BillZap backup file. I\'ll need this if I ever forget my PIN. Keep it safe!');
    } catch (_) {}
  }

  // ─────────── Step 5: Biometric enrollment ───────────
  Future<void> _enrollBiometric() async {
    final ok = await AppLockService.instance.authenticateBiometric();
    if (!mounted) return;
    if (ok) {
      // Enable lock with PIN + biometric
      await AppLockService.instance.enableLock(pin: _pin, useBiometric: true);
      if (!mounted) return;
      setState(() => _step = 5); // Done step
    } else {
      _showError('Fingerprint not enrolled. PIN-only lock will be set up.');
      await AppLockService.instance.enableLock(pin: _pin, useBiometric: false);
      if (!mounted) return;
      setState(() => _step = 5);
    }
  }

  // ─────────── Skip biometric ───────────
  Future<void> _skipBiometric() async {
    await AppLockService.instance.enableLock(pin: _pin, useBiometric: false);
    if (!mounted) return;
    setState(() => _step = 5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        iconTheme: const IconThemeData(color: AppColors.t1),
        title: Text('Set up App Lock',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.t1)),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _buildStep(),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _StepWarning(
        key: const ValueKey(0),
        busy: _busy,
        onContinue: _createBackup,
      );
      case 1: return _StepBackupShare(
        key: const ValueKey(1),
        backupPath: _backupFilePath ?? '',
        onShare: _shareBackup,
        onContinue: () => setState(() => _step = 2),
      );
      case 2: return _StepPin(
        key: const ValueKey(2),
        title: 'Set 4-digit PIN',
        subtitle: 'Choose a PIN you\'ll remember',
        onComplete: (pin) {
          setState(() {
            _pin = pin;
            _step = 3;
          });
        },
      );
      case 3: return _StepPin(
        key: const ValueKey(3),
        title: 'Confirm PIN',
        subtitle: 'Re-enter your PIN to confirm',
        onComplete: (pin) {
          if (pin == _pin) {
            // Move to biometric step (or skip if not available)
            if (_biometricAvailable) {
              setState(() => _step = 4);
            } else {
              _skipBiometric();
            }
          } else {
            _showError('PINs don\'t match. Please try again.');
            setState(() => _step = 2);
          }
        },
      );
      case 4: return _StepBiometric(
        key: const ValueKey(4),
        onEnroll: _enrollBiometric,
        onSkip: _skipBiometric,
      );
      case 5: return _StepDone(
        key: const ValueKey(5),
        onClose: () => Navigator.of(context).pop(true),
      );
      default: return const SizedBox.shrink();
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// STEP 0: Warning + backup
// ═══════════════════════════════════════════════════════════════
class _StepWarning extends StatelessWidget {
  final bool busy;
  final VoidCallback onContinue;
  const _StepWarning({super.key, required this.busy, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Gap(16),
        Container(
          width: 76, height: 76,
          decoration: BoxDecoration(
            color: AppColors.yellowSoft,
            borderRadius: BorderRadius.circular(20)),
          child: const Icon(Symbols.warning, color: AppColors.orange, size: 40),
        ).animate(),
        const Gap(20),
        Text('Before we set your PIN',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.t1)),
        const Gap(10),
        Text(
          'BillZap will create a backup of your data first. '
          'You\'ll need this backup if you ever forget your PIN — '
          'it\'s the only way to recover.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5, color: AppColors.t2, height: 1.55)),
        const Gap(20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.redSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.red.withOpacity(0.25))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Symbols.error, color: AppColors.red, size: 22),
            const Gap(10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('IMPORTANT',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, fontWeight: FontWeight.w900,
                  color: AppColors.red, letterSpacing: 0.6)),
              const Gap(3),
              Text(
                'If you forget your PIN AND lose your backup file, your data '
                'cannot be recovered. Please make sure to save the backup '
                'somewhere safe (we\'ll prompt you next).',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: AppColors.t1, height: 1.5)),
            ])),
          ]),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: busy ? null : onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brand,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13)),
            elevation: 0),
          child: busy
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Symbols.shield, size: 18),
                const Gap(8),
                Text('Create backup & continue',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5, fontWeight: FontWeight.w800)),
              ]),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STEP 1: Share backup (recommended)
// ═══════════════════════════════════════════════════════════════
class _StepBackupShare extends StatelessWidget {
  final String backupPath;
  final VoidCallback onShare;
  final VoidCallback onContinue;
  const _StepBackupShare({
    super.key,
    required this.backupPath,
    required this.onShare,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final filename = backupPath.split('/').last;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Gap(16),
        Container(
          width: 76, height: 76,
          decoration: BoxDecoration(
            color: AppColors.greenSoft,
            borderRadius: BorderRadius.circular(20)),
          child: const Icon(Symbols.check_circle, color: AppColors.green, size: 44),
        ),
        const Gap(20),
        Text('Backup created ✓',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.t1)),
        const Gap(10),
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const Icon(Symbols.folder, size: 18, color: AppColors.brand),
            const Gap(8),
            Expanded(child: Text(filename,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.brand,
                fontFeatures: const [FontFeature.tabularFigures()]),
              overflow: TextOverflow.ellipsis)),
          ]),
        ),
        const Gap(18),
        Text(
          'For extra safety, send this backup to yourself on WhatsApp '
          'or email. If you ever lose your phone, you can restore from it.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13, color: AppColors.t2, height: 1.55)),
        const Gap(20),
        ElevatedButton.icon(
          onPressed: onShare,
          icon: const Icon(Symbols.share, size: 18),
          label: Text('Send via WhatsApp / Email',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w800)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13)),
            elevation: 0),
        ),
        const Spacer(),
        TextButton(
          onPressed: onContinue,
          child: Text('Skip — backup is on phone',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.t3)),
        ),
        const Gap(4),
        ElevatedButton(
          onPressed: onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brand,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13)),
            elevation: 0),
          child: Text('Continue',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STEP 2/3: PIN entry (used for set + confirm)
// ═══════════════════════════════════════════════════════════════
class _StepPin extends StatefulWidget {
  final String title;
  final String subtitle;
  final ValueChanged<String> onComplete;
  const _StepPin({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onComplete,
  });

  @override
  State<_StepPin> createState() => _StepPinState();
}

class _StepPinState extends State<_StepPin> {
  String _pin = '';

  void _appendDigit(String d) {
    if (_pin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() => _pin += d);
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) widget.onComplete(_pin);
      });
    }
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(children: [
        const Gap(16),
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(16)),
          child: const Icon(Symbols.pin, color: AppColors.brand, size: 32),
        ),
        const Gap(16),
        Text(widget.title,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.t1)),
        const Gap(6),
        Text(widget.subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5, color: AppColors.t3)),
        const Gap(24),
        Row(mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final filled = i < _pin.length;
            return Container(
              width: 16, height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 9),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? AppColors.brand : AppColors.card,
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
            );
          })),
        const Spacer(),
        _NumberPadCompact(onDigit: _appendDigit, onBackspace: _backspace),
        const Gap(20),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STEP 4: Biometric enrollment
// ═══════════════════════════════════════════════════════════════
class _StepBiometric extends StatelessWidget {
  final VoidCallback onEnroll;
  final VoidCallback onSkip;
  const _StepBiometric({
    super.key,
    required this.onEnroll,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Gap(16),
        Center(child: Container(
          width: 76, height: 76,
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(20)),
          child: const Icon(Symbols.fingerprint, color: AppColors.brand, size: 44),
        )),
        const Gap(20),
        Text('Add Fingerprint?',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.t1)),
        const Gap(10),
        Text(
          'Unlock BillZap with your fingerprint instead of typing your PIN '
          'every time. You can still use your PIN as backup.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13, color: AppColors.t2, height: 1.55)),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: onEnroll,
          icon: const Icon(Symbols.fingerprint, size: 20),
          label: Text('Enable Fingerprint',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5, fontWeight: FontWeight.w800)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brand,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13)),
            elevation: 0),
        ),
        const Gap(8),
        TextButton(
          onPressed: onSkip,
          child: Text('Skip — PIN only',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.t3)),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STEP 5: Done
// ═══════════════════════════════════════════════════════════════
class _StepDone extends StatelessWidget {
  final VoidCallback onClose;
  const _StepDone({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Spacer(),
        Center(child: Container(
          width: 96, height: 96,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.green, Color(0xFF34D399)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(
              color: AppColors.green.withOpacity(0.32),
              blurRadius: 22, offset: const Offset(0, 10))],
          ),
          child: const Icon(Symbols.check, color: Colors.white, size: 56),
        )),
        const Gap(22),
        Text('App Lock Enabled 🔒',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.t1)),
        const Gap(10),
        Text(
          'BillZap will lock when you switch apps and return after 1 minute. '
          'Make sure you remember your PIN — and keep your backup file safe!',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5, color: AppColors.t2, height: 1.6)),
        const Spacer(),
        ElevatedButton(
          onPressed: onClose,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brand,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13)),
            elevation: 0),
          child: Text('Done',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Compact number pad (used during setup — slightly smaller)
// ═══════════════════════════════════════════════════════════════
class _NumberPadCompact extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  const _NumberPadCompact({required this.onDigit, required this.onBackspace});

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
        const SizedBox(width: 64),
        const Gap(12),
        _digit('0'),
        const Gap(12),
        _back(),
      ]),
    ]);
  }

  Widget _row(List<String> ds) => Row(mainAxisAlignment: MainAxisAlignment.center,
    children: [for (int i = 0; i < ds.length; i++) ...[if (i > 0) const Gap(12), _digit(ds[i])]]);

  Widget _digit(String d) => SizedBox(
    width: 64, height: 64,
    child: Material(
      color: AppColors.card,
      shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        onTap: () => onDigit(d),
        customBorder: const CircleBorder(),
        child: Center(child: Text(d,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.t1))),
      ),
    ),
  );

  Widget _back() => SizedBox(
    width: 64, height: 64,
    child: Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onBackspace,
        customBorder: const CircleBorder(),
        child: const Center(child: Icon(Symbols.backspace, size: 24, color: AppColors.t2)),
      ),
    ),
  );
}

// no-op helper for any code that referenced `.animate()` from animate package
extension _NoAnim on Widget { Widget animate() => this; }
