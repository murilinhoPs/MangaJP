/// Envelope version of the JSON file, independent of Drift [schemaVersion].
const kBackupFormatVersion = 1;

/// Caderno + SRS + `saved_kanji` snapshot (F25). No pages, crops, or images.
class BackupDocument {
  const BackupDocument({
    required this.formatVersion,
    required this.schemaVersion,
    required this.exportedAt,
    required this.words,
    required this.wordStates,
    required this.cards,
    required this.cardSrs,
    required this.reviewLogs,
    required this.savedKanji,
  });

  final int formatVersion;
  final int schemaVersion;
  final DateTime exportedAt;
  final List<BackupWord> words;
  final List<BackupWordState> wordStates;
  final List<BackupCard> cards;
  final List<BackupCardSrs> cardSrs;
  final List<BackupReviewLog> reviewLogs;
  final List<BackupSavedKanji> savedKanji;
}

class BackupWord {
  const BackupWord({
    required this.id,
    required this.seq,
    required this.lemma,
    required this.reading,
    required this.lemmaKey,
    required this.createdAt,
    this.userNote,
  });

  final String id;
  final int seq;
  final String lemma;
  final String reading;
  final String? userNote;
  final String lemmaKey;
  final DateTime createdAt;
}

class BackupWordState {
  const BackupWordState({
    required this.wordId,
    required this.state,
    required this.updatedAt,
  });

  final String wordId;
  final String state;
  final DateTime updatedAt;
}

class BackupCard {
  const BackupCard({
    required this.id,
    required this.wordId,
    required this.kind,
    required this.createdAt,
    this.suspendReason,
  });

  final String id;
  final String wordId;
  final String kind;
  final DateTime createdAt;
  final String? suspendReason;
}

class BackupCardSrs {
  const BackupCardSrs({
    required this.cardId,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.dueAt,
    required this.phase,
    required this.engineId,
  });

  final String cardId;
  final double easeFactor;
  final double intervalDays;
  final int repetitions;
  final DateTime dueAt;
  final String phase;
  final String engineId;
}

class BackupReviewLog {
  const BackupReviewLog({
    required this.id,
    required this.cardId,
    required this.ratedAt,
    required this.rating,
    required this.quality,
    required this.engineId,
    required this.isDrill,
  });

  final String id;
  final String cardId;
  final DateTime ratedAt;
  final int rating;
  final int quality;
  final String engineId;
  final int isDrill;
}

class BackupSavedKanji {
  const BackupSavedKanji({
    required this.literal,
    required this.savedAt,
    this.originPageId,
  });

  final String literal;
  final DateTime savedAt;
  final String? originPageId;
}

class BackupRestoreResult {
  const BackupRestoreResult({
    required this.wordCount,
    required this.cardCount,
    required this.savedKanjiCount,
    required this.skippedKanji,
  });

  final int wordCount;
  final int cardCount;
  final int savedKanjiCount;
  final int skippedKanji;
}
