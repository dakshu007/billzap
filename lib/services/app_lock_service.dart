// lib/services/app_lock_service.dart
// Handles PIN authentication, biometric, and app lifecycle tracking.
// Stores PIN hash + settings in the existing Hive box (billzap_v1).
// PIN is hashed with SHA-256 + salt, never stored plaintext.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppLockService {
  AppLockService._();
  static final AppLockService instance = AppLockService._();

  static const _kPinHash = 'app_lock_pin_hash';
  static const _kBiometric = 'app_lock_biometric';
  static const _kEnabled = 'app_lock_enabled';
  static const _kLastActive = 'app_lock_last_active_at';
  static const _salt = 'billzap_app_lock_v1';

  // Re-lock threshold: 60 seconds of background = require unlock again
  static const Duration _relockAfter = Duration(seconds: 60);

  final _localAuth = LocalAuthentication();
  Box? _box;

  bool _initialised = false;
  bool _enabled = false;
  bool _biometric = false;
  bool _hasUnlocked = false;

  Future<void> init() async {
    if (_initialised) return;
    _box = await Hive.openBox('billzap_v1');
    _enabled = _box?.get(_kEnabled) == true;
    _biometric = _box?.get(_kBiometric) == true;
    _initialised = true;
  }

  bool get isEnabled => _enabled;
  bool get isBiometricEnabled => _biometric;
  bool get hasUnlockedThisSession => _hasUnlocked;

  Future<bool> canUseBiometric() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      debugPrint("AppLock: canCheckBiometrics=$canCheck, isDeviceSupported=$isSupported");
      if (!canCheck || !isSupported) return false;
      final available = await _localAuth.getAvailableBiometrics();
      debugPrint("AppLock: availableBiometrics=$available");
      // Accept ANY enrolled biometric — some devices report 'weak' for fingerprint sensors
      return available.isNotEmpty;
    } catch (e) {
      debugPrint("AppLock: canUseBiometric error: $e");
      return false;
    }
  }

  /// Used during SETUP to test if biometric works, before _biometric flag is set.
  /// Unlike authenticateBiometric(), does not require lock to already be enabled.
  Future<bool> testBiometricForSetup() async {
    try {
      debugPrint("AppLock: testBiometricForSetup starting...");
      final ok = await _localAuth.authenticate(
        localizedReason: 'Confirm your fingerprint to enable for BillZap',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,
          useErrorDialogs: true,
        ),
      );
      debugPrint("AppLock: testBiometricForSetup result=$ok");
      return ok;
    } on Exception catch (e) {
      debugPrint("AppLock: testBiometricForSetup exception: $e");
      // Try once more without biometricOnly — some devices reject strict mode
      try {
        debugPrint("AppLock: retrying without biometricOnly...");
        final ok = await _localAuth.authenticate(
          localizedReason: 'Confirm your fingerprint to enable for BillZap',
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: false,
            useErrorDialogs: true,
          ),
        );
        debugPrint("AppLock: retry result=$ok");
        return ok;
      } catch (e2) {
        debugPrint("AppLock: retry also failed: $e2");
        return false;
      }
    }
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(_salt + pin);
    return sha256.convert(bytes).toString();
  }

  Future<void> enableLock({required String pin, required bool useBiometric}) async {
    final hash = _hashPin(pin);
    await _box?.put(_kPinHash, hash);
    await _box?.put(_kBiometric, useBiometric);
    await _box?.put(_kEnabled, true);
    _enabled = true;
    _biometric = useBiometric;
    _hasUnlocked = true;
  }

  Future<void> disableLock() async {
    await _box?.delete(_kPinHash);
    await _box?.delete(_kBiometric);
    await _box?.delete(_kEnabled);
    _enabled = false;
    _biometric = false;
  }

  Future<bool> verifyPin(String pin) async {
    final stored = _box?.get(_kPinHash) as String?;
    if (stored == null) return false;
    final ok = _hashPin(pin) == stored;
    if (ok) {
      _hasUnlocked = true;
      await _markActive();
    }
    return ok;
  }

  Future<void> resetPin(String newPin) async {
    final hash = _hashPin(newPin);
    await _box?.put(_kPinHash, hash);
    _hasUnlocked = true;
    await _markActive();
  }

  Future<bool> authenticateBiometric() async {
    if (!_biometric) return false;
    try {
      debugPrint("AppLock: authenticateBiometric starting...");
      final ok = await _localAuth.authenticate(
        localizedReason: 'Unlock BillZap with your fingerprint',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      debugPrint("AppLock: authenticate result=$ok");
      if (ok) {
        _hasUnlocked = true;
        await _markActive();
      }
      return ok;
    } catch (e) {
      debugPrint("AppLock: auth exception: $e");
      // Retry without biometricOnly
      try {
        final ok = await _localAuth.authenticate(
          localizedReason: 'Unlock BillZap',
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
            useErrorDialogs: true,
          ),
        );
        if (ok) {
          _hasUnlocked = true;
          await _markActive();
        }
        return ok;
      } catch (e2) {
        debugPrint("AppLock: retry failed: $e2");
        return false;
      }
    }
  }

  Future<bool> shouldShowLock() async {
    if (!_enabled) return false;
    if (!_hasUnlocked) return true;
    final last = _box?.get(_kLastActive) as int?;
    if (last == null) return true;
    final lastDt = DateTime.fromMillisecondsSinceEpoch(last);
    final elapsed = DateTime.now().difference(lastDt);
    return elapsed > _relockAfter;
  }

  Future<void> markBackground() async {
    await _markActive();
  }

  Future<void> _markActive() async {
    await _box?.put(_kLastActive, DateTime.now().millisecondsSinceEpoch);
  }

  void forceLock() {
    _hasUnlocked = false;
  }
}
