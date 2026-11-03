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

@ProviderFor(NotebookSelectedTab)
final notebookSelectedTabProvider = NotebookSelectedTabProvider._();

final class NotebookSelectedTabProvider
    extends $NotifierProvider<NotebookSelectedTab, NotebookTab> {
  NotebookSelectedTabProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notebookSelectedTabProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notebookSelectedTabHash();

  @$internal
  @override
  NotebookSelectedTab create() => NotebookSelectedTab();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotebookTab value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotebookTab>(value),
    );
  }
}

String _$notebookSelectedTabHash() =>
    r'd43f7740102edf420183db61d017e181bd8dde20';

abstract class _$NotebookSelectedTab extends $Notifier<NotebookTab> {
  NotebookTab build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NotebookTab, NotebookTab>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NotebookTab, NotebookTab>,
              NotebookTab,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(NotebookKanjiQuery)
final notebookKanjiQueryProvider = NotebookKanjiQueryProvider._();

final class NotebookKanjiQueryProvider
    extends $NotifierProvider<NotebookKanjiQuery, String> {
  NotebookKanjiQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notebookKanjiQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notebookKanjiQueryHash();

  @$internal
  @override
  NotebookKanjiQuery create() => NotebookKanjiQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$notebookKanjiQueryHash() =>
    r'e14d913599ddffb6c3042649102ead5bd0a68181';

abstract class _$NotebookKanjiQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Unfiltered Caderno words, newest first.
///
/// Palavras search/state and Kanji related-words both watch this so a
/// remove or study refreshes both tabs without leaking the Palavras filter
/// into the Kanji list.

@ProviderFor(notebookListedWords)
final notebookListedWordsProvider = NotebookListedWordsProvider._();

/// Unfiltered Caderno words, newest first.
///
/// Palavras search/state and Kanji related-words both watch this so a
/// remove or study refreshes both tabs without leaking the Palavras filter
/// into the Kanji list.

final class NotebookListedWordsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<NotebookEntry>>,
          List<NotebookEntry>,
          FutureOr<List<NotebookEntry>>
        >
    with
        $FutureModifier<List<NotebookEntry>>,
        $FutureProvider<List<NotebookEntry>> {
  /// Unfiltered Caderno words, newest first.
  ///
  /// Palavras search/state and Kanji related-words both watch this so a
  /// remove or study refreshes both tabs without leaking the Palavras filter
  /// into the Kanji list.
  NotebookListedWordsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notebookListedWordsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notebookListedWordsHash();

  @$internal
  @override
  $FutureProviderElement<List<NotebookEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<NotebookEntry>> create(Ref ref) {
    return notebookListedWords(ref);
  }
}

String _$notebookListedWordsHash() =>
    r'0dc746eaac2b8fc86d22f7c449c705c400d46e0c';

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

String _$notebookEntriesHash() => r'8e6c3dafab4e1be51b1e7d6baa9cd6a356dd217f';

/// Saved kanji for the Kanji tab, newest first, filtered by search.

@ProviderFor(notebookKanjiEntries)
final notebookKanjiEntriesProvider = NotebookKanjiEntriesProvider._();

/// Saved kanji for the Kanji tab, newest first, filtered by search.

final class NotebookKanjiEntriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<NotebookKanjiView>>,
          List<NotebookKanjiView>,
          FutureOr<List<NotebookKanjiView>>
        >
    with
        $FutureModifier<List<NotebookKanjiView>>,
        $FutureProvider<List<NotebookKanjiView>> {
  /// Saved kanji for the Kanji tab, newest first, filtered by search.
  NotebookKanjiEntriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notebookKanjiEntriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notebookKanjiEntriesHash();

  @$internal
  @override
  $FutureProviderElement<List<NotebookKanjiView>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<NotebookKanjiView>> create(Ref ref) {
    return notebookKanjiEntries(ref);
  }
}

String _$notebookKanjiEntriesHash() =>
    r'c15985aa8efc3a4455b4a097bc5207d8ba819d94';

/// `/notebook/kanji/:char` payload.

@ProviderFor(notebookKanji)
final notebookKanjiProvider = NotebookKanjiFamily._();

/// `/notebook/kanji/:char` payload.

final class NotebookKanjiProvider
    extends
        $FunctionalProvider<
          AsyncValue<NotebookKanjiView?>,
          NotebookKanjiView?,
          FutureOr<NotebookKanjiView?>
        >
    with
        $FutureModifier<NotebookKanjiView?>,
        $FutureProvider<NotebookKanjiView?> {
  /// `/notebook/kanji/:char` payload.
  NotebookKanjiProvider._({
    required NotebookKanjiFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'notebookKanjiProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$notebookKanjiHash();

  @override
  String toString() {
    return r'notebookKanjiProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<NotebookKanjiView?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<NotebookKanjiView?> create(Ref ref) {
    final argument = this.argument as String;
    return notebookKanji(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is NotebookKanjiProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$notebookKanjiHash() => r'849b3a9e94036a846982e9fdaa582fbe23ef7791';

/// `/notebook/kanji/:char` payload.

final class NotebookKanjiFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<NotebookKanjiView?>, String> {
  NotebookKanjiFamily._()
    : super(
        retry: null,
        name: r'notebookKanjiProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// `/notebook/kanji/:char` payload.

  NotebookKanjiProvider call(String char) =>
      NotebookKanjiProvider._(argument: char, from: this);

  @override
  String toString() => r'notebookKanjiProvider';
}

@ProviderFor(kanjiIsSaved)
final kanjiIsSavedProvider = KanjiIsSavedFamily._();

final class KanjiIsSavedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  KanjiIsSavedProvider._({
    required KanjiIsSavedFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'kanjiIsSavedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$kanjiIsSavedHash();

  @override
  String toString() {
    return r'kanjiIsSavedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as String;
    return kanjiIsSaved(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is KanjiIsSavedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$kanjiIsSavedHash() => r'2b6f82755560c5e5c567ea96c4227271dca5ddb7';

final class KanjiIsSavedFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, String> {
  KanjiIsSavedFamily._()
    : super(
        retry: null,
        name: r'kanjiIsSavedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  KanjiIsSavedProvider call(String literal) =>
      KanjiIsSavedProvider._(argument: literal, from: this);

  @override
  String toString() => r'kanjiIsSavedProvider';
}

/// `/notebook/word/:id` payload. Gloss comes from JMdict by seq.

@ProviderFor(notebookWord)
final notebookWordProvider = NotebookWordFamily._();

/// `/notebook/word/:id` payload. Gloss comes from JMdict by seq.

final class NotebookWordProvider
    extends
        $FunctionalProvider<
          AsyncValue<NotebookWordView?>,
          NotebookWordView?,
          FutureOr<NotebookWordView?>
        >
    with
        $FutureModifier<NotebookWordView?>,
        $FutureProvider<NotebookWordView?> {
  /// `/notebook/word/:id` payload. Gloss comes from JMdict by seq.
  NotebookWordProvider._({
    required NotebookWordFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'notebookWordProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$notebookWordHash();

  @override
  String toString() {
    return r'notebookWordProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<NotebookWordView?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<NotebookWordView?> create(Ref ref) {
    final argument = this.argument as String;
    return notebookWord(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is NotebookWordProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$notebookWordHash() => r'831b249e6f8060321483e5f81ce2c907f1de918b';

/// `/notebook/word/:id` payload. Gloss comes from JMdict by seq.

final class NotebookWordFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<NotebookWordView?>, String> {
  NotebookWordFamily._()
    : super(
        retry: null,
        name: r'notebookWordProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// `/notebook/word/:id` payload. Gloss comes from JMdict by seq.

  NotebookWordProvider call(String wordId) =>
      NotebookWordProvider._(argument: wordId, from: this);

  @override
  String toString() => r'notebookWordProvider';
}
