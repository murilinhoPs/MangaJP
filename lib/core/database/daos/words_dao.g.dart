// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'words_dao.dart';

// ignore_for_file: type=lint
mixin _$WordsDaoMixin on DatabaseAccessor<AppDatabase> {
  $UserWordsTable get userWords => attachedDatabase.userWords;
  $UserWordStatesTable get userWordStates => attachedDatabase.userWordStates;
  $CapturedPagesTable get capturedPages => attachedDatabase.capturedPages;
  $CapturedCropsTable get capturedCrops => attachedDatabase.capturedCrops;
  $CropWordsTable get cropWords => attachedDatabase.cropWords;
  WordsDaoManager get managers => WordsDaoManager(this);
}

class WordsDaoManager {
  final _$WordsDaoMixin _db;
  WordsDaoManager(this._db);
  $$UserWordsTableTableManager get userWords =>
      $$UserWordsTableTableManager(_db.attachedDatabase, _db.userWords);
  $$UserWordStatesTableTableManager get userWordStates =>
      $$UserWordStatesTableTableManager(
        _db.attachedDatabase,
        _db.userWordStates,
      );
  $$CapturedPagesTableTableManager get capturedPages =>
      $$CapturedPagesTableTableManager(_db.attachedDatabase, _db.capturedPages);
  $$CapturedCropsTableTableManager get capturedCrops =>
      $$CapturedCropsTableTableManager(_db.attachedDatabase, _db.capturedCrops);
  $$CropWordsTableTableManager get cropWords =>
      $$CropWordsTableTableManager(_db.attachedDatabase, _db.cropWords);
}
