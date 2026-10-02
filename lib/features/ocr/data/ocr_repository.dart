import 'dart:typed_data';

import '../domain/ocr_engine.dart';
import '../domain/ocr_result.dart';

class OcrRepository {
  const OcrRepository(this.engine);

  final OcrEngine engine;

  Future<OcrResult> recognize(Uint8List image) => engine.recognize(image);
}
