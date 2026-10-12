import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Coral solid crop index (Home **Capturas recentes** and `/capture` overlay).
///
/// `fontSize: 9` is a DS value not in `tokens.json` (same as M1.21a).
class CropNumberBadge extends StatelessWidget {
  const CropNumberBadge({super.key, required this.number});

  final int number;

  static const double size = 18;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.coral,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        '$number',
        style: AppTypeScale.mono10.copyWith(
          color: tokens.onCoral,
          fontWeight: FontWeight.w700,
          fontSize: 9,
        ),
      ),
    );
  }
}
