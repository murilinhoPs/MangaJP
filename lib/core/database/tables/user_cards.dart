import 'package:drift/drift.dart';

import 'user_words.dart';

/// Vocab flashcard (`cards`). One row per word; SRS lives in `card_srs`.
///
/// [suspendReason] is `known` / `ignored` when the word is marked that way.
/// Null means the card is not suspended. Known / ignored never delete the row.
class UserCards extends Table {
  @override
  String get tableName => 'cards';

  TextColumn get id => text()();
  TextColumn get wordId => text().unique().references(UserWords, #id)();
  TextColumn get kind => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get suspendReason => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
