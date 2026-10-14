import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/routes.dart';
import '../../../core/shell/shell_layout.dart';
import '../../../core/shell/shell_nav.dart';
import '../../../core/theme/app_theme.dart';
import '../../flashcards/data/flashcards_repository.dart';
import '../../words/data/words_repository.dart';
import '../../words/domain/word_state.dart';
import 'notebook_controller.dart';
import 'notebook_labels.dart';
import 'notebook_page.dart';

/// Keys for `/notebook/word/:id` (lemma / gloss / first crop / study actions).
abstract final class NotebookWordKeys {
  static const back = Key('notebook-word-back');
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
    final wide = ShellLayout.isWide(context);

    return Scaffold(
      backgroundColor: context.tokens.bg,
      appBar: AppBar(
        leading: BackButton(
          key: NotebookWordKeys.back,
          onPressed: () => popTaskOrHome(context),
        ),
      ),
      body: view.when(
        data: (item) {
          if (item == null) {
            return _NotebookMissing(wide: wide);
          }
          return _NotebookWordBody(wordId: wordId, view: item, wide: wide);
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
      ),
    );
  }
}

class _NotebookMissing extends StatelessWidget {
  const _NotebookMissing({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IgnorePointer(
                child: Text(
                  NotebookLabels.watermark,
                  style:
                      (wide
                              ? AppTypeScale.reviewDesktopJp
                              : AppTypeScale.reviewMobileJp)
                          .copyWith(
                            color: tokens.text4.withValues(alpha: 0.35),
                            height: 1,
                          ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                NotebookLabels.empty,
                key: NotebookKeys.empty,
                textAlign: TextAlign.center,
                style: AppTypeScale.tituloTela.copyWith(color: tokens.text),
              ),
              const SizedBox(height: 8),
              Text(
                NotebookLabels.emptyHint,
                textAlign: TextAlign.center,
                style: AppTypeScale.ui14.copyWith(color: tokens.text3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotebookWordBody extends ConsumerWidget {
  const _NotebookWordBody({
    required this.wordId,
    required this.view,
    required this.wide,
  });

  final String wordId;
  final NotebookWordView view;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final detail = view.detail;
    final sentence = detail.sentence;
    final pageId = detail.pageId;
    const detalheSize = Size.fromHeight(AppTargets.detalhe);
    final lemmaStyle = wide
        ? AppTypeScale.detalheDesktopJp
        : AppTypeScale.detalheMobileJp;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final mobileBottom = 32.0 + (bottomInset > 24 ? bottomInset : 24.0);

    return SingleChildScrollView(
      padding: ShellLayout.withCommandBarPadding(
        context,
        wide
            ? const EdgeInsets.fromLTRB(48, 24, 48, 48)
            : EdgeInsets.fromLTRB(16, 12, 16, mobileBottom),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                detail.lemma,
                key: NotebookWordKeys.lemma,
                style: lemmaStyle,
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
                NotebookLabels.state(detail.state),
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
                  NotebookLabels.frase.toUpperCase(),
                  style: AppTypeScale.mono10.copyWith(
                    color: tokens.text3,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Material(
                  color: tokens.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.linha),
                    side: BorderSide(color: tokens.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Text(
                      sentence,
                      key: NotebookWordKeys.sentence,
                      style: wide
                          ? AppTypeScale.fraseLeitorDesktopJp
                          : AppTypeScale.balaoPaginaMobileJp,
                    ),
                  ),
                ),
              ],
              if (pageId != null && pageId.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    key: NotebookWordKeys.pageLink,
                    style: TextButton.styleFrom(foregroundColor: tokens.text2),
                    onPressed: () =>
                        PageDetailRoute(id: pageId).push<void>(context),
                    child: const Text(NotebookLabels.verPagina),
                  ),
                ),
              const SizedBox(height: 16),
              if (detail.state != WordState.learning) ...[
                FilledButton(
                  key: NotebookWordKeys.learn,
                  style: FilledButton.styleFrom(
                    minimumSize: detalheSize,
                    backgroundColor: tokens.overlayEstadoAtivo,
                    foregroundColor: tokens.violetText,
                    surfaceTintColor: Colors.transparent,
                    side: BorderSide(color: tokens.coral),
                  ),
                  onPressed: () => _runStudy(ref, (repo) => repo.learn(wordId)),
                  child: const Text(NotebookLabels.aprender),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton(
                key: NotebookWordKeys.known,
                style: OutlinedButton.styleFrom(
                  minimumSize: detalheSize,
                  foregroundColor: tokens.mint,
                  backgroundColor: tokens.surfaceRaised,
                  side: BorderSide(color: tokens.border),
                ),
                onPressed: () =>
                    _runStudy(ref, (repo) => repo.markKnown(wordId)),
                child: const Text(NotebookLabels.conhecido),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: NotebookWordKeys.ignore,
                style: OutlinedButton.styleFrom(
                  minimumSize: detalheSize,
                  foregroundColor: tokens.text3,
                  backgroundColor: tokens.surfaceRaised,
                  side: BorderSide(color: tokens.border),
                ),
                onPressed: () =>
                    _runStudy(ref, (repo) => repo.markIgnored(wordId)),
                child: const Text(NotebookLabels.ignorar),
              ),
              const SizedBox(height: 16),
              TextButton(
                key: NotebookWordKeys.deleteCard,
                style: _dangerTextButtonStyle(tokens),
                onPressed: () => _confirmDeleteCard(context, ref),
                child: const Text(NotebookLabels.removerCard),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: NotebookWordKeys.removeFromNotebook,
                style: _dangerTextButtonStyle(tokens),
                onPressed: () => _confirmRemoveFromNotebook(context, ref),
                child: const Text(NotebookLabels.removerDoCaderno),
              ),
            ],
          ),
        ),
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
          actions: _dangerDialogActions(
            dialogContext,
            cancelKey: NotebookWordKeys.deleteCardCancel,
            confirmKey: NotebookWordKeys.deleteCardConfirm,
          ),
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
          actions: _dangerDialogActions(
            dialogContext,
            cancelKey: NotebookWordKeys.removeFromNotebookCancel,
            confirmKey: NotebookWordKeys.removeFromNotebookConfirm,
          ),
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
            actions: _dangerDialogActions(
              dialogContext,
              cancelKey: NotebookWordKeys.removeFromNotebookCardCancel,
              confirmKey: NotebookWordKeys.removeFromNotebookCardConfirm,
            ),
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

/// Confirm = filled danger; Cancel = ghost TextButton. Same on both layouts.
List<Widget> _dangerDialogActions(
  BuildContext context, {
  required Key cancelKey,
  required Key confirmKey,
}) {
  final tokens = context.tokens;
  return [
    TextButton(
      key: cancelKey,
      style: TextButton.styleFrom(
        foregroundColor: tokens.text2,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        side: BorderSide.none,
      ),
      onPressed: () => Navigator.of(context).pop(false),
      child: const Text('Cancelar'),
    ),
    FilledButton(
      key: confirmKey,
      style: FilledButton.styleFrom(
        backgroundColor: tokens.danger,
        foregroundColor: tokens.onCoral,
        surfaceTintColor: Colors.transparent,
        // `side` must be set: filledButtonTheme's coral outline would
        // otherwise show around the solid danger fill.
        side: BorderSide(color: tokens.danger),
      ),
      onPressed: () => Navigator.of(context).pop(true),
      child: const Text('Remover'),
    ),
  ];
}

ButtonStyle _dangerTextButtonStyle(MangaJpTokens tokens) {
  return TextButton.styleFrom(foregroundColor: tokens.danger).copyWith(
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.pressed) ||
          states.contains(WidgetState.focused)) {
        return tokens.dangerBg;
      }
      return Colors.transparent;
    }),
  );
}
