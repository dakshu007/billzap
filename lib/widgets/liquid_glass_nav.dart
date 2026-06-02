// lib/widgets/liquid_glass_nav.dart
//
// A floating "Liquid Glass" bottom navigation bar, Apple-style.
//
// What makes it feel liquid / glassy:
//   * Floats above the bottom edge as a rounded capsule (not docked).
//   * BackdropFilter blurs whatever scrolls behind it — real frosted
//     glass, not a flat fill.
//   * A specular top-edge highlight + soft outer shadow mimic light
//     catching the rim of a glass slab.
//   * The active-tab indicator is a soft brand-tinted "blob" that
//     springs between slots with an easeOutBack overshoot — the bouncy
//     settle reads as a liquid droplet snapping into place.
//   * The centre Create button is a raised, glowing gradient circle
//     that floats slightly proud of the bar.
//
// Drop-in compatible with the old _BmwNav: same idx + 5 callbacks.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../theme/app_theme.dart';
import '../i18n/translations.dart';

class LiquidGlassNav extends ConsumerWidget {
  final int idx;
  final VoidCallback onHome, onInvoices, onCreate, onReports, onMe;
  const LiquidGlassNav({
    super.key,
    required this.idx,
    required this.onHome,
    required this.onInvoices,
    required this.onCreate,
    required this.onReports,
    required this.onMe,
  });

  // The bar has 5 visual slots: Home(0) Invoices(1) Create(2) Reports(3)
  // Me(4). But the tab *index* only counts the four real tabs
  // (Home0 Invoices1 Reports2 Me3) — Create pushes a route, it's not a
  // tab. So map the active tab index onto its visual slot, skipping the
  // centre Create slot.
  int _slotForIndex(int i) => i < 2 ? i : i + 1;

  // Slot centre as Alignment.x (−1..1) for a 5-column bar.
  double _alignX(int slot) => (2 * slot - 4) / 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = AppColors.isDark;

    return Padding(
      // Float above the home-indicator / bottom edge.
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, MediaQuery.of(context).padding.bottom + 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              // Translucent glass fill — lets the blurred content tint
              // through. Slightly more opaque in light mode so the cream
              // reads cleanly; darker + dimmer at night.
              color: (dark ? const Color(0xFF141B2A) : Colors.white)
                  .withOpacity(dark ? 0.55 : 0.66),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(dark ? 0.08 : 0.6),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(dark ? 0.45 : 0.14),
                  blurRadius: 28,
                  spreadRadius: -4,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Specular sheen across the top third (glass rim) ──
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(dark ? 0.10 : 0.45),
                            Colors.white.withOpacity(0.0),
                          ],
                          stops: const [0.0, 0.55],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── The liquid blob behind the active tab ──
                // Hidden when the Create button (slot 2) is "active",
                // which never happens since Create pushes a route.
                AnimatedAlign(
                  duration: const Duration(milliseconds: 440),
                  curve: Curves.easeOutBack, // overshoot = liquid settle
                  alignment: Alignment(_alignX(_slotForIndex(idx)), 0),
                  child: FractionallySizedBox(
                    widthFactor: 1 / 5,
                    child: Center(
                      child: _LiquidBlob(dark: dark),
                    ),
                  ),
                ),

                // ── The five slots ──
                Row(children: [
                  _Tab(
                    icon: Symbols.home,
                    label: tr('nav.home', ref),
                    active: idx == 0,
                    onTap: onHome),
                  _Tab(
                    icon: Symbols.receipt_long,
                    label: tr('nav.invoices', ref),
                    active: idx == 1,
                    onTap: onInvoices),
                  _CreateButton(onTap: onCreate),
                  _Tab(
                    icon: Symbols.bar_chart,
                    label: tr('nav.reports', ref),
                    active: idx == 2,
                    onTap: onReports),
                  _Tab(
                    icon: Symbols.person,
                    label: tr('nav.me', ref),
                    active: idx == 3,
                    onTap: onMe),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// The soft brand-tinted droplet that sits behind the active tab.
class _LiquidBlob extends StatelessWidget {
  final bool dark;
  const _LiquidBlob({required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.brand.withOpacity(dark ? 0.42 : 0.20),
            AppColors.brand.withOpacity(dark ? 0.16 : 0.08),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withOpacity(dark ? 0.30 : 0.22),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon springs up slightly + recolors when active.
            AnimatedScale(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              scale: active ? 1.14 : 1.0,
              child: Icon(
                icon,
                size: 23,
                color: active ? AppColors.brand : AppColors.t3,
                fill: active ? 1 : 0,
              ),
            ),
            const SizedBox(height: 2),
            // Label fades + bolds for the active tab.
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 240),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                color: active ? AppColors.brand : AppColors.t3,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CreateButton({required this.onTap});

  @override
  State<_CreateButton> createState() => _CreateButtonState();
}

class _CreateButtonState extends State<_CreateButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: () {
            HapticFeedback.mediumImpact();
            widget.onTap();
          },
          child: AnimatedScale(
            duration: const Duration(milliseconds: 130),
            scale: _pressed ? 0.9 : 1.0,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.brand, Color(0xFF4070FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withOpacity(0.5),
                    blurRadius: 18,
                    spreadRadius: -2,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.35),
                  width: 1,
                ),
              ),
              child: const Icon(Symbols.add, color: Colors.white, size: 27),
            ),
          ),
        ),
      ),
    );
  }
}
