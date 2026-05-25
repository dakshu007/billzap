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
            gradient: LinearGradient(
              colors: const [
                Color(0xFFEDF1F8),
                Color(0xFFF7F9FC),
                Color(0xFFEDF1F8),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Skeleton(
          width: 40,
          height: 40,
          borderRadius: BorderRadius.circular(10),
        ),
        const SizedBox(width: 12),
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
    this.padding = const EdgeInsets.fromLTRB(12, 10, 12, 100),
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
