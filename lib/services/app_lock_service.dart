// lib/services/app_lock_service.dart
// Handles PIN authentication, biometric, and app lifecycle tracking.
//
// Design principles:
// - PIN is NEVER stored in plaintext. Only SHA-256 hash with salt.
// - Settings stored in flutter_secure_storage (Android Keystore-backed).
// - Tracks lastActiveAt timestamp to decide if app should re-lock on foreground.
// - Singleton pattern matching existing services.
//
// Storage keys (in secure storage):
//   pin_hash     → hex string of SHA-256(salt + pin)
//   biometric    → 'true' / 'false'
//   enabled      → 'true' / 'false'
//
// Storage keys (in normal Hive box for non-secret stuff):
//   last_active_at → ms since epoch (when app was last in foreground)

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppLockService {
  AppLockService._();
  static final AppLockService instance = AppLockService._();

  static const _kPinHash = 'pin_hash';
  static const _kBiometric = 'biometric';
  static const _kEnabled = 'enabled';
  static const _kLastActive = 'lock_last_active_at';
  static const _salt = 'billzap_app_lock_v1';

  // Re-lock threshold: 60 seconds of background = require unlock again
  static const Duration _relockAfter = Duration(seconds: 60);

  final _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final _localAuth = LocalAuthentication();
  Box? _box; // for last_active_at (not secret)

  bool _initialised = false;
  bool _enabled = false;
  bool _biometric = false;
  bool _hasUnlocked = false; // session flag — true after successful unlock

  Future<void> init() async {
    if (_initialised) return;
    _box = await Hive.openBox('billzap_v1');
    _enabled = (await _secure.read(key: _kEnabled)) == 'true';
    _biometric = (await _secure.read(key: _kBiometric)) == 'true';
    _initialised = true;
  }

  bool get isEnabled => _enabled;
  bool get isBiometricEnabled => _biometric;
  bool get hasUnlockedThisSession => _hasUnlocked;

  /// Returns true if the device supports biometric authentication.
  Future<bool> canUseBiometric() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!canCheck || !isSupported) return false;
      // Check there's at least one biometric enrolled (fingerprint specifically)
      final available = await _localAuth.getAvailableBiometrics();
      // We accept fingerprint OR strong (which includes fingerprint on Android)
      return available.contains(BiometricType.fingerprint) ||
             available.contains(BiometricType.strong);
    } catch (_) {
      return false;
    }
  }

  /// Hash a PIN with salt for safe storage.
  String _hashPin(String pin) {
    final bytes = utf8.encode(_salt + pin);
    return sha256.convert(bytes).toString();
  }

  /// Set up app lock with PIN. Optionally enable biometric.
  Future<void> enableLock({required String pin, required bool useBiometric}) async {
    final hash = _hashPin(pin);
    await _secure.write(key: _kPinHash, value: hash);
    await _secure.write(key: _kBiometric, value: useBiometric.toString());
    await _secure.write(key: _kEnabled, value: 'true');
    _enabled = true;
    _biometric = useBiometric;
    _hasUnlocked = true; // Just set it up — they're already in
  }

  /// Disable app lock entirely. Wipes PIN and biometric setting.
  Future<void> disableLock() async {
    await _secure.delete(key: _kPinHash);
    await _secure.delete(key: _kBiometric);
    await _secure.delete(key: _kEnabled);
    _enabled = false;
    _biometric = false;
  }

  /// Verify a PIN. Returns true if matches stored hash.
  Future<bool> verifyPin(String pin) async {
    final stored = await _secure.read(key: _kPinHash);
    if (stored == null) return false;
    final ok = _hashPin(pin) == stored;
    if (ok) {
      _hasUnlocked = true;
      await _markActive();
    }
    return ok;
  }

  /// Update PIN (used after Forgot PIN recovery flow).
  /// Caller MUST have validated user's identity (e.g. via backup file restore).
  Future<void> resetPin(String newPin) async {
    final hash = _hashPin(newPin);
    await _secure.write(key: _kPinHash, value: hash);
    _hasUnlocked = true;
    await _markActive();
  }

  /// Trigger biometric prompt. Returns true if succeeded.
  Future<bool> authenticateBiometric() async {
    if (!_biometric) return false;
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'Unlock BillZap with your fingerprint',
        options: const AuthenticationOptions(
          biometricOnly: true,    // we want fingerprint only, no device PIN fallback
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      if (ok) {
        _hasUnlocked = true;
        await _markActive();
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// Should the lock screen be shown right now when app comes to foreground?
  /// True if:
  ///  - Lock is enabled
  ///  - User hasn't unlocked this session, OR
  ///  - More than 60 seconds since last activity
  Future<bool> shouldShowLock() async {
    if (!_enabled) return false;
    if (!_hasUnlocked) return true; // First open since cold start
    final last = _box?.get(_kLastActive) as int?;
    if (last == null) return true;
    final lastDt = DateTime.fromMillisecondsSinceEpoch(last);
    final elapsed = DateTime.now().difference(lastDt);
    return elapsed > _relockAfter;
  }

  /// Called when app goes to background or user unlocks.
  Future<void> markBackground() async {
    await _markActive();
    // Don't reset _hasUnlocked here — it gets reset on next foreground if too much time passed
  }

  Future<void> _markActive() async {
    await _box?.put(_kLastActive, DateTime.now().millisecondsSinceEpoch);
  }

  /// Force re-lock (called on disable + re-enable, or when user explicitly locks).
  void forceLock() {
    _hasUnlocked = false;
  }
}
