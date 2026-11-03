import 'package:drift/drift.dart';

import 'captured_pages.dart';

/// Caderno kanji (`saved_kanji`). Identity is the normalized [literal].
///
/// No note, no flashcard, no `word_states`. A second save of the same
/// literal is a no-op (`INSERT OR IGNORE`) and does not rewrite [savedAt]
/// or [originPageId]. Deleting the origin page sets [originPageId] to null.
@TableIndex(name: 'idx_saved_kanji_saved_at', columns: {#savedAt})
class SavedKanji extends Table {
  @override
  String get tableName => 'saved_kanji';

  TextColumn get literal => text()();
  DateTimeColumn get savedAt => dateTime()();
  TextColumn get originPageId => text().nullable().references(
    CapturedPages,
    #id,
    onDelete: KeyAction.setNull,
  )();

  @override
  Set<Column<Object>> get primaryKey => {literal};
}
