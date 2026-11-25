import 'dart:convert';

import '../../../core/srs/card_srs_state.dart';
import '../../../core/utils/graphemes.dart';
import '../../flashcards/domain/flashcard.dart';
import '../../flashcards/domain/suspend_reason.dart';
import '../../words/domain/word_state.dart';
import 'backup_document.dart';
import 'backup_exception.dart';
import 'backup_labels.dart';

final _wordStates = {for (final value in WordState.values) value.name};
final _cardKinds = {for (final value in FlashcardKind.values) value.name};
final _cardPhases = {for (final value in CardPhase.values) value.name};
final _suspendReasons = {for (final value in SuspendReason.values) value.name};

/// Encodes [doc] as pretty JSON. Keys are snake_case, matching SQL columns.
String encodeBackupJson(BackupDocument doc) {
  return const JsonEncoder.withIndent('  ').convert(_documentToJson(doc));
}

/// Parses and validates a backup file. Does not write to the database.
///
/// Rejects a [BackupDocument.formatVersion] outside
/// [[kMinBackupFormatVersion], [kBackupFormatVersion]] and a
/// `schema_version` greater than [currentSchemaVersion]. A missing
/// `format_version` is treated as 1 (schema 8 fixtures from before this
/// field existed). Missing `saved_kanji` / `crop_words` are empty lists.
BackupDocument decodeBackupJson(
  String source, {
  required int currentSchemaVersion,
}) {
  late final Object? decoded;
  try {
    decoded = jsonDecode(source);
  } on FormatException {
    throw const BackupRejectedException(BackupLabels.invalidFile);
  }
  if (decoded is! Map) {
    throw const BackupRejectedException(BackupLabels.invalidFile);
  }
  final map = _stringKeyMap(decoded);
  if (map == null) {
    throw const BackupRejectedException(BackupLabels.invalidFile);
  }

  final formatVersion =
      _optionalInt(map, 'format_version') ?? kMinBackupFormatVersion;
  if (formatVersion < kMinBackupFormatVersion ||
      formatVersion > kBackupFormatVersion) {
    throw BackupRejectedException(BackupLabels.unknownFormat(formatVersion));
  }

  final schemaVersion = _requiredInt(map, 'schema_version');
  if (schemaVersion < 1) {
    throw const BackupRejectedException(BackupLabels.invalidFile);
  }
  if (schemaVersion > currentSchemaVersion) {
    throw BackupRejectedException(
      BackupLabels.unknownSchema(
        fileSchema: schemaVersion,
        appSchema: currentSchemaVersion,
      ),
    );
  }

  final exportedAt = map.containsKey('exported_at')
      ? _requiredDateTime(map, 'exported_at')
      : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  return BackupDocument(
    formatVersion: formatVersion,
    schemaVersion: schemaVersion,
    exportedAt: exportedAt,
    words: [for (final row in _objectList(map, 'words')) _wordFromJson(row)],
    wordStates: [
      for (final row in _objectList(map, 'word_states'))
        _wordStateFromJson(row),
    ],
    cards: [for (final row in _objectList(map, 'cards')) _cardFromJson(row)],
    cardSrs: [
      for (final row in _objectList(map, 'card_srs')) _cardSrsFromJson(row),
    ],
    reviewLogs: [
      for (final row in _objectList(map, 'review_logs'))
        _reviewLogFromJson(row),
    ],
    cropWords: [
      for (final row in _objectList(map, 'crop_words')) _cropWordFromJson(row),
    ],
    savedKanji: [
      for (final row in _objectList(map, 'saved_kanji'))
        _savedKanjiFromJson(row),
    ],
  );
}

Map<String, Object?> _documentToJson(BackupDocument doc) {
  return <String, Object?>{
    'format_version': doc.formatVersion,
    'schema_version': doc.schemaVersion,
    'exported_at': _date(doc.exportedAt),
    'words': [
      for (final word in doc.words)
        <String, Object?>{
          'id': word.id,
          'seq': word.seq,
          'lemma': word.lemma,
          'reading': word.reading,
          'user_note': word.userNote,
          'lemma_key': word.lemmaKey,
          'created_at': _date(word.createdAt),
        },
    ],
    'word_states': [
      for (final state in doc.wordStates)
        <String, Object?>{
          'word_id': state.wordId,
          'state': state.state,
          'updated_at': _date(state.updatedAt),
        },
    ],
    'cards': [
      for (final card in doc.cards)
        <String, Object?>{
          'id': card.id,
          'word_id': card.wordId,
          'kind': card.kind,
          'created_at': _date(card.createdAt),
          'suspend_reason': card.suspendReason,
        },
    ],
    'card_srs': [
      for (final srs in doc.cardSrs)
        <String, Object?>{
          'card_id': srs.cardId,
          'ease_factor': srs.easeFactor,
          'interval_days': srs.intervalDays,
          'repetitions': srs.repetitions,
          'due_at': _date(srs.dueAt),
          'phase': srs.phase,
          'engine_id': srs.engineId,
        },
    ],
    'review_logs': [
      for (final log in doc.reviewLogs)
        <String, Object?>{
          'id': log.id,
          'card_id': log.cardId,
          'rated_at': _date(log.ratedAt),
          'rating': log.rating,
          'quality': log.quality,
          'engine_id': log.engineId,
          'is_drill': log.isDrill,
        },
    ],
    'crop_words': [
      for (final link in doc.cropWords)
        <String, Object?>{
          'crop_id': link.cropId,
          'word_id': link.wordId,
          'created_at': _date(link.createdAt),
        },
    ],
    'saved_kanji': [
      for (final kanji in doc.savedKanji)
        <String, Object?>{
          'literal': kanji.literal,
          'saved_at': _date(kanji.savedAt),
          'origin_page_id': kanji.originPageId,
        },
    ],
  };
}

BackupWord _wordFromJson(Map<String, Object?> row) {
  final lemma = _requiredString(row, 'lemma');
  final lemmaKey = _optionalString(row, 'lemma_key');
  return BackupWord(
    id: _requiredString(row, 'id'),
    seq: _requiredInt(row, 'seq'),
    lemma: lemma,
    reading: _requiredString(row, 'reading'),
    userNote: _optionalString(row, 'user_note'),
    lemmaKey: (lemmaKey == null || lemmaKey.isEmpty)
        ? stripVariationSelectors(lemma)
        : lemmaKey,
    createdAt: _requiredDateTime(row, 'created_at'),
  );
}

BackupWordState _wordStateFromJson(Map<String, Object?> row) {
  return BackupWordState(
    wordId: _requiredString(row, 'word_id'),
    state: _requiredEnum(row, 'state', _wordStates),
    updatedAt: _requiredDateTime(row, 'updated_at'),
  );
}

BackupCard _cardFromJson(Map<String, Object?> row) {
  return BackupCard(
    id: _requiredString(row, 'id'),
    wordId: _requiredString(row, 'word_id'),
    kind: _requiredEnum(row, 'kind', _cardKinds),
    createdAt: _requiredDateTime(row, 'created_at'),
    suspendReason: _optionalEnum(row, 'suspend_reason', _suspendReasons),
  );
}

BackupCardSrs _cardSrsFromJson(Map<String, Object?> row) {
  return BackupCardSrs(
    cardId: _requiredString(row, 'card_id'),
    easeFactor: _requiredDouble(row, 'ease_factor'),
    intervalDays: _requiredDouble(row, 'interval_days'),
    repetitions: _requiredInt(row, 'repetitions'),
    dueAt: _requiredDateTime(row, 'due_at'),
    phase: _requiredEnum(row, 'phase', _cardPhases),
    engineId: _requiredString(row, 'engine_id'),
  );
}

BackupReviewLog _reviewLogFromJson(Map<String, Object?> row) {
  return BackupReviewLog(
    id: _requiredString(row, 'id'),
    cardId: _requiredString(row, 'card_id'),
    ratedAt: _requiredDateTime(row, 'rated_at'),
    rating: _requiredInt(row, 'rating'),
    quality: _requiredInt(row, 'quality'),
    engineId: _requiredString(row, 'engine_id'),
    isDrill: _requiredInt(row, 'is_drill'),
  );
}

BackupCropWord _cropWordFromJson(Map<String, Object?> row) {
  return BackupCropWord(
    cropId: _requiredString(row, 'crop_id'),
    wordId: _requiredString(row, 'word_id'),
    createdAt: _requiredDateTime(row, 'created_at'),
  );
}

BackupSavedKanji _savedKanjiFromJson(Map<String, Object?> row) {
  return BackupSavedKanji(
    literal: _requiredString(row, 'literal'),
    savedAt: _requiredDateTime(row, 'saved_at'),
    originPageId: _optionalString(row, 'origin_page_id'),
  );
}

String _date(DateTime value) => value.toUtc().toIso8601String();

Map<String, Object?>? _stringKeyMap(Map<dynamic, dynamic> raw) {
  final out = <String, Object?>{};
  for (final entry in raw.entries) {
    final key = entry.key;
    if (key is! String) {
      return null;
    }
    out[key] = entry.value;
  }
  return out;
}

List<Map<String, Object?>> _objectList(Map<String, Object?> map, String key) {
  if (!map.containsKey(key) || map[key] == null) {
    return const [];
  }
  final value = map[key];
  if (value is! List) {
    throw const BackupRejectedException(BackupLabels.invalidFile);
  }
  final rows = <Map<String, Object?>>[];
  for (final item in value) {
    if (item is! Map) {
      throw const BackupRejectedException(BackupLabels.invalidFile);
    }
    final row = _stringKeyMap(item);
    if (row == null) {
      throw const BackupRejectedException(BackupLabels.invalidFile);
    }
    rows.add(row);
  }
  return rows;
}

int _requiredInt(Map<String, Object?> map, String key) {
  final value = _optionalInt(map, key);
  if (value == null) {
    throw const BackupRejectedException(BackupLabels.invalidFile);
  }
  return value;
}

int? _optionalInt(Map<String, Object?> map, String key) {
  if (!map.containsKey(key) || map[key] == null) {
    return null;
  }
  final value = _asInt(map[key]);
  if (value == null) {
    throw const BackupRejectedException(BackupLabels.invalidFile);
  }
  return value;
}

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num && value == value.roundToDouble()) {
    return value.toInt();
  }
  return null;
}

double _requiredDouble(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is num) {
    return value.toDouble();
  }
  throw const BackupRejectedException(BackupLabels.invalidFile);
}

String _requiredString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is String) {
    return value;
  }
  throw const BackupRejectedException(BackupLabels.invalidFile);
}

String _requiredEnum(
  Map<String, Object?> map,
  String key,
  Set<String> allowed,
) {
  final value = _requiredString(map, key);
  if (!allowed.contains(value)) {
    throw const BackupRejectedException(BackupLabels.invalidFile);
  }
  return value;
}

String? _optionalEnum(
  Map<String, Object?> map,
  String key,
  Set<String> allowed,
) {
  final value = _optionalString(map, key);
  if (value == null || value.isEmpty) {
    return null;
  }
  if (!allowed.contains(value)) {
    throw const BackupRejectedException(BackupLabels.invalidFile);
  }
  return value;
}

String? _optionalString(Map<String, Object?> map, String key) {
  if (!map.containsKey(key) || map[key] == null) {
    return null;
  }
  final value = map[key];
  if (value is String) {
    return value;
  }
  throw const BackupRejectedException(BackupLabels.invalidFile);
}

DateTime _requiredDateTime(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return parsed.toUtc();
    }
  }
  throw const BackupRejectedException(BackupLabels.invalidFile);
}
