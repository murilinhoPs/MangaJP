import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/routes.dart';
import 'notebook_controller.dart';
import 'notebook_labels.dart';

/// Keys for `/notebook/word/:id` (read-only lemma / gloss / first crop).
abstract final class NotebookWordKeys {
  static const lemma = Key('notebook-word-lemma');
  static const reading = Key('notebook-word-reading');
  static const state = Key('notebook-word-state');
  static const gloss = Key('notebook-word-gloss');
  static const sentence = Key('notebook-word-sentence');
  static const pageLink = Key('notebook-word-page-link');
}

/// `/notebook/word/:id` — lemma, reading, state, JMdict gloss, first crop.
class NotebookWordPage extends ConsumerWidget {
  const NotebookWordPage({super.key, required this.wordId});

  final String wordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(notebookWordProvider(wordId));

    return view.when(
      data: (item) {
        if (item == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Nenhuma palavra.', textAlign: TextAlign.center),
            ),
          );
        }
        return _NotebookWordBody(view: item);
      },
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
    );
  }
}

class _NotebookWordBody extends StatelessWidget {
  const _NotebookWordBody({required this.view});

  final NotebookWordView view;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = view.detail;
    final sentence = detail.sentence;
    final pageId = detail.pageId;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          detail.lemma,
          key: NotebookWordKeys.lemma,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          detail.reading,
          key: NotebookWordKeys.reading,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          notebookStateLabel(detail.state),
          key: NotebookWordKeys.state,
          style: theme.textTheme.bodyMedium,
        ),
        if (view.glossText.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            view.glossText,
            key: NotebookWordKeys.gloss,
            style: theme.textTheme.bodyLarge,
          ),
        ],
        if (sentence != null && sentence.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            sentence,
            key: NotebookWordKeys.sentence,
            style: theme.textTheme.bodyLarge,
          ),
        ],
        if (pageId != null && pageId.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: NotebookWordKeys.pageLink,
              onPressed: () => PageDetailRoute(id: pageId).go(context),
              child: const Text('Ver página'),
            ),
          ),
      ],
    );
  }
}
