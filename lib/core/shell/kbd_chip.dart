import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Visible shortcut chip (JetBrains Mono, `border-strong`, radius `tecla`).
///
/// [onPrimary] is for chips on a coral fill: `onCoral` text + a translucent
/// `onCoral` border so the keycap stays readable (not coral-on-coral).
class KbdChip extends StatelessWidget {
  const KbdChip({
    super.key,
    required this.label,
    this.emphasis = false,
    this.onPrimary = false,
  });

  final String label;
  final bool emphasis;
  final bool onPrimary;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final Color border;
    final Color color;
    if (onPrimary) {
      color = tokens.onCoral;
      border = tokens.onCoral.withValues(alpha: 0.4);
    } else if (emphasis) {
      border = tokens.coral;
      color = tokens.coralText;
    } else {
      border = tokens.borderStrong;
      color = tokens.text2;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.tecla),
        border: Border.all(color: border),
      ),
      child: Text(label, style: AppTypeScale.mono10.copyWith(color: color)),
    );
  }
}
