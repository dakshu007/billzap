// lib/widgets/app_nav_dock.dart
//
// The floating navigation dock — the signature element of the redesign.
//
// A single ink-filled pill that hovers above the page with a soft shadow,
// holding four destinations plus the create action. The dock inverts with
// the theme: near-black on the light page, near-white on the dark one, with
// `onBrand` supplying the contrast for everything drawn on it.
//
// Selected destination  → icon at full contrast inside a soft halo
// Unselected            → the same icon at ~45% contrast
// Create                → a solid high-contrast circle, the one element
//                         that is always filled, so it never reads as
//                         "the selected tab"

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class AppNavDock extends StatelessWidget {
  final int idx;
  final VoidCallback onHome, onInvoices, onCreate, onReports, onMe;

  /// Icons are injected so the shell keeps ownership of the icon set.
  final IconData homeIcon, invoicesIcon, createIcon, reportsIcon, meIcon;

  /// Semantic labels — not painted (the dock is icon-only, like the
  /// reference), but exposed to screen readers.
  final String homeLabel, invoicesLabel, createLabel, reportsLabel, meLabel;

  /// `true` when the dock floats over the content (it is placed in a Stack
  /// by the caller) rather than sitting in `bottomNavigationBar`.
  final bool floating;

  const AppNavDock({
    super.key,
    required this.idx,
    required this.onHome,
    required this.onInvoices,
    required this.onCreate,
    required this.onReports,
    required this.onMe,
    required this.homeIcon,
    required this.invoicesIcon,
    required this.createIcon,
    required this.reportsIcon,
    required this.meIcon,
    required this.homeLabel,
    required this.invoicesLabel,
    required this.createLabel,
    required this.reportsLabel,
    required this.meLabel,
    this.floating = false,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final dock = AnimatedContainer(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeInOut,
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: AppShadow.float,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _DockItem(
              icon: homeIcon,
              label: homeLabel,
              selected: idx == 0,
              onTap: onHome),
          _DockItem(
              icon: invoicesIcon,
              label: invoicesLabel,
              selected: idx == 1,
              onTap: onInvoices),
          _DockCreate(
              icon: createIcon, label: createLabel, onTap: onCreate),
          _DockItem(
              icon: reportsIcon,
              label: reportsLabel,
              selected: idx == 2,
              onTap: onReports),
          _DockItem(
              icon: meIcon, label: meLabel, selected: idx == 3, onTap: onMe),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, floating ? 0 : 6, 20, bottomInset > 0 ? bottomInset + 6 : 18),
      child: dock,
    );
  }
}

class _DockItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DockItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final on = AppColors.onBrand;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        splashColor: on.withOpacity(0.10),
        highlightColor: on.withOpacity(0.06),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? on.withOpacity(0.14) : Colors.transparent,
          ),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            scale: selected ? 1.0 : 0.92,
            child: Icon(icon,
                size: 22, color: on.withOpacity(selected ? 1 : 0.45)),
          ),
        ),
      ),
    );
  }
}

/// The create action — the only permanently filled element in the dock, so
/// it never competes with the selected-tab halo.
class _DockCreate extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DockCreate({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.onBrand,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: AppColors.brand),
          ),
        ),
      );
}
