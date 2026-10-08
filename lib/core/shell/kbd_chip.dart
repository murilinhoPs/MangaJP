import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Visible shortcut chip (JetBrains Mono, `border-strong`, radius `tecla`).
class KbdChip extends StatelessWidget {
  const KbdChip({super.key, required this.label, this.emphasis = false});

  final String label;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final border = emphasis ? tokens.coral : tokens.borderStrong;
    final color = emphasis ? tokens.coralText : tokens.text2;
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
