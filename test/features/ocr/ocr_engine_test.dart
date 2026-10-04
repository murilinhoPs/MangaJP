import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/features/ocr/data/manga_ocr_engine.dart';
import 'package:manga_jp/features/ocr/data/ocr_repository.dart';

void main() {
  test('default OcrEngine is the manga-ocr local sidecar', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final engine = container.read(ocrEngineProvider);
    expect(engine, isA<MangaOcrEngine>());
    expect(engine.engineId, 'manga_ocr');
    expect(container.read(ocrRepositoryProvider).engine, same(engine));
  });
}
