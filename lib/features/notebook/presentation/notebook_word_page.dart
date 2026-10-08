import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../flashcards/data/flashcards_repository.dart';
import '../../words/data/words_repository.dart';
import 'notebook_controller.dart';
import 'notebook_labels.dart';

/// Keys for `/notebook/word/:id` (lemma / gloss / first crop / study actions).
abstract final class NotebookWordKeys {
  static const lemma = Key('notebook-word-lemma');
  static const reading = Key('notebook-word-reading');
  static const state = Key('notebook-word-state');
  static const gloss = Key('notebook-word-gloss');
  static const note = Key('notebook-word-note');
  static const sentence = Key('notebook-word-sentence');
  static const pageLink = Key('notebook-word-page-link');
  static const learn = Key('notebook-word-learn');
  static const known = Key('notebook-word-known');
  static const ignore = Key('notebook-word-ignore');
  static const deleteCard = Key('notebook-word-delete-card');
  static const deleteCardCancel = Key('notebook-word-delete-card-cancel');
  static const deleteCardConfirm = Key('notebook-word-delete-card-confirm');
  static const removeFromNotebook = Key('notebook-word-remove-from-notebook');
  static const removeFromNotebookCancel = Key(
    'notebook-word-remove-from-notebook-cancel',
  );
  static const removeFromNotebookConfirm = Key(
    'notebook-word-remove-from-notebook-confirm',
  );
  static const removeFromNotebookCardCancel = Key(
    'notebook-word-remove-from-notebook-card-cancel',
  );
  static const removeFromNotebookCardConfirm = Key(
    'notebook-word-remove-from-notebook-card-confirm',
  );
}

/// `/notebook/word/:id` — lemma, reading, state, JMdict gloss, first crop,
/// Aprender / Conhecido / Ignorar / Remover card / Remover do Caderno.
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
    final tokens = context.tokens;
    final detail = view.detail;
    final sentence = detail.sentence;
    final pageId = detail.pageId;
    const detalheSize = Size.fromHeight(AppTargets.detalhe);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            detail.lemma,
            key: NotebookWordKeys.lemma,
            style: AppTypeScale.detalheMobileJp,
          ),
          const SizedBox(height: 4),
          Text(
            detail.reading,
            key: NotebookWordKeys.reading,
            style: AppTypeScale.ui14.copyWith(
              fontFamily: AppFonts.jp,
              color: tokens.text2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            notebookStateLabel(detail.state),
            key: NotebookWordKeys.state,
            style: AppTypeScale.ui14.copyWith(
              color: tokens.wordState(detail.state.name),
            ),
          ),
          if (view.glossText.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              view.glossText,
              key: NotebookWordKeys.gloss,
              style: AppTypeScale.definicao,
            ),
          ],
          if (detail.userNote != null && detail.userNote!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              detail.userNote!,
              key: NotebookWordKeys.note,
              style: AppTypeScale.definicao,
            ),
          ],
          if (sentence != null && sentence.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              sentence,
              key: NotebookWordKeys.sentence,
              style: AppTypeScale.balaoPaginaMobileJp,
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
            style: FilledButton.styleFrom(
              minimumSize: detalheSize,
              backgroundColor: tokens.overlayEstadoAtivo,
              foregroundColor: tokens.violetText,
              side: BorderSide(color: tokens.coral),
            ),
            onPressed: () => _runStudy(ref, (repo) => repo.learn(wordId)),
            child: const Text('Aprender'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: NotebookWordKeys.known,
            style: OutlinedButton.styleFrom(
              minimumSize: detalheSize,
              foregroundColor: tokens.mint,
              backgroundColor: tokens.surfaceRaised,
            ),
            onPressed: () => _runStudy(ref, (repo) => repo.markKnown(wordId)),
            child: const Text('Conhecido'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: NotebookWordKeys.ignore,
            style: OutlinedButton.styleFrom(
              minimumSize: detalheSize,
              foregroundColor: tokens.text3,
              backgroundColor: tokens.surfaceRaised,
            ),
            onPressed: () => _runStudy(ref, (repo) => repo.markIgnored(wordId)),
            child: const Text('Ignorar'),
          ),
          const SizedBox(height: 8),
          TextButton(
            key: NotebookWordKeys.deleteCard,
            onPressed: () => _confirmDeleteCard(context, ref),
            child: Text(
              'Remover card',
              style: TextStyle(color: tokens.coral),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            key: NotebookWordKeys.removeFromNotebook,
            onPressed: () => _confirmRemoveFromNotebook(context, ref),
            child: Text(
              'Remover do Caderno',
              style: TextStyle(color: tokens.coral),
            ),
          ),
        ],
      ),
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

  Future<void> _confirmRemoveFromNotebook(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final words = ref.read(wordsRepositoryProvider);
    final hasCard = await words.hasCard(wordId);
    if (!context.mounted) {
      return;
    }

    final first = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remover do Caderno?'),
          content: const Text('A palavra será apagada do Caderno.'),
          actions: [
            TextButton(
              key: NotebookWordKeys.removeFromNotebookCancel,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              key: NotebookWordKeys.removeFromNotebookConfirm,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );
    if (!context.mounted || first != true) {
      return;
    }

    if (hasCard) {
      final second = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Apagar o card também?'),
            content: const Text(
              'O card, o progresso SRS e o histórico de revisão '
              'também serão apagados.',
            ),
            actions: [
              TextButton(
                key: NotebookWordKeys.removeFromNotebookCardCancel,
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                key: NotebookWordKeys.removeFromNotebookCardConfirm,
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Remover'),
              ),
            ],
          );
        },
      );
      if (!context.mounted || second != true) {
        return;
      }
    }

    await words.removeFromNotebook(wordId);
    ref.invalidate(notebookWordProvider(wordId));
    ref.invalidate(notebookEntriesProvider);
    if (!context.mounted) {
      return;
    }
    const NotebookRoute().go(context);
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
