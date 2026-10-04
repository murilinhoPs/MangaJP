import 'package:drift/drift.dart';

import 'user_words.dart';

/// Per-word study state (`word_states`): saved / learning / known / ignored.
class UserWordStates extends Table {
  @override
  String get tableName => 'word_states';

  TextColumn get wordId => text().references(UserWords, #id)();
  TextColumn get state => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {wordId};
}
