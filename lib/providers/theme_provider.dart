// lib/providers/theme_provider.dart
// Persists the user's theme preference in Hive and keeps AppColors in
// sync so non-Material widgets (custom Containers etc.) pick up the
// right palette on next paint.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    try {
      final box = Hive.isBoxOpen(_kBox)
          ? Hive.box(_kBox)
          : await Hive.openBox(_kBox);
      final raw = box.get(_kKey) as String?;
      final mode = _decode(raw);
      if (mode != state) state = mode;
    } catch (_) {}
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

final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(),
);

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
