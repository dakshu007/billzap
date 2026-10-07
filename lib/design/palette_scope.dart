// lib/design/palette_scope.dart — makes a theme change reach every screen.
//
// THE BUG THIS FIXES
//
// Most of the app paints with the static token getters in tokens.dart
// (AppColor.canvas, AppColors.card, ...), not with Theme.of(context).
// A static getter is not an InheritedWidget, so reading one registers
// no dependency: when the palette flips, Flutter has no idea which
// widgets used the old colours and rebuilds none of them. Only widgets
// that happened to rebuild for some other reason — the theme tile,
// which watches the provider — picked up the new palette. Everything
// else stayed in the old one until the user switched tabs and forced a
// rebuild, which is exactly what the screenshot showed: a dark Theme
// tile on an otherwise light page.
//
// THE FIX
//
// PaletteScope sits just under MaterialApp. When the resolved
// brightness changes it marks every element below it dirty, in the same
// frame, so every build method re-reads the tokens. State is kept —
// nothing is re-keyed, no form loses what was typed, no scroll position
// jumps. It also covers the system dark-mode toggle, which arrives the
// same way.
//
// To make the change read as a transition rather than a hard cut,
// switchThemeMode() takes a picture of the current frame first, applies
// the new mode underneath it, and fades the picture out.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_provider.dart';
import 'tokens.dart';

final GlobalKey _boundaryKey = GlobalKey(debugLabel: 'palette-boundary');
final ValueNotifier<ui.Image?> _snapshot = ValueNotifier<ui.Image?>(null);

/// Change the theme with a cross-fade. Safe to call from anywhere that
/// has a ref; if the snapshot cannot be taken the mode still changes,
/// just without the fade.
Future<void> switchThemeMode(WidgetRef ref, ThemeMode mode) async {
  if (ref.read(themeModeProvider) == mode) return;
  ui.Image? image;
  try {
    final boundary = _boundaryKey.currentContext?.findRenderObject();
    if (boundary is RenderRepaintBoundary) {
      final ctx = _boundaryKey.currentContext!;
      final dpr = MediaQuery.maybeDevicePixelRatioOf(ctx) ?? 1.0;
      image = await boundary.toImage(pixelRatio: dpr);
    }
  } catch (_) {
    image = null;
  }
  final old = _snapshot.value;
  _snapshot.value = image;
  old?.dispose();
  await ref.read(themeModeProvider.notifier).set(mode);
}

class PaletteScope extends StatefulWidget {
  final Brightness brightness;

  /// The language on screen. Most strings are looked up with trGlobal(),
  /// which — exactly like the static colour tokens — registers no
  /// dependency, so a language change has the same problem a theme
  /// change had and gets the same fix.
  final String language;
  final Widget child;
  const PaletteScope({
    super.key,
    required this.brightness,
    required this.language,
    required this.child,
  });

  @override
  State<PaletteScope> createState() => _PaletteScopeState();
}

class _PaletteScopeState extends State<PaletteScope>
    with SingleTickerProviderStateMixin {
  late Brightness _painted = widget.brightness;
  late String _language = widget.language;
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: AppMotion.theme,
  );

  @override
  void initState() {
    super.initState();
    _snapshot.addListener(_onSnapshot);
  }

  @override
  void dispose() {
    _snapshot.removeListener(_onSnapshot);
    _fade.dispose();
    super.dispose();
  }

  void _onSnapshot() {
    if (!mounted) return;
    if (_snapshot.value == null) return;
    // Full opacity: the picture covers the screen until the new palette
    // has been built underneath it.
    _fade.value = 0;
    setState(() {});
    // If the chosen mode resolves to the brightness already on screen
    // (Light -> System on a light phone) nothing below will start the
    // fade, so drop the picture rather than leave it covering the app.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _fade.isAnimating) return;
      _snapshot.value?.dispose();
      _snapshot.value = null;
      setState(() {});
    });
  }

  void _rebuildEverything() {
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    (context as Element).visitChildren(mark);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.language != _language) {
      _language = widget.language;
      if (widget.brightness == _painted) _rebuildEverything();
    }
    if (widget.brightness != _painted) {
      _painted = widget.brightness;
      // Every descendant re-reads the static tokens in this same frame.
      // Marking descendants dirty during our own build is allowed: they
      // are below the current build target, so they are built later in
      // this pass rather than in the next frame.
      _rebuildEverything();
      if (_snapshot.value != null) {
        _fade.forward(from: 0).whenComplete(() {
          if (!mounted) return;
          _snapshot.value?.dispose();
          _snapshot.value = null;
          setState(() {});
        });
      }
    }

    final image = _snapshot.value;
    return Stack(
      textDirection: TextDirection.ltr,
      fit: StackFit.expand,
      children: [
        RepaintBoundary(key: _boundaryKey, child: widget.child),
        if (image != null)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _fade,
                builder: (_, __) => Opacity(
                  // Holds at full while the new frame builds underneath,
                  // then dissolves.
                  opacity: 1 - Curves.easeOutCubic.transform(_fade.value),
                  child: RawImage(
                    image: image,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
