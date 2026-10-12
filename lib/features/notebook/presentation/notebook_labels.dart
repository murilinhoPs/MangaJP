import '../../words/domain/word_state.dart';

/// Portuguese Caderno copy (list, search, empty, word detail).
abstract final class NotebookLabels {
  static const todos = 'Todos';
  static const searchHint = 'Lema ou leitura';
  static const empty = 'Nenhuma palavra.';
  static const emptyHint = 'Salve uma palavra no lookup para vê-la aqui.';
  static const noResults = 'Nenhum resultado.';
  static const noResultsHint = 'Tente outro lema, leitura ou filtro.';
  static const watermark = '単語';
  static const frase = 'Frase';
  static const verPagina = 'Ver página';
  static const aprender = 'Aprender';
  static const conhecido = 'Conhecido';
  static const ignorar = 'Ignorar';
  static const removerCard = 'Remover card';
  static const removerDoCaderno = 'Remover do Caderno';

  /// Portuguese Caderno label for a listed [WordState].
  static String state(WordState state) {
    return switch (state) {
      WordState.saved => 'Salvo',
      WordState.learning => 'Aprendendo',
      WordState.known => 'Conhecido',
      WordState.ignored => 'Ignorado',
      WordState.unknown => '',
    };
  }
}

/// Portuguese Caderno label for a listed [WordState].
String notebookStateLabel(WordState state) => NotebookLabels.state(state);
