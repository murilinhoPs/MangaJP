import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/ocr_engine_chip.dart';
import 'cloud_vision_keys.dart';

/// Page-level chip: manga-ocr, Cloud Vision, or **misto**.
class OcrEngineChip extends StatelessWidget {
  const OcrEngineChip({super.key, required this.data});

  final OcrEngineChipData data;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final mixed = data.kind == OcrEngineChipKind.mixed;
    return Container(
      key: CloudVisionKeys.engineChip,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: mixed ? tokens.overlayPrimaria : tokens.surface,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: mixed ? tokens.coral : tokens.border),
      ),
      child: Text(
        data.label,
        style: AppTypeScale.metadados12.copyWith(
          color: mixed ? tokens.coralText : tokens.text2,
        ),
      ),
    );
  }
}
