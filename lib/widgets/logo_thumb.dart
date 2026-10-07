// lib/widgets/logo_thumb.dart — the shop's logo, small.

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The logo on white, in both themes. Most logos are dark ink on a
/// transparent background; on the dark card they would vanish. White is
/// also what the logo sits on when it prints on the invoice, so this is
/// a faithful preview.
class LogoThumb extends StatelessWidget {
  final Uint8List bytes;
  final double size;
  const LogoThumb({super.key, required this.bytes, required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true),
      );
}
