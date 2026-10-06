// lib/app_version.dart — which build is actually on this phone.
//
// This file exists because of a real support dead end. The About panel
// hardcoded the string '1.0.0', so when a tester installed a new APK
// and said "it still shows the old app", there was no way for anyone —
// them or me — to tell whether the install had actually replaced
// anything. The answer to "is this the new build?" has to be visible
// inside the app, or every future question like it is unanswerable.
//
// The build number is injected at compile time by the same CI step
// that bumps pubspec.yaml, so the number on this screen and the number
// in the artifact's filename cannot disagree:
//
//   flutter build apk --dart-define=BILLZAP_BUILD=260502277
//
// A local `flutter run` passes nothing and reads 'dev', which is the
// honest answer for a build that came off somebody's laptop.

/// The marketing version, matching pubspec.yaml's version name.
const String kVersionName = '1.0.0';

/// The build number CI stamped in, or 'dev' for a local build.
const String kBuildNumber =
    String.fromEnvironment('BILLZAP_BUILD', defaultValue: 'dev');

/// What the About panel shows: `1.0.0 (260502277)`.
///
/// The build number is the part that matters — the version name has
/// not changed since launch and will not tell anybody anything.
String get appVersionLabel => '$kVersionName ($kBuildNumber)';
