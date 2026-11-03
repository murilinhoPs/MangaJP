import '../../words/domain/word_state.dart';

/// Portuguese Caderno copy (list, search, empty, word detail, kanji tab).
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
  static const tabWords = 'Palavras';
  static const tabKanji = 'Kanji';
  static const kanjiSearchHint = 'Kanji, leitura ou significado';
  static const kanjiEmpty = 'Nenhum kanji.';
  static const kanjiEmptyHint = 'Salve um kanji no lookup para vê-lo aqui.';
  static const kanjiNoResultsHint =
      'Tente outro kanji, leitura ou significado.';
  static const kanjiWatermark = '漢字';
  static const kanjiOn = 'ON';
  static const kanjiKun = 'KUN';
  static const kanjiMeanings = 'SIGNIFICADOS';
  static const kanjiStrokes = 'TRAÇOS';
  static const kanjiWords = 'PALAVRAS DO CADERNO';
  static const salvarKanji = 'Salvar kanji';
  static const kanjiRemoveBody = 'O kanji será apagado do Caderno.';

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
