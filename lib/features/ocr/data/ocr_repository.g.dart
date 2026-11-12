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

String _$ocrEngineHash() => r'e71f27b109c77a75fb61850764f73a0a79565d99';

@ProviderFor(cloudVisionStore)
final cloudVisionStoreProvider = CloudVisionStoreProvider._();

final class CloudVisionStoreProvider
    extends
        $FunctionalProvider<
          CloudVisionStore,
          CloudVisionStore,
          CloudVisionStore
        >
    with $Provider<CloudVisionStore> {
  CloudVisionStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cloudVisionStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cloudVisionStoreHash();

  @$internal
  @override
  $ProviderElement<CloudVisionStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CloudVisionStore create(Ref ref) {
    return cloudVisionStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CloudVisionStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CloudVisionStore>(value),
    );
  }
}

String _$cloudVisionStoreHash() => r'b7c36f98bb71d97099fdcef29baa72bc04267a56';

@ProviderFor(cloudVisionOcrEngine)
final cloudVisionOcrEngineProvider = CloudVisionOcrEngineProvider._();

final class CloudVisionOcrEngineProvider
    extends
        $FunctionalProvider<
          CloudVisionOcrEngine,
          CloudVisionOcrEngine,
          CloudVisionOcrEngine
        >
    with $Provider<CloudVisionOcrEngine> {
  CloudVisionOcrEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cloudVisionOcrEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cloudVisionOcrEngineHash();

  @$internal
  @override
  $ProviderElement<CloudVisionOcrEngine> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CloudVisionOcrEngine create(Ref ref) {
    return cloudVisionOcrEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CloudVisionOcrEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CloudVisionOcrEngine>(value),
    );
  }
}

String _$cloudVisionOcrEngineHash() =>
    r'3d00fdf2d1d27e7e5f1de31dbd528e5326472d80';

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

String _$ocrRepositoryHash() => r'2790e77a2fada7af5931c6b2d9e989df7949d1d5';
