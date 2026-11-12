// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reader_overlay_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Global OCR overlay toggle. Key `reader.ocrOverlay`, default **on**.

@ProviderFor(ReaderOcrOverlay)
final readerOcrOverlayProvider = ReaderOcrOverlayProvider._();

/// Global OCR overlay toggle. Key `reader.ocrOverlay`, default **on**.
final class ReaderOcrOverlayProvider
    extends $NotifierProvider<ReaderOcrOverlay, bool> {
  /// Global OCR overlay toggle. Key `reader.ocrOverlay`, default **on**.
  ReaderOcrOverlayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readerOcrOverlayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readerOcrOverlayHash();

  @$internal
  @override
  ReaderOcrOverlay create() => ReaderOcrOverlay();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$readerOcrOverlayHash() => r'0000000000000000000000000000000000000000';

/// Global OCR overlay toggle. Key `reader.ocrOverlay`, default **on**.

abstract class _$ReaderOcrOverlay extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
