// lib/design/motion.dart
//
// Motion primitives. Every animated behaviour in the app is composed
// from these, so timing and feel stay consistent instead of each screen
// inventing its own durations.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// Scales a child down slightly while pressed, then springs back.
///
/// This is the single highest-leverage "premium" detail in the app: a
/// surface that yields under the finger reads as a physical object.
/// Everything tappable that is larger than an icon uses it.
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// How far to compress. Large surfaces need less than small ones to
  /// read as the same amount of give.
  final double scale;

  /// Haptic fired on tap-down. Money-committing actions pass a heavier one.
  final HapticFeedbackType haptic;

  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.975,
    this.haptic = HapticFeedbackType.selection,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

enum HapticFeedbackType { none, selection, light, medium, heavy }

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _fire() {
    switch (widget.haptic) {
      case HapticFeedbackType.none:
        break;
      case HapticFeedbackType.selection:
        HapticFeedback.selectionClick();
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
      case HapticFeedbackType.medium:
        HapticFeedback.mediumImpact();
      case HapticFeedbackType.heavy:
        HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled
          ? (_) {
              _fire();
              setState(() => _down = true);
            }
          : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: _down ? AppMotion.fast : AppMotion.base,
        curve: _down ? AppMotion.standard : AppMotion.spring,
        child: widget.child,
      ),
    );
  }
}

/// Fades and lifts a child into place, optionally after a delay.
///
/// Give sequential list items an increasing [index] and the list arrives
/// as a cascade rather than all at once — the difference between a screen
/// that "appears" and one that "assembles".
class Entrance extends StatefulWidget {
  final Widget child;
  final int index;
  final double offset;
  final Duration duration;

  const Entrance({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 14,
    this.duration = AppMotion.slow,
  });

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    // Cap the cascade so a long list does not take a second to settle.
    final delay = AppMotion.stagger * widget.index.clamp(0, 8);
    Future.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: AppMotion.enter);
    return AnimatedBuilder(
      animation: curved,
      builder: (_, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - curved.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Crossfades between two children by size as well as opacity — used
/// where a skeleton gives way to real content, so the swap does not jump.
class SoftSwitch extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const SoftSwitch({super.key, required this.child, this.duration = AppMotion.base});

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: duration,
        switchInCurve: AppMotion.enter,
        switchOutCurve: AppMotion.exit,
        transitionBuilder: (c, a) => FadeTransition(
          opacity: a,
          child: SizeTransition(sizeFactor: a, axisAlignment: -1, child: c),
        ),
        child: child,
      );
}
