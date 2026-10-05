import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/srs/card_srs_state.dart';
import 'package:manga_jp/core/srs/sm2_jr.dart';
import 'package:manga_jp/features/review/domain/interval_preview.dart';

void main() {
  final now = DateTime(2026, 10, 2);
  const engine = Sm2JrEngine();

  test('interval 0 is hoje; 1 is 1 dia; anything else is N dias', () {
    expect(intervalPreviewLabel(0), 'hoje');
    expect(intervalPreviewLabel(1), '1 dia');
    expect(intervalPreviewLabel(16), '16 dias');
    expect(intervalPreviewLabel(14), '14 dias');
  });

  test('new card Good preview label is 1 dia from sm2-jr@1', () {
    final prev = initialCardSrsState(now);
    final labels = ratingPreviewLabels(prev, isDrill: false, engine: engine);
    expect(labels, isNotNull);
    expect(labels![ReviewRating.good], '1 dia');
    expect(
      labels[ReviewRating.good],
      intervalPreviewLabel(
        engine.preview(prev, now)[ReviewRating.good]!.intervalDays.truncate(),
      ),
    );
  });

  test('interval 6 EF 2.5 Again is hoje and Easy is 16 dias from sm2-jr@1', () {
    final prev = CardSrsState(
      easeFactor: 2.5,
      intervalDays: 6,
      repetitions: 2,
      dueAt: now,
      phase: CardPhase.review,
    );
    final labels = ratingPreviewLabels(prev, isDrill: false, engine: engine);
    expect(labels, isNotNull);
    expect(labels![ReviewRating.again], 'hoje');
    expect(labels[ReviewRating.easy], '16 dias');
    final preview = engine.preview(prev, now);
    expect(preview[ReviewRating.again]!.intervalDays, 0);
    expect(preview[ReviewRating.easy]!.intervalDays, 16);
  });

  test('drill answers have no preview labels', () {
    final prev = initialCardSrsState(now);
    expect(ratingPreviewLabels(prev, isDrill: true, engine: engine), isNull);
  });
}
