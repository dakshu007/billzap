// test/app_version_test.dart
//
// The About panel showed a hardcoded '1.0.0', so when a tester
// installed a new APK and reported "it still shows the old app",
// nobody could tell whether the install had replaced anything. These
// assert the label stays answerable.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:billzap/app_version.dart';

void main() {
  test('the label carries the build number, not just the version name',
      () {
    // 'dev' under `flutter test`, because no --dart-define is passed —
    // which is itself the right answer for a local build.
    expect(appVersionLabel, '$kVersionName ($kBuildNumber)');
    expect(appVersionLabel, contains(kBuildNumber));
    expect(appVersionLabel, isNot(kVersionName),
        reason: 'a bare version name is what made this unanswerable');
  });

  test('a local build says dev rather than claiming a CI build number',
      () {
    expect(kBuildNumber, 'dev');
  });

  test('the version name matches pubspec, so the two cannot drift', () {
    // Reading pubspec directly: a comment saying "keep these in sync"
    // is not a mechanism.
    final pubspec = File('pubspec.yaml').readAsLinesSync();
    final line = pubspec.firstWhere((l) => l.startsWith('version:'));
    final name = line.split(':')[1].trim().split('+').first;
    expect(kVersionName, name,
        reason: 'lib/app_version.dart disagrees with pubspec.yaml');
  });
}
