import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/shell/shell_layout.dart';
import '../../../core/shell/shell_nav.dart';
import '../../../core/shell/shell_registry.dart';
import '../../../core/shell/task_dock.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/interval_preview.dart';
import '../domain/review_rating.dart';
import 'review_controller.dart';

/// Keys for `/review` (front, reveal, ratings, empty queue).
abstract final class ReviewKeys {
  static const empty = Key('review-empty');
  static const lemma = Key('review-lemma');
  static const reading = Key('review-reading');
  static const gloss = Key('review-gloss');
  static const note = Key('review-note');
  static const reveal = Key('review-reveal');

  static Key rating(ReviewRating rating) => Key('review-${rating.name}');

  static Key interval(ReviewRating rating) =>
      Key('review-${rating.name}-interval');
}

/// `/review` — session snapshot of the due queue (at most 15 new cards
/// per study-day). Front is the lemma; Revelar shows reading + JMdict
/// gloss, then Again / Hard / Good / Easy with the `sm2-jr@1` interval
/// that rating would schedule (hidden on drill). Again/Hard go to the
/// back of this session; Good/Easy leave it.
class ReviewPage extends ConsumerWidget {
  const ReviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(reviewSessionProvider);

    return view.when(
      data: (item) {
        if (item == null) {
          return const _ReviewScaffold(
            meta: 'Review',
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nenhum card para revisar.',
                  key: ReviewKeys.empty,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        return _ReviewCardBody(
          key: ValueKey('${item.card.cardId}-${item.showSeq}'),
          view: item,
        );
      },
      loading: () => const _ReviewScaffold(
        meta: 'Review',
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _ReviewScaffold(
        meta: 'Review',
        child: Center(
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

class _ReviewCardBody extends ConsumerStatefulWidget {
  const _ReviewCardBody({super.key, required this.view});

  final ReviewView view;

  @override
  ConsumerState<_ReviewCardBody> createState() => _ReviewCardBodyState();
}

class _ReviewScaffold extends StatelessWidget {
  const _ReviewScaffold({
    required this.child,
    required this.meta,
    this.actions = const [],
  });

  final Widget child;
  final String meta;
  final List<ShellAction> actions;

  @override
  Widget build(BuildContext context) {
    final wide = ShellLayout.isWide(context);
    return ShellBinder(
      task: ShellTask(meta: meta, actions: actions),
      child: Column(
        children: [
          Expanded(child: child),
          if (!wide)
            TaskDock(
              meta: meta,
              leading: [
                DockIconButton(
                  key: ShellKeys.dockAction('close'),
                  icon: Icons.close,
                  tooltip: 'Fechar',
                  onPressed: () => popTaskOrHome(context),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ReviewCardBodyState extends ConsumerState<_ReviewCardBody> {
  bool _revealed = false;

  void _reveal() {
    if (!_revealed) {
      setState(() => _revealed = true);
    }
  }

  void _rate(ReviewRating rating) {
    if (!_revealed) {
      return;
    }
    ref.read(reviewSessionProvider.notifier).answer(rating);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final card = widget.view.card;
    final gloss = widget.view.glossText;
    final previews = ratingPreviewLabels(card.srs, isDrill: card.isDrill);
    final actions = <ShellAction>[
      if (!_revealed)
        ShellAction(
          id: 'mostrar',
          label: 'Mostrar',
          shortcut: 'Espaço',
          primary: true,
          onPressed: _reveal,
        ),
    ];

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): _reveal,
        const SingleActivator(LogicalKeyboardKey.digit1): () {
          _rate(ReviewRating.again);
        },
        const SingleActivator(LogicalKeyboardKey.digit2): () {
          _rate(ReviewRating.hard);
        },
        const SingleActivator(LogicalKeyboardKey.digit3): () {
          _rate(ReviewRating.good);
        },
        const SingleActivator(LogicalKeyboardKey.digit4): () {
          _rate(ReviewRating.easy);
        },
      },
      child: Focus(
        autofocus: true,
        child: _ReviewScaffold(
          meta: card.lemma,
          actions: actions,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          card.lemma,
                          key: ReviewKeys.lemma,
                          style: AppTypeScale.reviewMobileJp,
                          textAlign: TextAlign.center,
                        ),
                        if (_revealed) ...[
                          const SizedBox(height: 8),
                          Text(
                            card.reading,
                            key: ReviewKeys.reading,
                            style: AppTypeScale.ui14.copyWith(
                              fontFamily: AppFonts.jp,
                              color: tokens.text2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (gloss.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              gloss,
                              key: ReviewKeys.gloss,
                              style: AppTypeScale.definicao,
                              textAlign: TextAlign.center,
                            ),
                          ],
                          if (card.userNote != null &&
                              card.userNote!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              card.userNote!,
                              key: ReviewKeys.note,
                              style: AppTypeScale.definicao,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                if (!_revealed)
                  FilledButton(
                    key: ReviewKeys.reveal,
                    onPressed: _reveal,
                    child: const Text('Revelar'),
                  )
                else
                  Row(
                    children: [
                      for (final rating in ReviewRating.values)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: FilledButton(
                              key: ReviewKeys.rating(rating),
                              style: _ratingStyle(rating, tokens),
                              onPressed: () => _rate(rating),
                              child: _RatingButtonLabel(
                                rating: rating,
                                interval: previews?[rating],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

ButtonStyle _ratingStyle(ReviewRating rating, MangaJpTokens tokens) {
  final (Color border, Color fill, Color fg) = switch (rating) {
    ReviewRating.again => (tokens.coral, tokens.srsErreiFill, tokens.text),
    ReviewRating.hard => (tokens.border, tokens.surface, tokens.text),
    ReviewRating.good => (tokens.mint, tokens.srsBomFill, tokens.text),
    ReviewRating.easy => (tokens.border, tokens.surface, tokens.text),
  };
  // `side` must be set here: FilledButton.styleFrom merges with
  // filledButtonTheme, whose coral outline would otherwise win over
  // `shape.side` for Hard/Easy (tokens: border + surface only).
  return FilledButton.styleFrom(
    backgroundColor: fill,
    foregroundColor: fg,
    minimumSize: const Size.fromHeight(AppTargets.respostaReviewMobile),
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
    side: BorderSide(color: border),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.dockAcaoBusca),
    ),
  );
}

class _RatingButtonLabel extends StatelessWidget {
  const _RatingButtonLabel({required this.rating, this.interval});

  final ReviewRating rating;
  final String? interval;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final intervalColor = switch (rating) {
      ReviewRating.again => tokens.coralText,
      ReviewRating.good => tokens.mint,
      ReviewRating.hard || ReviewRating.easy => tokens.text3,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_ratingLabel(rating), textAlign: TextAlign.center),
        if (interval != null)
          Text(
            interval!,
            key: ReviewKeys.interval(rating),
            textAlign: TextAlign.center,
            style: AppTypeScale.mono10.copyWith(color: intervalColor),
          ),
      ],
    );
  }
}

String _ratingLabel(ReviewRating rating) => switch (rating) {
  ReviewRating.again => 'Again',
  ReviewRating.hard => 'Hard',
  ReviewRating.good => 'Good',
  ReviewRating.easy => 'Easy',
};
