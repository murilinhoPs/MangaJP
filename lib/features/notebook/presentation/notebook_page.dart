import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../words/domain/word_state.dart';
import '../domain/notebook_entry.dart';
import 'notebook_controller.dart';

/// Keys for `/notebook` (list + search + state filter only).
abstract final class NotebookKeys {
  static const search = Key('notebook-search');
  static const stateAll = Key('notebook-state-all');
  static const list = Key('notebook-list');

  static Key stateFilter(WordState state) =>
      Key('notebook-state-${state.name}');

  static Key row(String wordId) => Key('notebook-row-$wordId');
}

/// `/notebook` — every word with a listed state, newest first.
class NotebookPage extends ConsumerWidget {
  const NotebookPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(notebookListQueryProvider);
    final entries = ref.watch(notebookEntriesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            key: NotebookKeys.search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Lema ou leitura',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) {
              ref.read(notebookListQueryProvider.notifier).setSearch(value);
            },
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  key: NotebookKeys.stateAll,
                  label: const Text('Todos'),
                  selected: query.state == null,
                  onSelected: (_) {
                    ref.read(notebookListQueryProvider.notifier).setState(null);
                  },
                ),
              ),
              for (final state in WordState.listed)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    key: NotebookKeys.stateFilter(state),
                    label: Text(_stateLabel(state)),
                    selected: query.state == state,
                    onSelected: (_) {
                      ref
                          .read(notebookListQueryProvider.notifier)
                          .setState(state);
                    },
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: entries.when(
            data: (items) => _NotebookList(entries: items),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotebookList extends StatelessWidget {
  const _NotebookList({required this.entries});

  final List<NotebookEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Nenhuma palavra.', textAlign: TextAlign.center),
        ),
      );
    }

    return ListView.separated(
      key: NotebookKeys.list,
      itemCount: entries.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return ListTile(
          key: NotebookKeys.row(entry.wordId),
          title: Text(entry.lemma),
          subtitle: Text(entry.reading),
          trailing: Text(_stateLabel(entry.state)),
        );
      },
    );
  }
}

String _stateLabel(WordState state) {
  return switch (state) {
    WordState.saved => 'Salvo',
    WordState.learning => 'Aprendendo',
    WordState.known => 'Conhecido',
    WordState.ignored => 'Ignorado',
    WordState.unknown => '',
  };
}
