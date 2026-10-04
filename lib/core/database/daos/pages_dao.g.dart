// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pages_dao.dart';

// ignore_for_file: type=lint
mixin _$PagesDaoMixin on DatabaseAccessor<AppDatabase> {
  $CapturedPagesTable get capturedPages => attachedDatabase.capturedPages;
  $CapturedCropsTable get capturedCrops => attachedDatabase.capturedCrops;
  PagesDaoManager get managers => PagesDaoManager(this);
}

class PagesDaoManager {
  final _$PagesDaoMixin _db;
  PagesDaoManager(this._db);
  $$CapturedPagesTableTableManager get capturedPages =>
      $$CapturedPagesTableTableManager(_db.attachedDatabase, _db.capturedPages);
  $$CapturedCropsTableTableManager get capturedCrops =>
      $$CapturedCropsTableTableManager(_db.attachedDatabase, _db.capturedCrops);
}
