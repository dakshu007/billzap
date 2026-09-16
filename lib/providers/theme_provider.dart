// lib/providers/theme_provider.dart
// Persists the user's theme preference in Hive and keeps AppColors in
// sync so non-Material widgets (custom Containers etc.) pick up the
// right palette on next paint.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../theme/app_theme.dart';

const _kBox = 'settings';
const _kKey = 'theme_mode';

ThemeMode _decode(String? v) {
  switch (v) {
    case 'dark':  return ThemeMode.dark;
    case 'light': return ThemeMode.light;
    default:      return ThemeMode.system;
  }
}

String _encode(ThemeMode m) {
  switch (m) {
    case ThemeMode.dark:  return 'dark';
    case ThemeMode.light: return 'light';
    case ThemeMode.system: return 'system';
  }
}

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Read it here, synchronously, and return it as the initial value.
    //
    // This used to return ThemeMode.system and kick off an async load
    // that assigned `state` once the box resolved. The write worked, but
    // the value never came back on the next launch — so picking Light,
    // closing the app and reopening it landed you back on system
    // default. main() already awaits Hive.openBox('settings') before
    // runApp, so by the time anything reads this provider the box is
    // open and there is nothing to wait for.
    return _readStored() ?? ThemeMode.system;
  }

  ThemeMode? _readStored() {
    try {
      if (!Hive.isBoxOpen(_kBox)) return null;
      final raw = Hive.box(_kBox).get(_kKey);
      return raw is String ? _decode(raw) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    try {
      final box = Hive.isBoxOpen(_kBox)
          ? Hive.box(_kBox)
          : await Hive.openBox(_kBox);
      await box.put(_kKey, _encode(mode));
    } catch (_) {}
  }
}

final themeModeProvider =
    NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

/// Resolve a ThemeMode to a concrete brightness given the device's
/// platform brightness.
Brightness brightnessFor(ThemeMode mode, Brightness platform) {
  switch (mode) {
    case ThemeMode.dark:   return Brightness.dark;
    case ThemeMode.light:  return Brightness.light;
    case ThemeMode.system: return platform;
  }
}

/// Sync the static AppColors palette with the resolved brightness so the
/// next frame's custom widgets paint with the matching tokens.
void syncAppColors(Brightness b) {
  if (AppColors.mode != b) AppColors.setMode(b);
}
