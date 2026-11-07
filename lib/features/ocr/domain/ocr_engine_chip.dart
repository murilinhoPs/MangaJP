import 'cloud_vision_labels.dart';
import 'ocr_engine_ids.dart';

/// Page-level OCR engine chip: one engine, or mixed when crops differ.
enum OcrEngineChipKind { mangaOcr, cloudVision, mixed, other }

final class OcrEngineChipData {
  const OcrEngineChipData({required this.kind, required this.label});

  final OcrEngineChipKind kind;
  final String label;

  static OcrEngineChipData? of(Iterable<String> engineIds) {
    final unique = <String>{};
    for (final id in engineIds) {
      if (id.isNotEmpty) {
        unique.add(id);
      }
    }
    if (unique.isEmpty) {
      return null;
    }
    if (unique.length > 1) {
      return const OcrEngineChipData(
        kind: OcrEngineChipKind.mixed,
        label: CloudVisionLabels.chipMixed,
      );
    }
    final id = unique.single;
    return switch (id) {
      OcrEngineIds.mangaOcr => const OcrEngineChipData(
        kind: OcrEngineChipKind.mangaOcr,
        label: CloudVisionLabels.chipMangaOcr,
      ),
      OcrEngineIds.cloudVision => const OcrEngineChipData(
        kind: OcrEngineChipKind.cloudVision,
        label: CloudVisionLabels.chipCloudVision,
      ),
      _ => OcrEngineChipData(kind: OcrEngineChipKind.other, label: id),
    };
  }
}
