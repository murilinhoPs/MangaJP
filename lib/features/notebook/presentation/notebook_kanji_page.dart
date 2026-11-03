import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/routes.dart';
import '../../../core/shell/shell_layout.dart';
import '../../../core/shell/shell_nav.dart';
import '../../../core/theme/app_theme.dart';
import '../data/notebook_repository.dart';
import '../domain/notebook_kanji.dart';
import 'notebook_controller.dart';
import 'notebook_labels.dart';
import 'notebook_page.dart';

/// Keys for `/notebook/kanji/:char`.
abstract final class NotebookKanjiKeys {
  static const back = Key('notebook-kanji-back');
  static const literal = Key('notebook-kanji-literal');
  static const on = Key('notebook-kanji-on');
  static const kun = Key('notebook-kanji-kun');
  static const meanings = Key('notebook-kanji-meanings');
  static const strokes = Key('notebook-kanji-strokes');
  static const words = Key('notebook-kanji-words');
  static const remove = Key('notebook-kanji-remove');
  static const removeCancel = Key('notebook-kanji-remove-cancel');
  static const removeConfirm = Key('notebook-kanji-remove-confirm');

  static Key word(String wordId) => Key('notebook-kanji-word-$wordId');
}

/// `/notebook/kanji/:char` — large kanji, on/kun, meanings, strokes, words.
class NotebookKanjiPage extends ConsumerWidget {
  const NotebookKanjiPage({super.key, required this.char});

  final String char;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(notebookKanjiProvider(char));
    final wide = ShellLayout.isWide(context);
    if (ref.read(notebookSelectedTabProvider) != NotebookTab.kanji) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(notebookSelectedTabProvider.notifier)
            .setTab(NotebookTab.kanji);
      });
    }

    return Scaffold(
      backgroundColor: context.tokens.bg,
      appBar: AppBar(
        leading: BackButton(
          key: NotebookKanjiKeys.back,
          onPressed: () => popTaskOrHome(context),
        ),
      ),
      body: view.when(
        data: (item) {
          if (item == null) {
            return _KanjiMissing(wide: wide);
          }
          return _NotebookKanjiBody(view: item, wide: wide);
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

class _KanjiMissing extends StatelessWidget {
  const _KanjiMissing({required this.wide});

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
                  NotebookLabels.kanjiWatermark,
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
                NotebookLabels.kanjiEmpty,
                key: NotebookKeys.kanjiEmpty,
                textAlign: TextAlign.center,
                style: AppTypeScale.tituloTela.copyWith(color: tokens.text),
              ),
              const SizedBox(height: 8),
              Text(
                NotebookLabels.kanjiEmptyHint,
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

class _NotebookKanjiBody extends ConsumerWidget {
  const _NotebookKanjiBody({required this.view, required this.wide});

  final NotebookKanjiView view;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final lookup = view.lookup;
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
                view.literal,
                key: NotebookKanjiKeys.literal,
                style: lemmaStyle,
              ),
              if (lookup != null && lookup.onReadings.isNotEmpty) ...[
                const SizedBox(height: 16),
                const _Label(NotebookLabels.kanjiOn),
                const SizedBox(height: 4),
                Text(
                  lookup.onReadings.join(' · '),
                  key: NotebookKanjiKeys.on,
                  style: AppTypeScale.ui14.copyWith(
                    fontFamily: AppFonts.jp,
                    color: tokens.text2,
                  ),
                ),
              ],
              if (lookup != null && lookup.kunReadings.isNotEmpty) ...[
                const SizedBox(height: 12),
                const _Label(NotebookLabels.kanjiKun),
                const SizedBox(height: 4),
                Text(
                  lookup.kunReadings.join(' · '),
                  key: NotebookKanjiKeys.kun,
                  style: AppTypeScale.ui14.copyWith(
                    fontFamily: AppFonts.jp,
                    color: tokens.text2,
                  ),
                ),
              ],
              if (lookup != null && lookup.meanings.isNotEmpty) ...[
                const SizedBox(height: 12),
                const _Label(NotebookLabels.kanjiMeanings),
                const SizedBox(height: 4),
                Text(
                  lookup.meanings.join('; '),
                  key: NotebookKanjiKeys.meanings,
                  style: AppTypeScale.definicao,
                ),
              ],
              if (lookup != null && lookup.strokeCount != null) ...[
                const SizedBox(height: 12),
                const _Label(NotebookLabels.kanjiStrokes),
                const SizedBox(height: 4),
                Text(
                  '${lookup.strokeCount}',
                  key: NotebookKanjiKeys.strokes,
                  style: AppTypeScale.ui14.copyWith(color: tokens.text2),
                ),
              ],
              if (view.notebookWords.isNotEmpty) ...[
                const SizedBox(height: 24),
                const _Label(NotebookLabels.kanjiWords),
                const SizedBox(height: 8),
                Column(
                  key: NotebookKanjiKeys.words,
                  children: [
                    for (final word in view.notebookWords)
                      ListTile(
                        key: NotebookKanjiKeys.word(word.wordId),
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          word.lemma,
                          style: AppTypeScale.linhaCadernoJp,
                        ),
                        subtitle: Text(
                          word.reading,
                          style: AppTypeScale.ui14.copyWith(
                            fontFamily: AppFonts.jp,
                            color: tokens.text2,
                          ),
                        ),
                        onTap: () =>
                            NotebookWordRoute(id: word.wordId)
                                .push<void>(context),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                key: NotebookKanjiKeys.remove,
                style: _dangerTextButtonStyle(tokens),
                onPressed: () => _confirmRemove(context, ref),
                child: const Text(NotebookLabels.removerDoCaderno),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remover do Caderno?'),
          content: const Text(NotebookLabels.kanjiRemoveBody),
          actions: [
            TextButton(
              key: NotebookKanjiKeys.removeCancel,
              style: TextButton.styleFrom(
                foregroundColor: dialogContext.tokens.text2,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.transparent,
                side: BorderSide.none,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: NotebookKanjiKeys.removeConfirm,
              style: FilledButton.styleFrom(
                backgroundColor: dialogContext.tokens.danger,
                foregroundColor: dialogContext.tokens.onCoral,
                surfaceTintColor: Colors.transparent,
                side: BorderSide(color: dialogContext.tokens.danger),
              ),
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
    await ref.read(notebookRepositoryProvider).removeKanji(view.literal);
    ref.invalidate(notebookKanjiProvider(view.literal));
    ref.invalidate(notebookKanjiEntriesProvider);
    ref.invalidate(kanjiIsSavedProvider(view.literal));
    if (!context.mounted) {
      return;
    }
    ref.read(notebookSelectedTabProvider.notifier).setTab(NotebookTab.kanji);
    const NotebookRoute().go(context);
  }
}

class _Label extends StatelessWidget {
  const _Label(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Text(
      label,
      style: AppTypeScale.mono10.copyWith(
        color: tokens.text3,
        letterSpacing: 0.8,
      ),
    );
  }
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
