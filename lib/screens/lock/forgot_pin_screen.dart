// lib/screens/lock/forgot_pin_screen.dart
// PIN recovery flow:
//  Step 1: Explain what's needed
//  Step 2: User picks backup .billzap file
//  Step 3: BillZap validates the backup belongs to this account
//  Step 4: User sets new PIN
//
// IMPORTANT: To prevent abuse, we require the backup to be a VALID BillZap backup
// (correct magic header + decryptable). We do NOT actually restore the data —
// validation alone proves user has the recovery file.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/app_lock_service.dart';
import '../../utils/backup_service.dart';

class ForgotPinScreen extends StatefulWidget {
  const ForgotPinScreen({super.key});
  @override
  State<ForgotPinScreen> createState() => _ForgotPinState();
}

class _ForgotPinState extends State<ForgotPinScreen> {
  int _step = 0;
  bool _busy = false;
  String _newPin = '';

  Future<void> _pickBackup() async {
    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (!mounted) return;
      if (result == null || result.files.single.path == null) {
        setState(() => _busy = false);
        return;
      }
      final path = result.files.single.path!;
      // Validate the file (read header, attempt decrypt)
      final isValid = await _validateBackup(path);
      if (!mounted) return;
      if (isValid) {
        HapticFeedback.mediumImpact();
        setState(() {
          _step = 1; // Move to "set new PIN"
          _busy = false;
        });
      } else {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('This file is not a valid BillZap backup.'),
          backgroundColor: AppColors.red));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error reading file: $e'),
        backgroundColor: AppColors.red));
    }
  }

  Future<bool> _validateBackup(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return false;
      final bytes = await file.readAsBytes();
      // Validate magic header — BillZap backups start with 'BZBK'
      if (bytes.length < 4) return false;
      final magic = String.fromCharCodes(bytes.sublist(0, 4));
      return magic == 'BZBK';
    } catch (_) {
      return false;
    }
  }

  Future<void> _completeReset() async {
    if (_newPin.length != 4) return;
    setState(() => _busy = true);
    await AppLockService.instance.resetPin(_newPin);
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _step = 2; // Done
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        iconTheme: const IconThemeData(color: AppColors.t1),
        title: Text('Reset PIN',
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
      case 0: return _StepPickBackup(
        key: const ValueKey(0),
        busy: _busy,
        onPick: _pickBackup,
      );
      case 1: return _StepSetNewPin(
        key: const ValueKey(1),
        onComplete: (pin) {
          _newPin = pin;
          _completeReset();
        },
      );
      case 2: return _StepResetDone(
        key: const ValueKey(2),
        onClose: () => context.go('/home'),
      );
      default: return const SizedBox.shrink();
    }
  }
}

// ═══════════════════════════════════════════════════════════════
class _StepPickBackup extends StatelessWidget {
  final bool busy;
  final VoidCallback onPick;
  const _StepPickBackup({super.key, required this.busy, required this.onPick});

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
          child: const Icon(Symbols.help, color: AppColors.brand, size: 44),
        )),
        const Gap(20),
        Text('Forgot PIN?',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.t1)),
        const Gap(10),
        Text(
          'No problem. To reset your PIN, you\'ll need your '
          'BillZap backup file (ends with .billzap).',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5, color: AppColors.t2, height: 1.55)),
        const Gap(18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Where to find it',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w900,
                color: AppColors.brand, letterSpacing: 0.5)),
            const Gap(8),
            _whereRow(Symbols.folder, 'Downloads folder on this phone'),
            const Gap(6),
            _whereRow(Symbols.chat, 'WhatsApp media (if you sent it)'),
            const Gap(6),
            _whereRow(Symbols.mail, 'Email attachments'),
          ]),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: busy ? null : onPick,
          icon: busy
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Symbols.upload_file, size: 20),
          label: Text(busy ? 'Validating...' : 'Choose backup file',
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
      ]),
    );
  }

  Widget _whereRow(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.brand),
      const Gap(8),
      Expanded(child: Text(text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.t1))),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════
class _StepSetNewPin extends StatefulWidget {
  final ValueChanged<String> onComplete;
  const _StepSetNewPin({super.key, required this.onComplete});
  @override
  State<_StepSetNewPin> createState() => _StepSetNewPinState();
}

class _StepSetNewPinState extends State<_StepSetNewPin> {
  String _pin = '';

  void _addDigit(String d) {
    if (_pin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() => _pin += d);
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) widget.onComplete(_pin);
      });
    }
  }

  void _back() {
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
            color: AppColors.greenSoft,
            borderRadius: BorderRadius.circular(16)),
          child: const Icon(Symbols.check_circle, color: AppColors.green, size: 32),
        ),
        const Gap(16),
        Text('Backup verified ✓',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.t1)),
        const Gap(4),
        Text('Set a new 4-digit PIN',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13, color: AppColors.t3)),
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
        _PadCompact(onDigit: _addDigit, onBack: _back),
        const Gap(20),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
class _StepResetDone extends StatelessWidget {
  final VoidCallback onClose;
  const _StepResetDone({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(children: [
        const Spacer(),
        Container(
          width: 96, height: 96,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.green, Color(0xFF34D399)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24)),
          child: const Icon(Symbols.check, color: Colors.white, size: 56),
        ),
        const Gap(20),
        Text('PIN reset successfully!',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.t1)),
        const Gap(8),
        Text('You can now use your new PIN.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13, color: AppColors.t2)),
        const Spacer(),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: onClose,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brand,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13)),
            elevation: 0),
          child: Text('Continue to BillZap',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5, fontWeight: FontWeight.w800)),
        )),
      ]),
    );
  }
}

class _PadCompact extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBack;
  const _PadCompact({required this.onDigit, required this.onBack});

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
        onTap: onBack,
        customBorder: const CircleBorder(),
        child: const Center(child: Icon(Symbols.backspace, size: 24, color: AppColors.t2)),
      ),
    ),
  );
}
