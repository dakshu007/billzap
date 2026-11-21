// The landing page's functions talk to Neon through the serverless HTTP
// driver. 0.10.x predates the template-only query API and the 1.2.x
// pool/connection fixes, so the pin and the lockfile must move together.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('landing page is pinned to the current Neon serverless driver', () {
    final manifest = jsonDecode(
      File('landing-page/package.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final dependencies = manifest['dependencies'] as Map<String, dynamic>;
    expect(dependencies['@neondatabase/serverless'], '^1.2.1',
        reason: 'package.json should require the 1.2.x driver.');

    final lock = jsonDecode(
      File('landing-page/package-lock.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final packages = lock['packages'] as Map<String, dynamic>;
    final installed = packages['node_modules/@neondatabase/serverless']
        as Map<String, dynamic>;
    expect(installed['version'], '1.2.1',
        reason: 'the lockfile should install the 1.2.1 driver.');
  });
}
