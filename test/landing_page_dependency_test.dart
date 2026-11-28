// The landing page's functions talk to Neon through the serverless HTTP
// driver. 0.10.x predates the template-only query API, and 1.2.2 fixes
// Pool.query() over HTTP plus query/params encoding over HTTP, so the
// pin and the lockfile must move together.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('landing page is pinned to the current Neon serverless driver', () {
    final manifest = jsonDecode(
      File('landing-page/package.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final dependencies = manifest['dependencies'] as Map<String, dynamic>;
    expect(dependencies['@neondatabase/serverless'], '^1.2.2',
        reason: 'package.json should require the 1.2.2 driver.');

    final lock = jsonDecode(
      File('landing-page/package-lock.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final packages = lock['packages'] as Map<String, dynamic>;
    final installed = packages['node_modules/@neondatabase/serverless']
        as Map<String, dynamic>;
    expect(installed['version'], '1.2.2',
        reason: 'the lockfile should install the 1.2.2 driver.');
  });

  test('the HTTP driver call sites use the tagged-template API', () {
    final db = File('landing-page/functions/lib/db.js').readAsStringSync();

    // 1.2.2 rewrote Pool.query() over HTTP; this project never used a
    // Pool, it uses the neon() tagged template, which stays supported.
    expect(db, contains("import { neon } from '@neondatabase/serverless';"),
        reason: 'db.js should keep importing the neon factory.');
    expect(db, contains('neon(normaliseUrl(url))'),
        reason: 'the factory should still build the driver from the URL.');
    expect(db, isNot(contains('Pool.query')),
        reason: 'there is no Pool call site to migrate for 1.2.2.');
  });
}
