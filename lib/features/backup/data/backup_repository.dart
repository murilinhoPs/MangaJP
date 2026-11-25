import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/app_database_provider.dart';
import '../../../core/utils/kanji.dart';
import '../domain/backup_codec.dart';
import '../domain/backup_document.dart';
import '../domain/backup_exception.dart';
import '../domain/backup_labels.dart';

part 'backup_repository.g.dart';

@Riverpod(keepAlive: true)
BackupRepository backupRepository(Ref ref) {
  return BackupRepository(ref.watch(appDatabaseProvider));
}

/// Export / restore Caderno + SRS + `saved_kanji` + `crop_words`.
/// Pages, crops, images, `app_meta`, and the Cloud Vision key are not
/// in the JSON. Restore re-inserts `crop_words` only when the crop still
/// exists (same skip pattern as `origin_page_id`).
class BackupRepository {
  const BackupRepository(this._db);

  final AppDatabase _db;

  int get schemaVersion => _db.schemaVersion;

  Future<BackupDocument> export() async {
    final words = await _db.select(_db.userWords).get();
    final states = await _db.select(_db.userWordStates).get();
    final cards = await _db.select(_db.userCards).get();
    final srs = await _db.select(_db.userCardSrs).get();
    final logs = await _db.select(_db.userReviewLogs).get();
    final links = await _db.select(_db.cropWords).get();
    final kanji = await _db.select(_db.savedKanji).get();
    return BackupDocument(
      formatVersion: kBackupFormatVersion,
      schemaVersion: _db.schemaVersion,
      exportedAt: DateTime.now().toUtc(),
      words: [
        for (final row in words)
          BackupWord(
            id: row.id,
            seq: row.seq,
            lemma: row.lemma,
            reading: row.reading,
            userNote: row.userNote,
            lemmaKey: row.lemmaKey,
            createdAt: row.createdAt.toUtc(),
          ),
      ],
      wordStates: [
        for (final row in states)
          BackupWordState(
            wordId: row.wordId,
            state: row.state,
            updatedAt: row.updatedAt.toUtc(),
          ),
      ],
      cards: [
        for (final row in cards)
          BackupCard(
            id: row.id,
            wordId: row.wordId,
            kind: row.kind,
            createdAt: row.createdAt.toUtc(),
            suspendReason: row.suspendReason,
          ),
      ],
      cardSrs: [
        for (final row in srs)
          BackupCardSrs(
            cardId: row.cardId,
            easeFactor: row.easeFactor,
            intervalDays: row.intervalDays,
            repetitions: row.repetitions,
            dueAt: row.dueAt.toUtc(),
            phase: row.phase,
            engineId: row.engineId,
          ),
      ],
      reviewLogs: [
        for (final row in logs)
          BackupReviewLog(
            id: row.id,
            cardId: row.cardId,
            ratedAt: row.ratedAt.toUtc(),
            rating: row.rating,
            quality: row.quality,
            engineId: row.engineId,
            isDrill: row.isDrill,
          ),
      ],
      cropWords: [
        for (final row in links)
          BackupCropWord(
            cropId: row.cropId,
            wordId: row.wordId,
            createdAt: row.createdAt.toUtc(),
          ),
      ],
      savedKanji: [
        for (final row in kanji)
          BackupSavedKanji(
            literal: row.literal,
            savedAt: row.savedAt.toUtc(),
            originPageId: row.originPageId,
          ),
      ],
    );
  }

  /// Decode [source] then replace Caderno + SRS + `saved_kanji` in one
  /// transaction. Any failure leaves the database untouched.
  Future<BackupRestoreResult> restoreJson(String source) {
    final doc = decodeBackupJson(
      source,
      currentSchemaVersion: _db.schemaVersion,
    );
    return restore(doc);
  }

  /// Replace Caderno + SRS + `saved_kanji` with [doc] inside one Drift
  /// transaction. Pages / crops / images stay. Invalid `saved_kanji.literal`
  /// values are skipped (counted); the rest of the restore continues.
  Future<BackupRestoreResult> restore(BackupDocument doc) async {
    try {
      return await _db.transaction(() async {
        await _db.delete(_db.cropWords).go();
        await _db.delete(_db.userReviewLogs).go();
        await _db.delete(_db.userCardSrs).go();
        await _db.delete(_db.userCards).go();
        await _db.delete(_db.userWordStates).go();
        await _db.delete(_db.savedKanji).go();
        await _db.delete(_db.userWords).go();

        for (final word in doc.words) {
          await _db
              .into(_db.userWords)
              .insert(
                UserWordsCompanion.insert(
                  id: word.id,
                  seq: word.seq,
                  lemma: word.lemma,
                  reading: word.reading,
                  userNote: Value(word.userNote),
                  lemmaKey: Value(word.lemmaKey),
                  createdAt: word.createdAt,
                ),
              );
        }
        for (final state in doc.wordStates) {
          await _db
              .into(_db.userWordStates)
              .insert(
                UserWordStatesCompanion.insert(
                  wordId: state.wordId,
                  state: state.state,
                  updatedAt: state.updatedAt,
                ),
              );
        }
        for (final card in doc.cards) {
          await _db
              .into(_db.userCards)
              .insert(
                UserCardsCompanion.insert(
                  id: card.id,
                  wordId: card.wordId,
                  kind: card.kind,
                  createdAt: card.createdAt,
                  suspendReason: Value(card.suspendReason),
                ),
              );
        }
        for (final srs in doc.cardSrs) {
          await _db
              .into(_db.userCardSrs)
              .insert(
                UserCardSrsCompanion.insert(
                  cardId: srs.cardId,
                  easeFactor: srs.easeFactor,
                  intervalDays: srs.intervalDays,
                  repetitions: srs.repetitions,
                  dueAt: srs.dueAt,
                  phase: srs.phase,
                  engineId: srs.engineId,
                ),
              );
        }
        for (final log in doc.reviewLogs) {
          await _db
              .into(_db.userReviewLogs)
              .insert(
                UserReviewLogsCompanion.insert(
                  id: log.id,
                  cardId: log.cardId,
                  ratedAt: log.ratedAt,
                  rating: log.rating,
                  quality: log.quality,
                  engineId: log.engineId,
                  isDrill: log.isDrill,
                ),
              );
        }

        final cropIds = {
          for (final crop in await _db.select(_db.capturedCrops).get()) crop.id,
        };
        final wordIds = {for (final word in doc.words) word.id};
        final seenLinks = <String>{};
        for (final link in doc.cropWords) {
          if (!cropIds.contains(link.cropId) ||
              !wordIds.contains(link.wordId)) {
            continue;
          }
          final key = '${link.cropId}\u0000${link.wordId}';
          if (!seenLinks.add(key)) {
            continue;
          }
          await _db
              .into(_db.cropWords)
              .insert(
                CropWordsCompanion.insert(
                  cropId: link.cropId,
                  wordId: link.wordId,
                  createdAt: link.createdAt,
                ),
              );
        }

        final pageIds = {
          for (final page in await _db.select(_db.capturedPages).get()) page.id,
        };
        var skippedKanji = 0;
        var savedKanjiCount = 0;
        final seenLiterals = <String>{};
        for (final kanji in doc.savedKanji) {
          final literal = normalizeKanjiLiteral(kanji.literal);
          if (literal == null) {
            skippedKanji += 1;
            continue;
          }
          if (!seenLiterals.add(literal)) {
            continue;
          }
          final origin = kanji.originPageId;
          final originPageId = origin != null && pageIds.contains(origin)
              ? origin
              : null;
          await _db
              .into(_db.savedKanji)
              .insert(
                SavedKanjiCompanion.insert(
                  literal: literal,
                  savedAt: kanji.savedAt,
                  originPageId: Value(originPageId),
                ),
              );
          savedKanjiCount += 1;
        }

        return BackupRestoreResult(
          wordCount: doc.words.length,
          cardCount: doc.cards.length,
          savedKanjiCount: savedKanjiCount,
          skippedKanji: skippedKanji,
        );
      });
    } on BackupRejectedException {
      rethrow;
    } catch (error) {
      throw BackupRestoreFailedException(BackupLabels.restoreFailed, error);
    }
  }
}
