import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Crop index badge. Coral on `/capture`; Home thumbs use [neutral].
///
/// `fontSize: 9` is a DS value not in `tokens.json` (same as M1.21a).
class CropNumberBadge extends StatelessWidget {
  const CropNumberBadge({
    super.key,
    required this.number,
    this.neutral = false,
  });

  final int number;
  final bool neutral;

  static const double size = 18;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: neutral ? tokens.surfaceRaised : tokens.coral,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: neutral ? Border.all(color: tokens.border) : null,
      ),
      child: Text(
        '$number',
        style: AppTypeScale.mono10.copyWith(
          color: neutral ? tokens.text : tokens.onCoral,
          fontWeight: FontWeight.w700,
          fontSize: 9,
        ),
      ),
    );
  }
}
