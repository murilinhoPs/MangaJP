enum WordState {
  unknown,
  saved,
  learning,
  known,
  ignored;

  /// Caderno lists these (every stored study state except [unknown]).
  static const listed = <WordState>[saved, learning, known, ignored];

  /// Save must not move these back to [saved].
  bool get isProtected => this == learning || this == known || this == ignored;

  static WordState fromDb(String value) {
    for (final state in WordState.values) {
      if (state.name == value) {
        return state;
      }
    }
    return WordState.unknown;
  }
}
