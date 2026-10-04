import '../../words/domain/word_state.dart';

/// Portuguese Caderno label for a listed [WordState].
String notebookStateLabel(WordState state) {
  return switch (state) {
    WordState.saved => 'Salvo',
    WordState.learning => 'Aprendendo',
    WordState.known => 'Conhecido',
    WordState.ignored => 'Ignorado',
    WordState.unknown => '',
  };
}
