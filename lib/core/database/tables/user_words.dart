import 'package:drift/drift.dart';

/// User word (`words`). JMdict rows are keyed by unique `seq`. Custom rows
/// (no JMdict hit) use id `custom:<uuid>` and a required [userNote].
///
/// [lemmaKey] is [lemma] with variation selectors stripped (M1.26). Custom
/// save and the v8 merge look up by this column, not by scanning every
/// custom row. The displayed [lemma] keeps the first-saved / survivor form.
@TableIndex(name: 'idx_words_lemma_key', columns: {#lemmaKey})
@TableIndex.sql(
  "CREATE UNIQUE INDEX idx_words_custom_lemma_key "
  "ON words (lemma_key) WHERE id LIKE 'custom:%'",
)
class UserWords extends Table {
  @override
  String get tableName => 'words';

  TextColumn get id => text()();
  IntColumn get seq => integer().unique()();
  TextColumn get lemma => text()();
  TextColumn get reading => text()();
  TextColumn get userNote => text().nullable()();
  TextColumn get lemmaKey => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
