// lib/design/nav_dock.dart
//
// The floating navigation dock.
//
// Two decisions worth naming:
//
//  * The active destination EXPANDS to show its label instead of every
//    tab carrying permanent text. Four always-on labels crowd the bar and
//    force tiny type; one label on the selected tab is bigger, easier to
//    read in sunlight, and the expansion itself signals what changed.
//
//  * The create action is a separate jade button sitting above the dock,
//    not a fifth tab. Billing is the reason the app exists — it should
//    not be one peer among five. It also lands in the natural thumb arc.

import 'package:flutter/material.dart';

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

class AppNavDock extends StatelessWidget {
  final int index;
  final List<NavDestination> destinations;
  final ValueChanged<int> onSelect;

  /// The primary action. Null hides the button entirely.
  final VoidCallback? onCreate;
  final IconData createIcon;
  final String createLabel;

  const AppNavDock({
    super.key,
    required this.index,
    required this.destinations,
    required this.onSelect,
    this.onCreate,
    this.createIcon = Icons.add_rounded,
    this.createLabel = 'New bill',
  });

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
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (onCreate != null)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.md),
              child: _CreateButton(
                  icon: createIcon, label: createLabel, onTap: onCreate!),
            ),
          ),
        Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: AppRadius.all(AppRadius.pill),
            border: Border.all(color: AppColor.hairline),
            boxShadow: AppElevation.lifted,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < destinations.length; i++)
                Flexible(
                  child: _DockItem(
                    destination: destinations[i],
                    selected: i == index,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _DockItem extends StatelessWidget {
  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  const _DockItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColor.primary : AppColor.textTertiary;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: PressScale(
        onTap: onTap,
        scale: 0.9,
        child: AnimatedContainer(
          duration: AppMotion.base,
          curve: AppMotion.standard,
          height: 46,
          padding: EdgeInsets.symmetric(horizontal: selected ? 14 : 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColor.wash(AppColor.primary)
                : Colors.transparent,
            borderRadius: AppRadius.all(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? destination.activeIcon : destination.icon,
                  size: 21, color: fg),
              // The label grows in rather than fading, so the selected
              // pill physically widens — the motion carries the meaning.
              ClipRect(
                child: AnimatedAlign(
                  duration: AppMotion.base,
                  curve: AppMotion.standard,
                  alignment: Alignment.centerLeft,
                  widthFactor: selected ? 1 : 0,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 7),
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: AppFont.style(AppType.labelM, color: fg),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The primary action.
///
/// A disc rather than a labelled pill: as a pill it sat over a cell of the
/// quick-action grid for the whole scroll, which looked like a layout bug.
/// The jade fill and glow already make it the loudest thing on screen, and
/// the label lives on as the semantic name and tooltip.
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
              width: 58,
              height: 58,
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
