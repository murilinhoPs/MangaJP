// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pages_list_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every persisted page for `/pages`, newest first.
///
/// A stream so Galeria + → capture can insert while `/pages` stays mounted
/// underneath (push `/capture`, then `pushReplacement` `/pages/:id`).

@ProviderFor(pagesList)
final pagesListProvider = PagesListProvider._();

/// Every persisted page for `/pages`, newest first.
///
/// A stream so Galeria + → capture can insert while `/pages` stays mounted
/// underneath (push `/capture`, then `pushReplacement` `/pages/:id`).

final class PagesListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PageListEntry>>,
          List<PageListEntry>,
          Stream<List<PageListEntry>>
        >
    with
        $FutureModifier<List<PageListEntry>>,
        $StreamProvider<List<PageListEntry>> {
  /// Every persisted page for `/pages`, newest first.
  ///
  /// A stream so Galeria + → capture can insert while `/pages` stays mounted
  /// underneath (push `/capture`, then `pushReplacement` `/pages/:id`).
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
  $StreamProviderElement<List<PageListEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<PageListEntry>> create(Ref ref) {
    return pagesList(ref);
  }
}

String _$pagesListHash() => r'2d63aeb46c69e89a5deed1968f978c1ff6cf6c9d';
