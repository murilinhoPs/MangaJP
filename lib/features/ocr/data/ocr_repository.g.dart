// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ocr_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Default OCR is the manga-ocr sidecar (`docs/m0.3-cer-bakeoff.md`, 20.75% CER).

@ProviderFor(ocrEngine)
final ocrEngineProvider = OcrEngineProvider._();

/// Default OCR is the manga-ocr sidecar (`docs/m0.3-cer-bakeoff.md`, 20.75% CER).

final class OcrEngineProvider
    extends $FunctionalProvider<OcrEngine, OcrEngine, OcrEngine>
    with $Provider<OcrEngine> {
  /// Default OCR is the manga-ocr sidecar (`docs/m0.3-cer-bakeoff.md`, 20.75% CER).
  OcrEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ocrEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ocrEngineHash();

  @$internal
  @override
  $ProviderElement<OcrEngine> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OcrEngine create(Ref ref) {
    return ocrEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OcrEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OcrEngine>(value),
    );
  }
}

String _$ocrEngineHash() => r'18187ab2f1a4c6e521f2b521b19649d8b1b6c2d1';

@ProviderFor(ocrRepository)
final ocrRepositoryProvider = OcrRepositoryProvider._();

final class OcrRepositoryProvider
    extends $FunctionalProvider<OcrRepository, OcrRepository, OcrRepository>
    with $Provider<OcrRepository> {
  OcrRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ocrRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ocrRepositoryHash();

  @$internal
  @override
  $ProviderElement<OcrRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OcrRepository create(Ref ref) {
    return ocrRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OcrRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OcrRepository>(value),
    );
  }
}

String _$ocrRepositoryHash() => r'2bd0a12971c04212c5e2400dadd2e8894c10aa18';
