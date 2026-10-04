import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/utils/hashing.dart';
import 'package:manga_jp/features/pages/data/pages_repository.dart';

import '../capture/fixture_png.dart';

void main() {
  test('saveRecognizedCrop persists OCR text on a crop row', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = PagesRepository(db);
    final png = fixturePng();

    final crop = await repo.saveRecognizedCrop(
      pageId: 'page-1',
      sourceSha256: sha256Hex(png),
      left: 0.2,
      top: 0.2,
      width: 0.6,
      height: 0.6,
      ocrText: 'よぉ、相棒',
      engineId: 'manga_ocr',
    );

    expect(crop.ocrText, 'よぉ、相棒');
    expect(crop.engineId, 'manga_ocr');

    final listed = await repo.listCrops();
    expect(listed, hasLength(1));
    expect(listed.single.ocrText, 'よぉ、相棒');
    expect(listed.single.pageId, 'page-1');

    final page = await repo.pageById('page-1');
    expect(page, isNotNull);
    expect(page!.sha256, sha256Hex(png));
  });
}
