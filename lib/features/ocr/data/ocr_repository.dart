import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/cloud_vision_exception.dart';
import '../domain/ocr_engine.dart';
import '../domain/ocr_result.dart';
import 'cloud_vision_ocr_engine.dart';
import 'cloud_vision_shot.dart';
import 'cloud_vision_store.dart';
import 'crop_ocr_outcome.dart';
import 'manga_ocr_engine.dart';
import 'manga_ocr_url.dart';

part 'ocr_repository.g.dart';

/// Default OCR is the manga-ocr sidecar (`docs/m0.3-cer-bakeoff.md`, 20.75% CER).
@Riverpod(keepAlive: true)
OcrEngine ocrEngine(Ref ref) {
  final url = mangaOcrUrl();
  return MangaOcrEngine(
    baseUrl: (url == null || url.isEmpty) ? MangaOcrEngine.defaultBaseUrl : url,
  );
}

@Riverpod(keepAlive: true)
CloudVisionStore cloudVisionStore(Ref ref) {
  final shot = cloudVisionShotStore();
  if (shot != null) {
    return shot;
  }
  if (_useMemoryStoreInTests) {
    return MemoryCloudVisionStore();
  }
  return FlutterCloudVisionStore();
}

/// Widget/unit tests have no Keychain/libsecret; never hang on a platform channel.
bool get _useMemoryStoreInTests {
  try {
    return WidgetsBinding.instance.runtimeType.toString().contains('Test');
  } catch (_) {
    return true;
  }
}

@Riverpod(keepAlive: true)
CloudVisionOcrEngine cloudVisionOcrEngine(Ref ref) {
  final store = ref.watch(cloudVisionStoreProvider);
  return CloudVisionOcrEngine(readApiKey: store.readApiKey);
}

@Riverpod(keepAlive: true)
OcrRepository ocrRepository(Ref ref) {
  return OcrRepository(
    ref.watch(ocrEngineProvider),
    cloud: ref.watch(cloudVisionOcrEngineProvider),
    store: ref.watch(cloudVisionStoreProvider),
  );
}

class OcrRepository {
  const OcrRepository(this.engine, {this.cloud, this.store});

  final OcrEngine engine;
  final CloudVisionOcrEngine? cloud;
  final CloudVisionStore? store;

  Future<OcrResult> recognize(Uint8List image) async {
    return (await recognizeCrop(image)).result;
  }

  /// Tries Cloud Vision first when the toggle is on and a key exists.
  /// 401/403, 429, network, timeout, missing key: that crop uses [engine].
  Future<CropOcrOutcome> recognizeCrop(Uint8List image) async {
    final cloudEngine = cloud;
    final settings = store;
    if (cloudEngine != null && settings != null && await settings.isEnabled) {
      try {
        final result = await cloudEngine.recognize(image);
        return CropOcrOutcome(result: result);
      } on CloudVisionException catch (error) {
        if (error.fallsBackToLocal) {
          final local = await engine.recognize(image);
          return CropOcrOutcome(result: local, fallback: error);
        }
        rethrow;
      }
    }
    return CropOcrOutcome(result: await engine.recognize(image));
  }
}
