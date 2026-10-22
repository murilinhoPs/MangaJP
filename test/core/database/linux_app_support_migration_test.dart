import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/database/linux_app_support_migration.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory root;
  final logs = <String>[];

  setUp(() {
    root = Directory.systemTemp.createTempSync('linux-app-support-');
    logs.clear();
    linuxAppSupportLog = logs.add;
    resetLinuxAppSupportDirectoryCache();
  });

  tearDown(() {
    linuxAppSupportLog = null;
    resetLinuxAppSupportDirectoryCache();
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  Directory dir(String name) => Directory('${root.path}/$name');

  File marker(Directory folder, [String name = kMangaJpDatabaseFileName]) {
    return File('${folder.path}/$name');
  }

  test('old exists and new does not: copies contents into new', () {
    final oldDir = dir(kLegacyLinuxApplicationId)..createSync();
    final nested = Directory('${oldDir.path}/nested')..createSync();
    marker(oldDir).writeAsStringSync('legacy-db');
    File('${nested.path}/note.txt').writeAsStringSync('keep-me');
    final newDir = dir(kLinuxApplicationId);

    final result = migrateLinuxAppSupportDirectory(
      oldDir: oldDir,
      newDir: newDir,
    );

    expect(result, LinuxAppSupportMigrationResult.migrated);
    expect(newDir.existsSync(), isTrue);
    expect(marker(newDir).readAsStringSync(), 'legacy-db');
    expect(
      File('${newDir.path}/nested/note.txt').readAsStringSync(),
      'keep-me',
    );
    expect(marker(oldDir).readAsStringSync(), 'legacy-db');
  });

  test('both exist with mangajp.sqlite: does not overwrite new', () {
    final oldDir = dir(kLegacyLinuxApplicationId)..createSync();
    final newDir = dir(kLinuxApplicationId)..createSync();
    marker(oldDir).writeAsStringSync('old');
    marker(newDir).writeAsStringSync('new');

    final result = migrateLinuxAppSupportDirectory(
      oldDir: oldDir,
      newDir: newDir,
    );

    expect(result, LinuxAppSupportMigrationResult.skippedNewHasData);
    expect(marker(newDir).readAsStringSync(), 'new');
    expect(marker(oldDir).readAsStringSync(), 'old');
  });

  test('neither exists: no-op', () {
    final oldDir = dir(kLegacyLinuxApplicationId);
    final newDir = dir(kLinuxApplicationId);

    final result = migrateLinuxAppSupportDirectory(
      oldDir: oldDir,
      newDir: newDir,
    );

    expect(result, LinuxAppSupportMigrationResult.skippedOldMissing);
    expect(oldDir.existsSync(), isFalse);
    expect(newDir.existsSync(), isFalse);
  });

  test('second run is a no-op', () {
    final oldDir = dir(kLegacyLinuxApplicationId)..createSync();
    final newDir = dir(kLinuxApplicationId);
    marker(oldDir).writeAsStringSync('legacy-db');

    expect(
      migrateLinuxAppSupportDirectory(oldDir: oldDir, newDir: newDir),
      LinuxAppSupportMigrationResult.migrated,
    );
    marker(newDir).writeAsStringSync('after-first-run');

    expect(
      migrateLinuxAppSupportDirectory(oldDir: oldDir, newDir: newDir),
      LinuxAppSupportMigrationResult.skippedNewHasData,
    );
    expect(marker(newDir).readAsStringSync(), 'after-first-run');
  });

  test('old exists and new is empty: copies into new', () {
    final oldDir = dir(kLegacyLinuxApplicationId)..createSync();
    final newDir = dir(kLinuxApplicationId)..createSync();
    marker(oldDir).writeAsStringSync('legacy-db');

    final result = migrateLinuxAppSupportDirectory(
      oldDir: oldDir,
      newDir: newDir,
    );

    expect(result, LinuxAppSupportMigrationResult.migrated);
    expect(marker(newDir).readAsStringSync(), 'legacy-db');
  });

  test(
    'new dir without mangajp.sqlite is retried even if other files exist',
    () {
      final oldDir = dir(kLegacyLinuxApplicationId)..createSync();
      final newDir = dir(kLinuxApplicationId)..createSync();
      marker(oldDir).writeAsStringSync('legacy-db');
      File('${newDir.path}/leftover.txt').writeAsStringSync('not-the-db');
      File('${newDir.path}/jmdict.sqlite').writeAsStringSync('keep-dict');

      final result = migrateLinuxAppSupportDirectory(
        oldDir: oldDir,
        newDir: newDir,
      );

      expect(result, LinuxAppSupportMigrationResult.migrated);
      expect(marker(newDir).readAsStringSync(), 'legacy-db');
      expect(
        File('${newDir.path}/leftover.txt').readAsStringSync(),
        'not-the-db',
      );
      expect(
        File('${newDir.path}/jmdict.sqlite').readAsStringSync(),
        'keep-dict',
      );
    },
  );

  test('orphan .migrating is deleted before a successful copy', () {
    final oldDir = dir(kLegacyLinuxApplicationId)..createSync();
    final newDir = dir(kLinuxApplicationId);
    marker(oldDir).writeAsStringSync('legacy-db');
    final staging = Directory('${newDir.path}.migrating')..createSync();
    File('${staging.path}/stale.bin').writeAsStringSync('partial');

    final result = migrateLinuxAppSupportDirectory(
      oldDir: oldDir,
      newDir: newDir,
    );

    expect(result, LinuxAppSupportMigrationResult.migrated);
    expect(staging.existsSync(), isFalse);
    expect(marker(newDir).readAsStringSync(), 'legacy-db');
  });

  test('staging leftover as a file is deleted before copy', () {
    final oldDir = dir(kLegacyLinuxApplicationId)..createSync();
    final newDir = dir(kLinuxApplicationId);
    marker(oldDir).writeAsStringSync('legacy-db');
    File('${newDir.path}.migrating').writeAsStringSync('not-a-dir');

    final result = migrateLinuxAppSupportDirectory(
      oldDir: oldDir,
      newDir: newDir,
    );

    expect(result, LinuxAppSupportMigrationResult.migrated);
    expect(File('${newDir.path}.migrating').existsSync(), isFalse);
    expect(marker(newDir).readAsStringSync(), 'legacy-db');
  });

  test(
    'unreadable file mid-copy uses old dir and does not create new sqlite',
    () {
      final oldDir = dir(kLegacyLinuxApplicationId)..createSync();
      final newDir = dir(kLinuxApplicationId);
      marker(oldDir).writeAsStringSync('legacy-db');
      final poison = File('${oldDir.path}/poison.bin')..writeAsStringSync('x');
      _chmod(poison.path, '000');
      addTearDown(() {
        _chmod(poison.path, '644');
      });

      final result = migrateLinuxAppSupportDirectory(
        oldDir: oldDir,
        newDir: newDir,
      );

      expect(result, LinuxAppSupportMigrationResult.failed);
      expect(marker(oldDir).readAsStringSync(), 'legacy-db');
      expect(marker(newDir).existsSync(), isFalse);
      expect(
        logs.any((line) => line.contains('using legacy directory')),
        isTrue,
      );

      final resolved = resolveLinuxAppSupportDirectoryFrom(
        oldDir: oldDir,
        newDir: newDir,
      );
      expect(resolved.path, oldDir.absolute.path);
      expect(marker(newDir).existsSync(), isFalse);
    },
  );

  test('after unreadable file is fixed, next attempt migrates', () {
    final oldDir = dir(kLegacyLinuxApplicationId)..createSync();
    final newDir = dir(kLinuxApplicationId);
    marker(oldDir).writeAsStringSync('legacy-db');
    final poison = File('${oldDir.path}/poison.bin')..writeAsStringSync('x');
    _chmod(poison.path, '000');

    expect(
      migrateLinuxAppSupportDirectory(oldDir: oldDir, newDir: newDir),
      LinuxAppSupportMigrationResult.failed,
    );
    expect(Directory('${newDir.path}.migrating').existsSync(), isTrue);

    _chmod(poison.path, '644');

    expect(
      migrateLinuxAppSupportDirectory(oldDir: oldDir, newDir: newDir),
      LinuxAppSupportMigrationResult.migrated,
    );
    expect(Directory('${newDir.path}.migrating').existsSync(), isFalse);
    expect(marker(newDir).readAsStringSync(), 'legacy-db');
    expect(File('${newDir.path}/poison.bin').readAsStringSync(), 'x');
  });

  test('without HOME and XDG_DATA_HOME does not create an empty database', () {
    const env = <String, String>{};
    expect(
      () => linuxXdgDataHome(environment: env),
      throwsA(isA<StateError>()),
    );
    expect(
      () => linuxXdgDataHome(
        environment: const {'HOME': '', 'XDG_DATA_HOME': ''},
      ),
      throwsA(isA<StateError>()),
    );

    final oldDir = dir(kLegacyLinuxApplicationId)..createSync();
    final newDir = dir(kLinuxApplicationId);
    _writeSqliteWithWord(oldDir, id: 'demo-taberu');

    expect(
      () => resolveLinuxAppSupportDirectory(environment: env),
      throwsA(isA<StateError>()),
    );
    expect(
      logs.any(
        (line) =>
            line.contains('HOME') &&
            line.contains('XDG_DATA_HOME') &&
            line.contains('not creating an empty database'),
      ),
      isTrue,
    );
    expect(newDir.existsSync(), isFalse);
    expect(marker(newDir).existsSync(), isFalse);

    resetLinuxAppSupportDirectoryCache();
    final resolved = resolveLinuxAppSupportDirectoryFromPathProvider(
      newDir,
      resolveError: StateError('HOME is not set'),
    );
    expect(resolved.absolute.path, newDir.absolute.path);
    expect(_wordIds(marker(newDir)), ['demo-taberu']);
    expect(logs.any((line) => line.contains('recovering via')), isTrue);
  });

  test('empty new sqlite is replaced when old sqlite has user data', () {
    final oldDir = dir(kLegacyLinuxApplicationId)..createSync();
    final newDir = dir(kLinuxApplicationId)..createSync();
    _writeSqliteWithWord(oldDir, id: 'demo-taberu');
    _writeEmptySqlite(newDir);
    File('${newDir.path}/jmdict.sqlite').writeAsStringSync('keep-dict');
    File('${newDir.path}/$kMangaJpDatabaseFileName-wal')
        .writeAsStringSync('stale-wal');

    final result = migrateLinuxAppSupportDirectory(
      oldDir: oldDir,
      newDir: newDir,
    );

    expect(result, LinuxAppSupportMigrationResult.migrated);
    expect(_wordIds(marker(newDir)), ['demo-taberu']);
    expect(_wordIds(marker(oldDir)), ['demo-taberu']);
    expect(
      File('${newDir.path}/jmdict.sqlite').readAsStringSync(),
      'keep-dict',
    );
    expect(
      File('${newDir.path}/$kMangaJpDatabaseFileName-wal').existsSync(),
      isFalse,
    );
    expect(
      logs.any(
        (line) => line.contains('found empty $kMangaJpDatabaseFileName'),
      ),
      isTrue,
    );
  });

  test('new sqlite with real user data is not overwritten', () {
    final oldDir = dir(kLegacyLinuxApplicationId)..createSync();
    final newDir = dir(kLinuxApplicationId)..createSync();
    _writeSqliteWithWord(oldDir, id: 'legacy-word');
    _writeSqliteWithWord(newDir, id: 'new-word');

    final result = migrateLinuxAppSupportDirectory(
      oldDir: oldDir,
      newDir: newDir,
    );

    expect(result, LinuxAppSupportMigrationResult.skippedNewHasData);
    expect(_wordIds(marker(newDir)), ['new-word']);
    expect(_wordIds(marker(oldDir)), ['legacy-word']);
  });

  test('replacing empty sqlite is idempotent on the next run', () {
    final oldDir = dir(kLegacyLinuxApplicationId)..createSync();
    final newDir = dir(kLinuxApplicationId)..createSync();
    _writeSqliteWithWord(oldDir, id: 'demo-taberu');
    _writeEmptySqlite(newDir);

    expect(
      migrateLinuxAppSupportDirectory(oldDir: oldDir, newDir: newDir),
      LinuxAppSupportMigrationResult.migrated,
    );
    expect(_wordIds(marker(newDir)), ['demo-taberu']);

    expect(
      migrateLinuxAppSupportDirectory(oldDir: oldDir, newDir: newDir),
      LinuxAppSupportMigrationResult.skippedNewHasData,
    );
    expect(_wordIds(marker(newDir)), ['demo-taberu']);
    expect(_wordIds(marker(oldDir)), ['demo-taberu']);
  });
}

void _writeEmptySqlite(Directory dir) {
  final db = sqlite3.open('${dir.path}/$kMangaJpDatabaseFileName');
  db
    ..execute(
      'CREATE TABLE app_meta (key TEXT NOT NULL PRIMARY KEY, value TEXT NOT NULL)',
    )
    ..execute(
      'CREATE TABLE words ('
      'id TEXT NOT NULL PRIMARY KEY, '
      'seq INTEGER NOT NULL, '
      'lemma TEXT NOT NULL, '
      'reading TEXT NOT NULL, '
      'user_note TEXT, '
      'lemma_key TEXT NOT NULL DEFAULT \'\', '
      'created_at INTEGER NOT NULL)',
    )
    ..execute(
      "INSERT INTO app_meta (key, value) VALUES ('hello', 'MangaJP M0.1')",
    )
    ..execute(
      "INSERT INTO app_meta (key, value) VALUES ('schema_version', '8')",
    );
  db.close();
}

void _writeSqliteWithWord(Directory dir, {required String id}) {
  _writeEmptySqlite(dir);
  final db = sqlite3.open('${dir.path}/$kMangaJpDatabaseFileName');
  db.execute(
    'INSERT INTO words (id, seq, lemma, reading, lemma_key, created_at) '
    'VALUES (?, ?, ?, ?, ?, ?)',
    [id, 1, '食べる', 'たべる', '食べる', 0],
  );
  db.close();
}

List<String> _wordIds(File file) {
  final db = sqlite3.open(file.path, mode: OpenMode.readOnly);
  try {
    return [
      for (final row in db.select('SELECT id FROM words ORDER BY id'))
        row['id'] as String,
    ];
  } finally {
    db.close();
  }
}

void _chmod(String path, String mode) {
  final result = Process.runSync('chmod', [mode, path]);
  expect(result.exitCode, 0, reason: result.stderr.toString());
}
