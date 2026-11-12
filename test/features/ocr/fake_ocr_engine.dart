import 'dart:typed_data';

import 'package:manga_jp/features/ocr/domain/ocr_engine.dart';
import 'package:manga_jp/features/ocr/domain/ocr_result.dart';

/// Test double for [OcrEngine]. Default app wiring stays [MangaOcrEngine].
class FakeOcrEngine implements OcrEngine {
  const FakeOcrEngine({
    this.text = 'よぉ、相棒',
    this.id = 'fake',
    this.error,
    this.blocks,
  });

  final String text;
  final String id;
  final Object? error;
  final List<OcrBlock>? blocks;

  @override
  String get engineId => id;

  @override
  Future<OcrResult> recognize(Uint8List image) async {
    final thrown = error;
    if (thrown != null) {
      throw thrown;
    }
    return OcrResult(
      fullText: text,
      blocks: blocks ?? [OcrBlock(text: text)],
      engineId: id,
    );
  }
}
