import 'review_rating.dart';

/// Placeholder until motif defines Review re-queue copy. `{n}` is
/// [HomeReviewCounts.waiting] when the in-memory pass ended and the DB
/// still has cards due now. No Brief/DS string for this yet.
const kReviewRequeuedLabel = '[motif] {n} voltam agora';

/// Portuguese copy for `/review` (Design Deck Review).
abstract final class ReviewLabels {
  static const sessao = 'Sessão';
  static const mostrar = 'Mostrar';
  static const fechar = 'Fechar';
  static const empty = 'Nenhum card para revisar.';
  static const emptyHint = 'A fila de hoje está vazia.';
  static const done = 'Sessão concluída.';
  static const doneHint = 'Nada mais na fila agora.';
  static const errei = 'Errei';
  static const dificil = 'Difícil';
  static const bom = 'Bom';
  static const facil = 'Fácil';

  static String restantes(int count) =>
      count == 1 ? '1 restante' : '$count restantes';

  static String rating(ReviewRating rating) => switch (rating) {
    ReviewRating.again => errei,
    ReviewRating.hard => dificil,
    ReviewRating.good => bom,
    ReviewRating.easy => facil,
  };

  static String ratingShortcut(ReviewRating rating) => switch (rating) {
    ReviewRating.again => '1',
    ReviewRating.hard => '2',
    ReviewRating.good => '3',
    ReviewRating.easy => '4',
  };

  /// Captions from `tokens.json` `srs.*.interval`. Always on the rating
  /// row (including drill). Live `sm2-jr@1` day copy lives in
  /// `interval_preview.dart`.
  static String interval(ReviewRating rating) => switch (rating) {
    ReviewRating.again => 'agora',
    ReviewRating.hard => '10 min',
    ReviewRating.good => '1 dia',
    ReviewRating.easy => '4 dias',
  };
}
