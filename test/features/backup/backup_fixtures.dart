import 'package:manga_jp/features/backup/domain/backup_document.dart';

const kEatCreated = '2026-01-02T03:04:05.000Z';
const kEatUpdated = '2026-01-03T03:04:05.000Z';
const kDue = '2026-01-10T03:04:05.000Z';
const kRated = '2026-01-04T03:04:05.000Z';
const kKanjiSaved = '2026-01-05T00:00:00.000Z';
const kExported = '2026-01-06T00:00:00.000Z';

const kCropLinked = '2026-01-02T03:05:00.000Z';

BackupDocument sampleDocument({
  int formatVersion = kBackupFormatVersion,
  int schemaVersion = 10,
  List<BackupCropWord>? cropWords,
  List<BackupSavedKanji>? savedKanji,
}) {
  return BackupDocument(
    formatVersion: formatVersion,
    schemaVersion: schemaVersion,
    exportedAt: DateTime.parse(kExported).toUtc(),
    words: [
      BackupWord(
        id: 'eat',
        seq: 1414310,
        lemma: '食べる',
        reading: 'たべる',
        userNote: 'comer',
        lemmaKey: '食べる',
        createdAt: DateTime.parse(kEatCreated).toUtc(),
      ),
    ],
    wordStates: [
      BackupWordState(
        wordId: 'eat',
        state: 'learning',
        updatedAt: DateTime.parse(kEatUpdated).toUtc(),
      ),
    ],
    cards: [
      BackupCard(
        id: 'card-eat',
        wordId: 'eat',
        kind: 'vocab',
        createdAt: DateTime.parse(kEatCreated).toUtc(),
      ),
    ],
    cardSrs: [
      BackupCardSrs(
        cardId: 'card-eat',
        easeFactor: 2.5,
        intervalDays: 1,
        repetitions: 1,
        dueAt: DateTime.parse(kDue).toUtc(),
        phase: 'learning',
        engineId: 'sm2-jr@1',
      ),
    ],
    reviewLogs: [
      BackupReviewLog(
        id: 'log-1',
        cardId: 'card-eat',
        ratedAt: DateTime.parse(kRated).toUtc(),
        rating: 3,
        quality: 3,
        engineId: 'sm2-jr@1',
        isDrill: 0,
      ),
    ],
    cropWords: cropWords ?? const [],
    savedKanji:
        savedKanji ??
        [
          BackupSavedKanji(
            literal: '食',
            savedAt: DateTime.parse(kKanjiSaved).toUtc(),
            originPageId: 'page-a',
          ),
        ],
  );
}

BackupCropWord sampleCropWord({
  String cropId = 'crop-a',
  String wordId = 'eat',
}) {
  return BackupCropWord(
    cropId: cropId,
    wordId: wordId,
    createdAt: DateTime.parse(kCropLinked).toUtc(),
  );
}

String sampleJson({
  int formatVersion = kBackupFormatVersion,
  int schemaVersion = 10,
  bool includeSavedKanji = true,
  bool includeCropWords = false,
  String? extraKanji,
}) {
  final kanji = includeSavedKanji
      ? '''
  "saved_kanji": [
    {
      "literal": "食",
      "saved_at": "$kKanjiSaved",
      "origin_page_id": "page-a"
    }${extraKanji ?? ''}
  ]'''
      : null;
  final cropWords = includeCropWords
      ? '''
  "crop_words": [
    {
      "crop_id": "crop-a",
      "word_id": "eat",
      "created_at": "$kCropLinked"
    }
  ]'''
      : null;
  final extras = <String>[?cropWords, ?kanji];
  final tail = extras.isEmpty ? '' : ',\n${extras.join(',\n')}';
  return '''
{
  "format_version": $formatVersion,
  "schema_version": $schemaVersion,
  "exported_at": "$kExported",
  "words": [
    {
      "id": "eat",
      "seq": 1414310,
      "lemma": "食べる",
      "reading": "たべる",
      "user_note": "comer",
      "lemma_key": "食べる",
      "created_at": "$kEatCreated"
    }
  ],
  "word_states": [
    {
      "word_id": "eat",
      "state": "learning",
      "updated_at": "$kEatUpdated"
    }
  ],
  "cards": [
    {
      "id": "card-eat",
      "word_id": "eat",
      "kind": "vocab",
      "created_at": "$kEatCreated",
      "suspend_reason": null
    }
  ],
  "card_srs": [
    {
      "card_id": "card-eat",
      "ease_factor": 2.5,
      "interval_days": 1,
      "repetitions": 1,
      "due_at": "$kDue",
      "phase": "learning",
      "engine_id": "sm2-jr@1"
    }
  ],
  "review_logs": [
    {
      "id": "log-1",
      "card_id": "card-eat",
      "rated_at": "$kRated",
      "rating": 3,
      "quality": 3,
      "engine_id": "sm2-jr@1",
      "is_drill": 0
    }
  ]$tail
}
''';
}

String schema8Json() =>
    sampleJson(formatVersion: 1, schemaVersion: 8, includeSavedKanji: false);
