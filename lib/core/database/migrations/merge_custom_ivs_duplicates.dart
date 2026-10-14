part of '../app_database.dart';

/// Fill [UserWords.lemmaKey] and fold custom rows that collide after
/// [stripVariationSelectors] into one survivor (M1.28).
Future<void> backfillLemmaKeysAndMergeCustomIvsDuplicates(AppDatabase db) async {
  final words = await db.select(db.userWords).get();
  await db.batch((batch) {
    for (final word in words) {
      final key = stripVariationSelectors(word.lemma);
      if (word.lemmaKey == key) {
        continue;
      }
      batch.update(
        db.userWords,
        UserWordsCompanion(lemmaKey: Value(key)),
        where: (t) => t.id.equals(word.id),
      );
    }
  });
  await mergeCustomIvsDuplicates(db);
}

Future<void> assertNoForeignKeyViolations(AppDatabase db) async {
  final rows = await db.customSelect('PRAGMA foreign_key_check').get();
  if (rows.isEmpty) {
    return;
  }
  throw StateError(
    'foreign_key_check failed after v8 merge: '
    '${[for (final row in rows) row.data]}',
  );
}

Future<void> mergeCustomIvsDuplicates(AppDatabase db) async {
  final custom = await (db.select(
    db.userWords,
  )..where((t) => t.id.like('$customWordIdPrefix%'))).get();
  final groups = <String, List<UserWord>>{};
  for (final word in custom) {
    final key = word.lemmaKey.isEmpty
        ? stripVariationSelectors(word.lemma)
        : word.lemmaKey;
    if (key.isEmpty) {
      continue;
    }
    groups.putIfAbsent(key, () => []).add(word);
  }
  for (final group in groups.values) {
    if (group.length < 2) {
      continue;
    }
    await _mergeCustomIvsGroup(db, group);
  }
}

Future<void> _mergeCustomIvsGroup(AppDatabase db, List<UserWord> group) async {
  final candidates = <CustomWordMergeCandidate>[];
  for (final word in group) {
    final card = await db.cardsDao.cardForWord(word.id);
    var repetitions = 0;
    DateTime? latestReview;
    if (card != null) {
      final srs = await db.cardsDao.srsFor(card.id);
      repetitions = srs?.repetitions ?? 0;
      latestReview = (await db.cardsDao.latestLogFor(card.id))?.ratedAt;
    }
    candidates.add(
      CustomWordMergeCandidate(
        id: word.id,
        createdAt: word.createdAt,
        repetitions: repetitions,
        latestReview: latestReview,
      ),
    );
  }
  final survivorId = pickCustomWordSurvivor(candidates).id;
  final survivor = group.firstWhere((word) => word.id == survivorId);
  final losers = [
    for (final word in group)
      if (word.id != survivorId) word,
  ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  final mergedNote = mergeUserNotes(
    survivor.userNote,
    losers.map((word) => word.userNote),
  );
  if (mergedNote != survivor.userNote) {
    await (db.update(db.userWords)..where((t) => t.id.equals(survivorId)))
        .write(UserWordsCompanion(userNote: Value(mergedNote)));
  }

  var survivorCard = await db.cardsDao.cardForWord(survivorId);
  for (final loser in losers) {
    survivorCard = await _repointCustomIvsLoser(
      db,
      survivorId: survivorId,
      survivorCard: survivorCard,
      loserId: loser.id,
    );
  }
}

Future<UserCard?> _repointCustomIvsLoser(
  AppDatabase db, {
  required String survivorId,
  required UserCard? survivorCard,
  required String loserId,
}) async {
  var keptCard = survivorCard;
  final loserCard = await db.cardsDao.cardForWord(loserId);
  if (loserCard != null) {
    if (keptCard == null) {
      await (db.update(db.userCards)..where((t) => t.id.equals(loserCard.id)))
          .write(UserCardsCompanion(wordId: Value(survivorId)));
      keptCard = loserCard.copyWith(wordId: survivorId);
    } else if (keptCard.id != loserCard.id) {
      await db.customStatement(
        'UPDATE review_logs SET card_id = ? WHERE card_id = ?',
        [keptCard.id, loserCard.id],
      );
      await db.cardsDao.deleteSrs(loserCard.id);
      await db.cardsDao.deleteCard(loserCard.id);
    }
  }

  await db.customStatement(
    'UPDATE OR IGNORE crop_words SET word_id = ? WHERE word_id = ?',
    [survivorId, loserId],
  );
  await db.wordsDao.deleteCropWordsFor(loserId);

  final survivorState = await db.wordsDao.stateFor(survivorId);
  final loserState = await db.wordsDao.stateFor(loserId);
  if (survivorState == null && loserState != null) {
    await db.customStatement(
      'UPDATE word_states SET word_id = ? WHERE word_id = ?',
      [survivorId, loserId],
    );
  } else {
    await db.wordsDao.deleteState(loserId);
  }

  await db.wordsDao.deleteWord(loserId);
  return keptCard;
}
