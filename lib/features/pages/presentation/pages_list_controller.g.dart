// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pages_list_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every persisted page for `/pages`, newest first.

@ProviderFor(pagesList)
final pagesListProvider = PagesListProvider._();

/// Every persisted page for `/pages`, newest first.

final class PagesListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PageListEntry>>,
          List<PageListEntry>,
          FutureOr<List<PageListEntry>>
        >
    with
        $FutureModifier<List<PageListEntry>>,
        $FutureProvider<List<PageListEntry>> {
  /// Every persisted page for `/pages`, newest first.
  PagesListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pagesListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pagesListHash();

  @$internal
  @override
  $FutureProviderElement<List<PageListEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PageListEntry>> create(Ref ref) {
    return pagesList(ref);
  }
}

String _$pagesListHash() => r'6a953c60958eb4d222920f66a0a94c5fa598de6d';
