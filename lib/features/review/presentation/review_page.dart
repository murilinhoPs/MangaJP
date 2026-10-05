import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/review_rating.dart';
import 'review_controller.dart';

/// Keys for `/review` (front, reveal, ratings, empty queue).
abstract final class ReviewKeys {
  static const empty = Key('review-empty');
  static const lemma = Key('review-lemma');
  static const reading = Key('review-reading');
  static const gloss = Key('review-gloss');
  static const reveal = Key('review-reveal');

  static Key rating(ReviewRating rating) => Key('review-${rating.name}');
}

/// `/review` — session snapshot of the due queue. Front is the lemma;
/// Revelar shows reading + JMdict gloss, then Again / Hard / Good / Easy.
/// Again/Hard go to the back of this session; Good/Easy leave it.
class ReviewPage extends ConsumerWidget {
  const ReviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(reviewSessionProvider);

    return view.when(
      data: (item) {
        if (item == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Nenhum card para revisar.',
                key: ReviewKeys.empty,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return _ReviewCardBody(
          key: ValueKey('${item.card.cardId}-${item.showSeq}'),
          view: item,
        );
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

class _ReviewCardBody extends ConsumerStatefulWidget {
  const _ReviewCardBody({super.key, required this.view});

  final ReviewView view;

  @override
  ConsumerState<_ReviewCardBody> createState() => _ReviewCardBodyState();
}

class _ReviewCardBodyState extends ConsumerState<_ReviewCardBody> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = widget.view.card;
    final gloss = widget.view.glossText;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
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
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  if (_revealed) ...[
                    const SizedBox(height: 8),
                    Text(
                      card.reading,
                      key: ReviewKeys.reading,
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (gloss.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        gloss,
                        key: ReviewKeys.gloss,
                        style: theme.textTheme.bodyLarge,
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
              onPressed: () => setState(() => _revealed = true),
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
                        onPressed: () {
                          ref
                              .read(reviewSessionProvider.notifier)
                              .answer(rating);
                        },
                        child: Text(_ratingLabel(rating)),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

String _ratingLabel(ReviewRating rating) => switch (rating) {
  ReviewRating.again => 'Again',
  ReviewRating.hard => 'Hard',
  ReviewRating.good => 'Good',
  ReviewRating.easy => 'Easy',
};
