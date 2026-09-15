// lib/widgets/skeleton.dart
// Lightweight shimmer skeleton used while a list is loading for the
// first time. Pure Flutter, no external shimmer package needed.
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Skeleton extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  const Skeleton({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius,
  });

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(6);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: radius,
            // Token-driven so the shimmer follows the theme instead of
            // staying light-mode blue on a dark surface.
            gradient: LinearGradient(
              colors: [
                AppColors.inset,
                Color.alphaBlend(
                  AppColors.t4.withOpacity(0.10), AppColors.inset),
                AppColors.inset,
              ],
              begin: Alignment(-1 + t * 2, 0),
              end: Alignment(1 + t * 2, 0),
            ),
          ),
        );
      },
    );
  }
}

class SkeletonListItem extends StatelessWidget {
  const SkeletonListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.card,
        border: AppColors.isDark ? Border.all(color: AppColors.border) : null,
      ),
      child: Row(children: [
        Skeleton(
          width: 46,
          height: 46,
          borderRadius: BorderRadius.circular(16),
        ),
        const SizedBox(width: 13),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton(width: 140, height: 12),
              SizedBox(height: 6),
              Skeleton(width: 90, height: 10),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Skeleton(width: 60, height: 14),
            const SizedBox(height: 6),
            Skeleton(
              width: 44,
              height: 14,
              borderRadius: BorderRadius.circular(99),
            ),
          ],
        ),
      ]),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int count;
  final EdgeInsets padding;
  const SkeletonList({
    super.key,
    this.count = 6,
    this.padding = const EdgeInsets.fromLTRB(20, 14, 20, 124),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      itemCount: count,
      itemBuilder: (_, __) => const SkeletonListItem(),
    );
  }
}
