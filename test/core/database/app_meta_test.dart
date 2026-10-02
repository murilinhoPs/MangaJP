import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/database/app_database.dart';

void main() {
  test('app_meta roundtrip', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await db.appMetaDao.upsert('hello', 'MangaJP M0.1');
    expect(await db.appMetaDao.getValue('hello'), 'MangaJP M0.1');

    await db.appMetaDao.upsert('hello', 'updated');
    expect(await db.appMetaDao.getValue('hello'), 'updated');
  });
}
