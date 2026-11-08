import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/features/ocr/domain/cloud_vision_labels.dart';
import 'package:manga_jp/features/ocr/domain/ocr_engine_chip.dart';
import 'package:manga_jp/features/ocr/domain/ocr_engine_ids.dart';

void main() {
  test('empty crops have no chip', () {
    expect(OcrEngineChipData.of(const []), isNull);
  });

  test('one engine is manga-ocr or Cloud Vision', () {
    expect(
      OcrEngineChipData.of(const [OcrEngineIds.mangaOcr])!.label,
      CloudVisionLabels.chipMangaOcr,
    );
    expect(
      OcrEngineChipData.of(const [
        OcrEngineIds.cloudVision,
        OcrEngineIds.cloudVision,
      ])!.label,
      CloudVisionLabels.chipCloudVision,
    );
  });

  test('differing crops are misto', () {
    final chip = OcrEngineChipData.of(const [
      OcrEngineIds.mangaOcr,
      OcrEngineIds.cloudVision,
    ]);
    expect(chip!.kind, OcrEngineChipKind.mixed);
    expect(chip.label, CloudVisionLabels.chipMixed);
  });
}
