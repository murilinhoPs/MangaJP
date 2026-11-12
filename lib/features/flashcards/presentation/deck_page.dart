import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/shell/shell_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../notebook/presentation/notebook_controller.dart';
import '../../review/data/review_repository.dart';
import '../data/flashcards_repository.dart';
import '../domain/deck_card.dart';
import '../domain/suspend_reason.dart';
import 'deck_controller.dart';
import 'deck_labels.dart';

/// Keys for `/deck` (list + empty + F23 suspend / reactivate).
abstract final class DeckKeys {
  static const list = Key('deck-list');
  static const empty = Key('deck-empty');
  static const title = Key('deck-title');
  static const suspendDialog = Key('deck-suspend-dialog');
  static const suspendCancel = Key('deck-suspend-cancel');
  static const suspendConfirm = Key('deck-suspend-confirm');

  static Key row(String wordId) => Key('deck-row-$wordId');

  static Key status(String wordId) => Key('deck-status-$wordId');

  static Key suspend(String wordId) => Key('deck-suspend-$wordId');

  static Key reactivate(String wordId) => Key('deck-reactivate-$wordId');
}

/// `/deck` — every vocab card. F23: Suspender / Reativar on the row.
class DeckPage extends ConsumerWidget {
  const DeckPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(deckCardsProvider);
    final wide = ShellLayout.isWide(context);

    return Scaffold(
      backgroundColor: context.tokens.bg,
      appBar: AppBar(
        title: const Text(DeckLabels.title, key: DeckKeys.title),
      ),
      body: cards.when(
        data: (items) => items.isEmpty
            ? _DeckEmpty(wide: wide)
            : _DeckList(cards: items, wide: wide),
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

class _DeckList extends StatelessWidget {
  const _DeckList({required this.cards, required this.wide});

  final List<DeckCard> cards;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final padH = wide ? 48.0 : 16.0;
    return ListView.separated(
      key: DeckKeys.list,
      padding: ShellLayout.withCommandBarPadding(
        context,
        EdgeInsets.fromLTRB(padH, 16, padH, wide ? 32 : 16),
      ),
      itemCount: cards.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _DeckRow(card: cards[index]);
      },
    );
  }
}

class _DeckRow extends ConsumerWidget {
  const _DeckRow({required this.card});

  final DeckCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final radius = BorderRadius.circular(AppRadius.linha);
    final status = DeckLabels.status(
      suspendReason: card.suspendReason,
      wordState: card.wordState,
    );
    return Material(
      key: DeckKeys.row(card.wordId),
      color: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: tokens.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.lemma,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypeScale.linhaCadernoJp,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    card.reading,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypeScale.ui14.copyWith(
                      fontFamily: AppFonts.jp,
                      color: tokens.text2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              status,
              key: DeckKeys.status(card.wordId),
              style: AppTypeScale.metadados11.copyWith(
                color: _statusColor(tokens, card),
              ),
            ),
            const SizedBox(width: 4),
            if (card.canSuspend)
              TextButton(
                key: DeckKeys.suspend(card.wordId),
                onPressed: () => _confirmSuspend(context, ref),
                child: const Text(DeckLabels.suspender),
              )
            else if (card.canReactivate)
              TextButton(
                key: DeckKeys.reactivate(card.wordId),
                onPressed: () => _run(ref, (repo) => repo.reactivate(card.wordId)),
                child: const Text(DeckLabels.reativar),
              ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(MangaJpTokens tokens, DeckCard card) {
    if (SuspendReason.fromDb(card.suspendReason) == SuspendReason.user) {
      return tokens.text2;
    }
    return tokens.wordState(card.wordState.name);
  }

  Future<void> _confirmSuspend(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final tokens = dialogContext.tokens;
        return AlertDialog(
          key: DeckKeys.suspendDialog,
          title: const Text(DeckLabels.suspenderTitulo),
          content: const Text(DeckLabels.suspenderBody),
          actions: [
            TextButton(
              key: DeckKeys.suspendCancel,
              style: TextButton.styleFrom(
                foregroundColor: tokens.text2,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.transparent,
                side: BorderSide.none,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(DeckLabels.cancelar),
            ),
            FilledButton(
              key: DeckKeys.suspendConfirm,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(DeckLabels.suspender),
            ),
          ],
        );
      },
    );
    if (!context.mounted || confirmed != true) {
      return;
    }
    await _run(ref, (repo) => repo.suspendByUser(card.wordId));
  }

  Future<void> _run(
    WidgetRef ref,
    Future<void> Function(FlashcardsRepository repo) action,
  ) async {
    await action(ref.read(flashcardsRepositoryProvider));
    ref.invalidate(deckCardsProvider);
    ref.read(reviewRevisionProvider.notifier).bump();
    ref.invalidate(notebookListedWordsProvider);
    ref.invalidate(notebookWordProvider(card.wordId));
  }
}

class _DeckEmpty extends StatelessWidget {
  const _DeckEmpty({required this.wide});

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
                  DeckLabels.watermark,
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
                DeckLabels.empty,
                key: DeckKeys.empty,
                textAlign: TextAlign.center,
                style: AppTypeScale.tituloTela.copyWith(color: tokens.text),
              ),
              const SizedBox(height: 8),
              Text(
                DeckLabels.emptyHint,
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
