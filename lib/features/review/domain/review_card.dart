import '../../../core/srs/card_srs_state.dart';

/// One due vocab card for `/review`. Gloss is loaded from JMdict by [seq].
class ReviewCard {
  const ReviewCard({
    required this.cardId,
    required this.wordId,
    required this.seq,
    required this.lemma,
    required this.reading,
    required this.srs,
    this.isDrill = false,
  });

  final String cardId;
  final String wordId;
  final int seq;
  final String lemma;
  final String reading;
  final CardSrsState srs;

  /// Next answer of this card on the current study-day is drill (`is_drill=1`):
  /// it does not change SRS, and rating buttons hide the interval preview.
  final bool isDrill;

  ReviewCard asDrill() {
    if (isDrill) {
      return this;
    }
    return ReviewCard(
      cardId: cardId,
      wordId: wordId,
      seq: seq,
      lemma: lemma,
      reading: reading,
      srs: srs,
      isDrill: true,
    );
  }
}
