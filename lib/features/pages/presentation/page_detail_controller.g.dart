// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_detail_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Persisted crops for `/pages/:id`. Text is read from Drift, not route extra.

@ProviderFor(PageCrops)
final pageCropsProvider = PageCropsFamily._();

/// Persisted crops for `/pages/:id`. Text is read from Drift, not route extra.
final class PageCropsProvider
    extends $AsyncNotifierProvider<PageCrops, List<PageCrop>> {
  /// Persisted crops for `/pages/:id`. Text is read from Drift, not route extra.
  PageCropsProvider._({
    required PageCropsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pageCropsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pageCropsHash();

  @override
  String toString() {
    return r'pageCropsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PageCrops create() => PageCrops();

  @override
  bool operator ==(Object other) {
    return other is PageCropsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pageCropsHash() => r'd63053e3c3e0ce86aee6ed1821bffcc8bb734490';

/// Persisted crops for `/pages/:id`. Text is read from Drift, not route extra.

final class PageCropsFamily extends $Family
    with
        $ClassFamilyOverride<
          PageCrops,
          AsyncValue<List<PageCrop>>,
          List<PageCrop>,
          FutureOr<List<PageCrop>>,
          String
        > {
  PageCropsFamily._()
    : super(
        retry: null,
        name: r'pageCropsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Persisted crops for `/pages/:id`. Text is read from Drift, not route extra.

  PageCropsProvider call(String pageId) =>
      PageCropsProvider._(argument: pageId, from: this);

  @override
  String toString() => r'pageCropsProvider';
}

/// Persisted crops for `/pages/:id`. Text is read from Drift, not route extra.

abstract class _$PageCrops extends $AsyncNotifier<List<PageCrop>> {
  late final _$args = ref.$arg as String;
  String get pageId => _$args;

  FutureOr<List<PageCrop>> build(String pageId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<PageCrop>>, List<PageCrop>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<PageCrop>>, List<PageCrop>>,
              AsyncValue<List<PageCrop>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
