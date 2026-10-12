import 'review_rating.dart';

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
}
