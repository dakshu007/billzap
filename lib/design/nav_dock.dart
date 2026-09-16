// lib/design/nav_dock.dart
//
// The navigation dock.
//
// Three behaviours carry the feel here, and all three are driven by the
// SAME continuous page offset rather than by discrete tab events:
//
//  1. THE BUBBLE follows the page. Swipe the pages and the indicator
//     travels with your finger in real time — it does not wait for the
//     page to settle and then jump. Because it is offset-driven it also
//     squashes and stretches in flight (a liquid "bubbly" travel) and
//     settles with a spring.
//
//  2. HOLD AND SWEEP. Press anywhere on the dock and slide, iOS-style,
//     and the selection tracks your finger across the slots with a
//     selection tick at each boundary. Lifting commits. This is much
//     faster than four separate taps once it is in muscle memory.
//
//  3. THE ACTIVE LABEL cross-fades in under the bubble, so only one
//     label is ever on screen. Four permanent labels crowd a 393pt bar
//     and force type down to a size that is hard to read in sunlight.

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'motion.dart';
import 'theme.dart';
import 'tokens.dart';

class NavDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const NavDestination({
    required this.icon,
    IconData? activeIcon,
    required this.label,
  }) : activeIcon = activeIcon ?? icon;
}

/// Height of the bar itself, excluding the outer margin.
const double kDockBarHeight = 68;

class AppNavDock extends StatefulWidget {
  final int index;
  final List<NavDestination> destinations;
  final ValueChanged<int> onSelect;

  /// Continuous page position from the shell's PageController — 1.42 means
  /// "42% of the way from Invoices to Reports". This is what makes the
  /// bubble track a swipe instead of snapping after it.
  final ValueListenable<double> offset;

  final VoidCallback? onCreate;
  final IconData createIcon;
  final String createLabel;

  const AppNavDock({
    super.key,
    required this.index,
    required this.destinations,
    required this.onSelect,
    required this.offset,
    this.onCreate,
    this.createIcon = Icons.add_rounded,
    this.createLabel = 'New bill',
  });

  @override
  State<AppNavDock> createState() => _AppNavDockState();
}

class _AppNavDockState extends State<AppNavDock> {
  /// Slot the finger is currently over during a hold-and-sweep, or null.
  int? _sweeping;

  int _slotAt(double dx, double width) {
    final slot = width / widget.destinations.length;
    return (dx / slot).floor().clamp(0, widget.destinations.length - 1);
  }

  void _sweepTo(int i) {
    if (_sweeping == i) return;
    HapticFeedback.selectionClick();
    setState(() => _sweeping = i);
    widget.onSelect(i);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.gutter,
        0,
        AppSpace.gutter,
        bottomInset > 0 ? bottomInset + AppSpace.sm : AppSpace.lg,
      ),
      child: Row(children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final width = box.maxWidth;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                // Hold-and-sweep. A tap is just a zero-distance sweep, so
                // both gestures fall out of the same handlers.
                onTapDown: (d) => _sweepTo(_slotAt(d.localPosition.dx, width)),
                onTapUp: (_) => setState(() => _sweeping = null),
                onTapCancel: () => setState(() => _sweeping = null),
                onHorizontalDragStart: (d) =>
                    _sweepTo(_slotAt(d.localPosition.dx, width)),
                onHorizontalDragUpdate: (d) =>
                    _sweepTo(_slotAt(d.localPosition.dx, width)),
                onHorizontalDragEnd: (_) => setState(() => _sweeping = null),
                onHorizontalDragCancel: () => setState(() => _sweeping = null),
                child: Container(
                  height: kDockBarHeight,
                  decoration: BoxDecoration(
                    color: AppColor.surface,
                    borderRadius: AppRadius.all(AppRadius.pill),
                    border: Border.all(color: AppColor.hairline),
                    boxShadow: AppElevation.lifted,
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadius.all(AppRadius.pill),
                    child: ValueListenableBuilder<double>(
                      valueListenable: widget.offset,
                      builder: (context, offset, _) => _DockContents(
                        offset: offset,
                        destinations: widget.destinations,
                        pressed: _sweeping,
                        width: width,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.onCreate != null) ...[
          const SizedBox(width: AppSpace.md),
          _CreateButton(
            icon: widget.createIcon,
            label: widget.createLabel,
            onTap: widget.onCreate!,
          ),
        ],
      ]),
    );
  }
}

class _DockContents extends StatelessWidget {
  final double offset;
  final List<NavDestination> destinations;
  final int? pressed;
  final double width;

  const _DockContents({
    required this.offset,
    required this.destinations,
    required this.pressed,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final n = destinations.length;
    final slot = width / n;

    // Distance from the nearest slot centre, 0 at rest and 0.5 mid-flight.
    // Everything that reacts to travel is derived from this one number.
    final travel = (offset - offset.roundToDouble()).abs() * 2;

    // Squash and stretch: the bubble elongates along its direction of
    // travel and thins slightly, the way a drop of liquid does, then
    // returns to a circle as it lands.
    final stretch = 1 + travel * 0.42;
    final squash = 1 - travel * 0.13;

    final bubbleW = math.min(slot - 10, 62.0);

    // The bubble is centred on its slot, but the stretch would push its
    // leading edge past the pill's rounded end on the first and last
    // slots. Clamping the centre keeps it inside the bar; at rest the
    // stretch is 1 and the clamp never bites, so the icon alignment is
    // untouched wherever it matters.
    const endInset = 5.0;
    final half = bubbleW * stretch / 2;
    final centre = (slot * (offset + 0.5))
        .clamp(endInset + half, math.max(endInset + half, width - endInset - half));

    return Stack(children: [
      // ── The bubble ────────────────────────────────────────────────
      Positioned(
        left: centre - bubbleW / 2,
        top: 0,
        bottom: 0,
        width: bubbleW,
        child: Center(
          child: Transform.scale(
            scaleX: stretch,
            scaleY: squash,
            child: Container(
              // Tall enough that the icon and the label sit inside it
              // with air around them; at 46 the label's descenders ran
              // right up against the edge.
              height: 50,
              decoration: BoxDecoration(
                color: AppColor.wash(AppColor.primary),
                borderRadius: AppRadius.all(AppRadius.pill),
              ),
            ),
          ),
        ),
      ),

      // ── Icons ─────────────────────────────────────────────────────
      Row(
        children: List.generate(n, (i) {
          // How "selected" this slot is, 1 at its centre and 0 once the
          // page has fully moved on. Tint, scale and label opacity all
          // read from it, so a swipe blends them continuously rather
          // than flipping at a threshold.
          final t = (1 - (offset - i).abs()).clamp(0.0, 1.0);
          final d = destinations[i];
          final held = pressed == i;

          return Expanded(
            child: Semantics(
              button: true,
              selected: t > 0.5,
              label: d.label,
              child: AnimatedScale(
                // A held slot dips under the finger, which is what makes
                // the sweep feel like it has physical detents.
                scale: held ? 0.9 : 1.0,
                duration: AppMotion.fast,
                curve: AppMotion.standard,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.scale(
                      scale: 1 + t * 0.08,
                      child: Icon(
                        t > 0.5 ? d.activeIcon : d.icon,
                        size: 22,
                        color: Color.lerp(
                            AppColor.textTertiary, AppColor.primary, t),
                      ),
                    ),
                    // The label occupies reserved height at all times, so
                    // fading it in never nudges the icons.
                    SizedBox(
                      height: 14,
                      child: Opacity(
                        // Sharpened so only the arriving label is legible;
                        // a linear fade leaves two ghosts mid-swipe.
                        opacity: (t * t * t).clamp(0.0, 1.0),
                        child: Text(
                          d.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFont.style(AppType.labelS,
                              color: AppColor.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    ]);
  }
}

/// The primary action — jade, glowing, and sitting beside the bar rather
/// than inside it, so it never competes with the destination bubble.
class _CreateButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CreateButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: Tooltip(
          message: label,
          child: PressScale(
            onTap: onTap,
            scale: 0.9,
            haptic: HapticFeedbackType.medium,
            child: Container(
              width: kDockBarHeight,
              height: kDockBarHeight,
              decoration: BoxDecoration(
                color: AppColor.primary,
                shape: BoxShape.circle,
                boxShadow: AppElevation.glow(AppColor.primary),
              ),
              child: Icon(icon, size: 26, color: AppColor.onPrimary),
            ),
          ),
        ),
      );
}

/// A fade that sits between scrolling content and the floating dock.
///
/// Without it a list row slides under the bar and its text pokes out
/// below, which reads as a clipping bug rather than as depth. The
/// gradient lets content dissolve into the page instead.
class DockScrim extends StatelessWidget {
  final double height;

  /// Taller than the dock on purpose. At 132 the fade only began level
  /// with the bar, so the last list row still met it at full opacity and
  /// came out sliced; the dissolve has to start well above the chrome.
  const DockScrim({super.key, this.height = 184});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: SizedBox(
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColor.canvas.withValues(alpha: 0),
                  AppColor.canvas.withValues(alpha: 0.75),
                  AppColor.canvas,
                  AppColor.canvas,
                ],
                stops: const [0.0, 0.40, 0.66, 1.0],
              ),
            ),
          ),
        ),
      );
}


/// The mirror of [DockScrim] for a transparent app bar.
///
/// A ListView that scrolls under a bare AppBar gets sliced by it — a row
/// of figures appears cut in half across the title. This dissolves the
/// content into the page tone instead, so the bar reads as floating over
/// depth rather than as a crop.
class TopScrim extends StatelessWidget {
  final double height;
  const TopScrim({super.key, this.height = 26});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Column(children: [
          Expanded(child: ColoredBox(color: AppColor.canvas)),
          SizedBox(
            height: height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColor.canvas,
                    AppColor.canvas.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ]),
      );
}
