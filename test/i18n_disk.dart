// test/i18n_disk.dart — the translation files, read straight off disk.
//
// A plain unit test has no asset bundle, so the app's own loader cannot
// reach assets/i18n. These helpers read the same files with dart:io and
// hand them to the lookup layer, so the tests check exactly what ships.

import 'dart:convert';
import 'dart:io';

import 'package:billzap/i18n/translations.dart';

/// Language ids that have a file in assets/i18n, sorted.
List<String> translationFilesOnDisk() {
  final dir = Directory('assets/i18n');
  if (!dir.existsSync()) return const [];
  return dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .map((f) => f.uri.pathSegments.last.replaceAll('.json', ''))
      .toList()
    ..sort();
}

/// One file's strings, decoded.
Map<String, dynamic> readTranslationFile(String id) =>
    jsonDecode(File('assets/i18n/$id.json').readAsStringSync())
        as Map<String, dynamic>;

/// Load every file into the lookup layer.
void registerAllTranslationsFromDisk() {
  for (final id in translationFilesOnDisk()) {
    final raw = readTranslationFile(id);
    registerTranslations(id, {
      for (final e in raw.entries)
        if (e.value is String) e.key: e.value as String,
    });
  }
}

/// The {name} placeholders in a string, as a sorted list.
List<String> placeholdersIn(String s) =>
    RegExp(r'\{([a-z]+)\}').allMatches(s).map((m) => m.group(1)!).toList()
      ..sort();
