// test/dark_mode_surfaces_test.dart
//
// A bottom sheet hardcoded `color: Colors.white` while its labels used
// AppColors.t1, which is near-white in dark mode. The result was a
// white sheet of invisible text, and the only rows a tester could read
// were the greyed-out "not installed" ones, because grey happens to
// show up on white.
//
// It shipped in four places at once. That is the signature of a class
// of bug rather than one mistake, and the fix for a class is a test,
// not four careful edits. No widget test would have caught it either:
// white-on-white renders without error and satisfies every assertion
// anyone would think to write about layout.
//
// So this scans the source instead. A *surface* painted in a screen or
// widget has to take its colour from the theme. A *foreground* — a
// white icon or spinner sitting on a red delete swipe or a brand
// button — is fine, and the scan tells the two apart by resolving
// which constructor's argument list the colour sits in.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Constructors whose `color:` argument paints a surface behind other
/// widgets, rather than tinting the widget itself.
const _surfaceCtors = {
  'BoxDecoration',
  'ShapeDecoration',
  'DecoratedBox',
  'Container',
  'Material',
  'Card',
  'ColoredBox',
  'Scaffold',
  'AppBar',
};

/// Files allowed to paint a fixed surface, and why. The reason is the
/// point: an exception needs a justification a reader can check.
const _allowed = <String, String>{
  'lib/screens/invoice/invoice_preview_screen.dart':
      'The UPI QR code must be dark-on-white in both themes or scanners '
          'cannot read it. An earlier build used a theme colour here and '
          'made the code unscannable.',
  'lib/screens/invoice/create_invoice_screen.dart':
      'The toggle knob is white on both themes, riding on a tinted '
          'track. It is a control surface, not a background.',
  'lib/screens/festival/festival_greeting_screen.dart':
      'Translucent white over a fixed colour gradient, which does not '
          'change with the theme.',
  'lib/widgets/festival_banner.dart':
      'Translucent white over that same fixed gradient.',
};

/// The constructor whose argument list encloses [index], found by
/// walking back to the nearest unbalanced `(`.
String _enclosingConstructor(String source, int index) {
  var depth = 0;
  for (var i = index; i > 0; i--) {
    final c = source[i];
    if (c == ')') {
      depth++;
    } else if (c == '(') {
      if (depth == 0) {
        final before = source.substring(0, i);
        final m = RegExp(r'([A-Za-z_][A-Za-z0-9_]*)\s*$').firstMatch(before);
        return m?.group(1) ?? '';
      }
      depth--;
    }
  }
  return '';
}

void main() {
  test('no screen paints a surface the theme cannot change', () {
    final pattern = RegExp(
        r'\b(color|backgroundColor|fillColor)\s*:\s*Colors\.(white|black)\b');
    final offenders = <String>[];

    for (final dir in ['lib/screens', 'lib/widgets']) {
      for (final entity in Directory(dir).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (_allowed.containsKey(entity.path)) continue;

        final source = entity.readAsStringSync();
        for (final m in pattern.allMatches(source)) {
          final lineStart = source.lastIndexOf('\n', m.start) + 1;
          var lineEnd = source.indexOf('\n', m.start);
          if (lineEnd < 0) lineEnd = source.length;
          final line = source.substring(lineStart, lineEnd);

          if (line.trimLeft().startsWith('//')) continue;
          // A translucent overlay reads correctly over either theme.
          if (line.contains('withOpacity') || line.contains('withValues')) {
            continue;
          }
          // backgroundColor and fillColor are always a surface. A bare
          // `color:` only is when it sits in a surface constructor —
          // otherwise it is tinting an icon or some text.
          if (m.group(1) == 'color' &&
              !_surfaceCtors.contains(_enclosingConstructor(source, m.start))) {
            continue;
          }
          final lineNo = '\n'.allMatches(source.substring(0, m.start)).length + 1;
          offenders.add('${entity.path}:$lineNo  ${line.trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'These paint a fixed surface colour, so text drawn on them '
          'in theme colours vanishes in one of the two themes. Use '
          'AppColors.card or AppColors.bg, or add the file to _allowed '
          'in this test with the reason it must stay fixed:\n  '
          '${offenders.join('\n  ')}',
    );
  });

  test('the scan actually recognises a surface when it sees one', () {
    // A test that can only ever pass is not a test. This is the exact
    // shape of the bug that shipped.
    const bad = '''
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      )''';
    expect(_enclosingConstructor(bad, bad.indexOf('Colors.white')),
        'BoxDecoration');
  });

  test('and leaves a foreground colour alone', () {
    const fine = 'Icon(Symbols.delete, color: Colors.white, size: 20)';
    expect(_enclosingConstructor(fine, fine.indexOf('Colors.white')), 'Icon');

    const spinner = 'CircularProgressIndicator(color: Colors.white)';
    expect(_enclosingConstructor(spinner, spinner.indexOf('Colors.white')),
        'CircularProgressIndicator');
  });

  test('every allowance names a file that still exists', () {
    // An allowance for a renamed file is a hole that looks like
    // coverage.
    for (final path in _allowed.keys) {
      expect(File(path).existsSync(), isTrue,
          reason: '$path is allowlisted but does not exist');
    }
  });
}
