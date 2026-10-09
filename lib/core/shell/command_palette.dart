import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'shell_layout.dart';

Future<void> showCommandPalette(
  BuildContext context, {
  required List<PaletteAction> items,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final tokens = dialogContext.tokens;
      return Dialog(
        key: ShellKeys.palette,
        backgroundColor: tokens.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: tokens.border),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Comandos',
                  style: AppTypeScale.ui14.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final item in items)
                      ListTile(
                        key: ShellKeys.paletteItem(item.id),
                        title: Text(item.label, style: AppTypeScale.ui14),
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          item.run(context);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
