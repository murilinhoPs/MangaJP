// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notebook_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NotebookListQuery)
final notebookListQueryProvider = NotebookListQueryProvider._();

final class NotebookListQueryProvider
    extends $NotifierProvider<NotebookListQuery, NotebookQuery> {
  NotebookListQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notebookListQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notebookListQueryHash();

  @$internal
  @override
  NotebookListQuery create() => NotebookListQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotebookQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotebookQuery>(value),
    );
  }
}

String _$notebookListQueryHash() => r'fcfce86feb625f34572bcf7267d0ff09764d5208';

abstract class _$NotebookListQuery extends $Notifier<NotebookQuery> {
  NotebookQuery build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NotebookQuery, NotebookQuery>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NotebookQuery, NotebookQuery>,
              NotebookQuery,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Caderno rows for the current search / state filter.

@ProviderFor(notebookEntries)
final notebookEntriesProvider = NotebookEntriesProvider._();

/// Caderno rows for the current search / state filter.

final class NotebookEntriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<NotebookEntry>>,
          List<NotebookEntry>,
          FutureOr<List<NotebookEntry>>
        >
    with
        $FutureModifier<List<NotebookEntry>>,
        $FutureProvider<List<NotebookEntry>> {
  /// Caderno rows for the current search / state filter.
  NotebookEntriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notebookEntriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notebookEntriesHash();

  @$internal
  @override
  $FutureProviderElement<List<NotebookEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<NotebookEntry>> create(Ref ref) {
    return notebookEntries(ref);
  }
}

String _$notebookEntriesHash() => r'd1e61f2b3eaef104590467bc7b36605d634f497b';
