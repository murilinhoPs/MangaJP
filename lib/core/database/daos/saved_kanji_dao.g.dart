// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_kanji_dao.dart';

// ignore_for_file: type=lint
mixin _$SavedKanjiDaoMixin on DatabaseAccessor<AppDatabase> {
  $CapturedPagesTable get capturedPages => attachedDatabase.capturedPages;
  $SavedKanjiTable get savedKanji => attachedDatabase.savedKanji;
  SavedKanjiDaoManager get managers => SavedKanjiDaoManager(this);
}

class SavedKanjiDaoManager {
  final _$SavedKanjiDaoMixin _db;
  SavedKanjiDaoManager(this._db);
  $$CapturedPagesTableTableManager get capturedPages =>
      $$CapturedPagesTableTableManager(_db.attachedDatabase, _db.capturedPages);
  $$SavedKanjiTableTableManager get savedKanji =>
      $$SavedKanjiTableTableManager(_db.attachedDatabase, _db.savedKanji);
}
