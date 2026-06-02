// lib/utils/platform.dart
//
// Lightweight platform predicates used across the app. The Flutter
// codebase ships on Android + macOS (and later web/iOS/Windows). We
// gate features that aren't available on every platform here rather
// than scattering `Platform.isMacOS` checks throughout the UI.

import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class AppPlatform {
  AppPlatform._();

  /// True when running on a desktop OS (macOS / Windows / Linux).
  /// Used to switch between bottom-nav (mobile) and sidebar (desktop)
  /// layouts. Always false on web (we treat web like mobile for now).
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  /// True when running on Apple's desktop OS specifically. Used for the
  /// Liquid-Glass treatment which only ships on macOS today.
  static bool get isMacOS {
    if (kIsWeb) return false;
    return Platform.isMacOS;
  }

  /// True when voice billing is supported on the current platform. The
  /// `speech_to_text` plugin only ships iOS / Android / Web today, so we
  /// hide the Voice Bill entry on desktop builds rather than launching a
  /// dead-end screen.
  static bool get supportsVoiceBilling {
    if (kIsWeb) return true;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// True when the platform's biometric API works through `local_auth`.
  /// macOS Touch ID is supported; Windows/Linux are not.
  static bool get supportsBiometric {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  }
}
