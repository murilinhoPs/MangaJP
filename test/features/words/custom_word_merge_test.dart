import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/features/words/domain/custom_word_merge.dart';

void main() {
  group('mergeUserNotes', () {
    test('keeps the primary note when the incoming one is the same', () {
      expect(mergeUserNotes('kuzu ivs', ['kuzu ivs']), 'kuzu ivs');
      expect(mergeUserNotes('  kuzu ivs  ', ['kuzu ivs']), 'kuzu ivs');
    });

    test('appends a distinct incoming note after the primary', () {
      expect(mergeUserNotes('kuzu ivs', ['plain kuzu']), 'kuzu ivs\nplain kuzu');
    });

    test('skips empty and duplicate others, survivor first', () {
      expect(
        mergeUserNotes('alpha', ['', '  ', 'alpha', 'beta', 'beta', null]),
        'alpha\nbeta',
      );
      expect(
        mergeUserNotes('alpha\nbeta', ['beta', 'alpha', 'gamma']),
        'alpha\nbeta\ngamma',
      );
    });

    test('returns null when every note is empty', () {
      expect(mergeUserNotes(null, [null, '', '  ']), isNull);
      expect(mergeUserNotes('  ', const []), isNull);
    });
  });

  group('pickCustomWordSurvivor', () {
    final older = DateTime.utc(2026, 1, 1);
    final newer = DateTime.utc(2026, 2, 1);
    final earlyReview = DateTime.utc(2026, 3, 1);
    final lateReview = DateTime.utc(2026, 4, 1);

    test('picks the row with more repetitions', () {
      final winner = CustomWordMergeCandidate(
        id: 'custom:b',
        createdAt: newer,
        repetitions: 5,
      );
      expect(
        pickCustomWordSurvivor([
          CustomWordMergeCandidate(id: 'custom:a', createdAt: older),
          winner,
        ]).id,
        'custom:b',
      );
    });

    test('equal reps: later review wins', () {
      expect(
        pickCustomWordSurvivor([
          CustomWordMergeCandidate(
            id: 'custom:a',
            createdAt: older,
            repetitions: 2,
            latestReview: earlyReview,
          ),
          CustomWordMergeCandidate(
            id: 'custom:b',
            createdAt: older,
            repetitions: 2,
            latestReview: lateReview,
          ),
        ]).id,
        'custom:b',
      );
    });

    test('equal progress: oldest createdAt wins', () {
      expect(
        pickCustomWordSurvivor([
          CustomWordMergeCandidate(id: 'custom:b', createdAt: newer),
          CustomWordMergeCandidate(id: 'custom:a', createdAt: older),
        ]).id,
        'custom:a',
      );
    });

    test('a review beats no review when reps are equal', () {
      expect(
        pickCustomWordSurvivor([
          CustomWordMergeCandidate(
            id: 'custom:a',
            createdAt: older,
            repetitions: 0,
          ),
          CustomWordMergeCandidate(
            id: 'custom:b',
            createdAt: newer,
            repetitions: 0,
            latestReview: lateReview,
          ),
        ]).id,
        'custom:b',
      );
    });
  });
}
