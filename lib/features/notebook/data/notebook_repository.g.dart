// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notebook_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(notebookRepository)
final notebookRepositoryProvider = NotebookRepositoryProvider._();

final class NotebookRepositoryProvider
    extends
        $FunctionalProvider<
          NotebookRepository,
          NotebookRepository,
          NotebookRepository
        >
    with $Provider<NotebookRepository> {
  NotebookRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notebookRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notebookRepositoryHash();

  @$internal
  @override
  $ProviderElement<NotebookRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotebookRepository create(Ref ref) {
    return notebookRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotebookRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotebookRepository>(value),
    );
  }
}

String _$notebookRepositoryHash() =>
    r'c42a9741d51eb8b9251fe08b3f43ebdf735a733d';
