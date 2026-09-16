// Does the theme choice actually survive a restart?
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:billzap/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('billzap_theme');
    Hive.init(dir.path);
    await Hive.openBox('settings');
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('a chosen mode is written to the box', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(themeModeProvider), ThemeMode.system);

    await c.read(themeModeProvider.notifier).set(ThemeMode.light);
    expect(c.read(themeModeProvider), ThemeMode.light);
    expect(Hive.box('settings').get('theme_mode'), 'light');
  });

  test('a fresh container reads the stored mode back', () async {
    await Hive.box('settings').put('theme_mode', 'light');

    // Simulates app relaunch: brand new container, box already open the
    // way main() opens it before runApp.
    final c = ProviderContainer();
    addTearDown(c.dispose);

    final first = c.read(themeModeProvider);
    // Let any async load settle.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final after = c.read(themeModeProvider);

    // ignore: avoid_print
    print('first frame: $first, after load: $after');
    expect(after, ThemeMode.light,
        reason: 'the stored choice must survive a restart');
  });
}
