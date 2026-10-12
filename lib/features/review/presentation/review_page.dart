import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/shell/kbd_chip.dart';
import '../../../core/shell/shell_layout.dart';
import '../../../core/shell/shell_nav.dart';
import '../../../core/shell/shell_registry.dart';
import '../../../core/shell/task_dock.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/review_labels.dart';
import '../domain/review_rating.dart';
import 'review_controller.dart';

/// Keys for `/review` (front, reveal, ratings, empty / done).
abstract final class ReviewKeys {
  static const empty = Key('review-empty');
  static const done = Key('review-done');
  static const card = Key('review-card');
  static const remaining = Key('review-remaining');
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
/// per study-day). Front is the lemma; Mostrar shows kana + JMdict
/// gloss, then Errei / Difícil / Bom / Fácil with DS interval captions
/// (`srs.*.interval`). Bom is the only filled primary. Again/Hard go to
/// the back of this session; Good/Easy leave it.
class ReviewPage extends ConsumerWidget {
  const ReviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(reviewSessionProvider);

    return view.when(
      data: (item) {
        if (item == null || item.isEmpty) {
          return const _ReviewEndState(
            statusKey: ReviewKeys.empty,
            title: ReviewLabels.empty,
            hint: ReviewLabels.emptyHint,
          );
        }
        if (item.isDone) {
          return const _ReviewEndState(
            statusKey: ReviewKeys.done,
            title: ReviewLabels.done,
            hint: ReviewLabels.doneHint,
          );
        }
        return _ReviewCardBody(
          key: ValueKey('${item.card!.cardId}-${item.showSeq}'),
          view: item,
        );
      },
      loading: () => const _ReviewScaffold(
        meta: ReviewLabels.sessao,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _ReviewScaffold(
        meta: ReviewLabels.sessao,
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

class _ReviewEndState extends StatelessWidget {
  const _ReviewEndState({
    required this.statusKey,
    required this.title,
    required this.hint,
  });

  final Key statusKey;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return _ReviewScaffold(
      meta: ReviewLabels.sessao,
      actions: [
        ShellAction(
          id: 'close',
          label: ReviewLabels.fechar,
          shortcut: 'Esc',
          onPressed: () => popTaskOrHome(context),
        ),
      ],
      child: _ReviewStatus(statusKey: statusKey, title: title, hint: hint),
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
    this.metaHint,
    this.actions = const [],
  });

  final Widget child;
  final String meta;
  final String? metaHint;
  final List<ShellAction> actions;

  @override
  Widget build(BuildContext context) {
    final wide = ShellLayout.isWide(context);
    return ShellBinder(
      task: ShellTask(meta: meta, metaHint: metaHint, actions: actions),
      child: Column(
        children: [
          Expanded(child: child),
          if (!wide)
            TaskDock(
              meta: meta,
              metaHint: metaHint,
              leading: [
                DockIconButton(
                  key: ShellKeys.dockAction('close'),
                  icon: Icons.close,
                  tooltip: ReviewLabels.fechar,
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
    final wide = ShellLayout.isWide(context);
    final card = widget.view.card!;
    final gloss = widget.view.glossText;
    final kana = widget.view.reading;
    final showKana = _revealed && kana.isNotEmpty && kana != card.lemma;
    final remaining = ReviewLabels.restantes(widget.view.remaining);
    final actions = <ShellAction>[
      ShellAction(
        id: 'close',
        label: ReviewLabels.fechar,
        shortcut: 'Esc',
        onPressed: () => popTaskOrHome(context),
      ),
      if (!_revealed)
        ShellAction(
          id: 'mostrar',
          label: ReviewLabels.mostrar,
          shortcut: 'Espaço',
          primary: true,
          onPressed: _reveal,
        ),
    ];

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.space): ShellShortcutIntent('space'),
        SingleActivator(LogicalKeyboardKey.digit1): ShellShortcutIntent('1'),
        SingleActivator(LogicalKeyboardKey.digit2): ShellShortcutIntent('2'),
        SingleActivator(LogicalKeyboardKey.digit3): ShellShortcutIntent('3'),
        SingleActivator(LogicalKeyboardKey.digit4): ShellShortcutIntent('4'),
      },
      child: Actions(
        actions: {
          ShellShortcutIntent: ShellPassthroughAction(
            shouldPassThrough: () => ShellShortcuts.isTyping,
            onInvoke: (intent) {
              switch (intent.id) {
                case 'space':
                  _reveal();
                case '1':
                  _rate(ReviewRating.again);
                case '2':
                  _rate(ReviewRating.hard);
                case '3':
                  _rate(ReviewRating.good);
                case '4':
                  _rate(ReviewRating.easy);
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: _ReviewScaffold(
            meta: card.lemma,
            metaHint: remaining,
            actions: actions,
            child: Padding(
              padding: wide
                  ? const EdgeInsets.fromLTRB(48, 36, 48, 24)
                  : const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        // Desktop card max width. Deck / not in tokens.json.
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: _ReviewCard(
                          lemma: card.lemma,
                          remaining: remaining,
                          reading: showKana ? kana : null,
                          gloss: _revealed && gloss.isNotEmpty ? gloss : null,
                          note:
                              _revealed &&
                                  card.userNote != null &&
                                  card.userNote!.isNotEmpty
                              ? card.userNote
                              : null,
                          wide: wide,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_revealed)
                    FilledButton(
                      key: ReviewKeys.reveal,
                      onPressed: _reveal,
                      style: FilledButton.styleFrom(
                        minimumSize: Size.fromHeight(
                          wide
                              ? AppTargets.min
                              : AppTargets.respostaReviewMobile,
                        ),
                      ),
                      child: const Text(ReviewLabels.mostrar),
                    )
                  else
                    _RatingRow(wide: wide, onRate: _rate),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.lemma,
    required this.remaining,
    required this.wide,
    this.reading,
    this.gloss,
    this.note,
  });

  final String lemma;
  final String remaining;
  final String? reading;
  final String? gloss;
  final String? note;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Material(
      key: ReviewKeys.card,
      color: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sheetReview),
        side: BorderSide(color: tokens.border),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: wide ? 32 : 20,
          vertical: wide ? 36 : 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  ReviewLabels.sessao.toUpperCase(),
                  style: AppTypeScale.mono10.copyWith(
                    color: tokens.text3,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Text(
                  remaining,
                  key: ReviewKeys.remaining,
                  style: AppTypeScale.metadados12.copyWith(color: tokens.text3),
                ),
              ],
            ),
            SizedBox(height: wide ? 28 : 20),
            Text(
              lemma,
              key: ReviewKeys.lemma,
              style: wide
                  ? AppTypeScale.reviewDesktopJp
                  : AppTypeScale.reviewMobileJp,
              textAlign: TextAlign.center,
            ),
            if (reading != null) ...[
              const SizedBox(height: 8),
              Text(
                reading!,
                key: ReviewKeys.reading,
                style: AppTypeScale.ui14.copyWith(
                  fontFamily: AppFonts.jp,
                  color: tokens.text2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (gloss != null) ...[
              const SizedBox(height: 16),
              Text(
                gloss!,
                key: ReviewKeys.gloss,
                style: AppTypeScale.definicao.copyWith(color: tokens.text2),
                textAlign: TextAlign.center,
              ),
            ],
            if (note != null) ...[
              const SizedBox(height: 16),
              Text(
                note!,
                key: ReviewKeys.note,
                style: AppTypeScale.definicao.copyWith(color: tokens.text3),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewStatus extends StatelessWidget {
  const _ReviewStatus({
    required this.statusKey,
    required this.title,
    required this.hint,
  });

  final Key statusKey;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final wide = ShellLayout.isWide(context);
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
                  '復習',
                  style:
                      (wide
                              ? AppTypeScale.reviewDesktopJp
                              : AppTypeScale.reviewMobileJp)
                          .copyWith(
                            color: tokens.coral.withValues(alpha: 0.08),
                            height: 1,
                          ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                key: statusKey,
                textAlign: TextAlign.center,
                style: AppTypeScale.tituloTela,
              ),
              const SizedBox(height: 8),
              Text(
                hint,
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

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.wide, required this.onRate});

  final bool wide;
  final ValueChanged<ReviewRating> onRate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final rating in ReviewRating.values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilledButton(
                key: ReviewKeys.rating(rating),
                style: _ratingStyle(rating, context.tokens, wide: wide),
                onPressed: () => onRate(rating),
                child: _RatingButtonLabel(
                  rating: rating,
                  interval: ReviewLabels.interval(rating),
                  wide: wide,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

ButtonStyle _ratingStyle(
  ReviewRating rating,
  MangaJpTokens tokens, {
  required bool wide,
}) {
  // Bom is the only filled primary. Errei keeps the coral border from
  // `srs.errei` but uses `surface` so two buttons are not highlighted.
  final (Color border, Color fill, Color fg) = switch (rating) {
    ReviewRating.again => (tokens.coral, tokens.surface, tokens.text),
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
    surfaceTintColor: Colors.transparent,
    minimumSize: Size.fromHeight(
      wide ? AppTargets.min : AppTargets.respostaReviewMobile,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
    side: BorderSide(color: border),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.dockAcaoBusca),
    ),
  );
}

class _RatingButtonLabel extends StatelessWidget {
  const _RatingButtonLabel({
    required this.rating,
    required this.wide,
    required this.interval,
  });

  final ReviewRating rating;
  final String interval;
  final bool wide;

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
        Text(ReviewLabels.rating(rating), textAlign: TextAlign.center),
        Text(
          interval,
          key: ReviewKeys.interval(rating),
          textAlign: TextAlign.center,
          style: AppTypeScale.mono10.copyWith(color: intervalColor),
        ),
        if (wide) ...[
          const SizedBox(height: 4),
          KbdChip(label: ReviewLabels.ratingShortcut(rating)),
        ],
      ],
    );
  }
}
