import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/routes.dart';
import '../../flashcards/data/flashcards_repository.dart';
import 'notebook_controller.dart';
import 'notebook_labels.dart';

/// Keys for `/notebook/word/:id` (lemma / gloss / first crop / study actions).
abstract final class NotebookWordKeys {
  static const lemma = Key('notebook-word-lemma');
  static const reading = Key('notebook-word-reading');
  static const state = Key('notebook-word-state');
  static const gloss = Key('notebook-word-gloss');
  static const sentence = Key('notebook-word-sentence');
  static const pageLink = Key('notebook-word-page-link');
  static const learn = Key('notebook-word-learn');
  static const known = Key('notebook-word-known');
  static const ignore = Key('notebook-word-ignore');
  static const deleteCard = Key('notebook-word-delete-card');
  static const deleteCardCancel = Key('notebook-word-delete-card-cancel');
  static const deleteCardConfirm = Key('notebook-word-delete-card-confirm');
}

/// `/notebook/word/:id` — lemma, reading, state, JMdict gloss, first crop,
/// Aprender / Conhecido / Ignorar / Remover card.
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
        return _NotebookWordBody(wordId: wordId, view: item);
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

class _NotebookWordBody extends ConsumerWidget {
  const _NotebookWordBody({required this.wordId, required this.view});

  final String wordId;
  final NotebookWordView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        const SizedBox(height: 16),
        FilledButton(
          key: NotebookWordKeys.learn,
          onPressed: () => _runStudy(ref, (repo) => repo.learn(wordId)),
          child: const Text('Aprender'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: NotebookWordKeys.known,
          onPressed: () => _runStudy(ref, (repo) => repo.markKnown(wordId)),
          child: const Text('Conhecido'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: NotebookWordKeys.ignore,
          onPressed: () => _runStudy(ref, (repo) => repo.markIgnored(wordId)),
          child: const Text('Ignorar'),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: NotebookWordKeys.deleteCard,
          onPressed: () => _confirmDeleteCard(context, ref),
          child: Text(
            'Remover card',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteCard(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remover card?'),
          content: const Text(
            'O card e o progresso SRS serão apagados. '
            'A palavra continua no Caderno.',
          ),
          actions: [
            TextButton(
              key: NotebookWordKeys.deleteCardCancel,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              key: NotebookWordKeys.deleteCardConfirm,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );
    if (!context.mounted || confirmed != true) {
      return;
    }
    await _runStudy(ref, (repo) => repo.deleteCard(wordId));
  }

  Future<void> _runStudy(
    WidgetRef ref,
    Future<void> Function(FlashcardsRepository repo) action,
  ) async {
    await action(ref.read(flashcardsRepositoryProvider));
    ref.invalidate(notebookWordProvider(wordId));
    ref.invalidate(notebookEntriesProvider);
  }
}
