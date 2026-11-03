import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/database/app_database_open_io.dart';
import 'package:manga_jp/core/database/linux_app_support_migration.dart';
import 'package:manga_jp/core/utils/hashing.dart';
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
    linuxAppSupportForceWalFoldFailure = false;
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
      if (_skipIfChmod000Ineffective(poison, what: 'poison.bin.openSync()')) {
        return;
      }

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
    addTearDown(() {
      if (poison.existsSync()) {
        _chmod(poison.path, '644');
      }
    });
    if (_skipIfChmod000Ineffective(poison, what: 'poison.bin.openSync()')) {
      return;
    }

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

  test('release ignores MANGAJP_FORCE_GETPWUID_FAILURE', () {
    expect(
      resolveLinuxForceGetpwuidFailure(defined: true, release: true),
      isFalse,
    );
    expect(
      resolveLinuxForceGetpwuidFailure(defined: true, release: false),
      isTrue,
    );
    expect(
      resolveLinuxForceGetpwuidFailure(defined: false, release: false),
      isFalse,
    );
  });

  test(
    'getpwuid returns an absolute home on Linux',
    skip: !Platform.isLinux,
    () {
      final home = linuxHomeFromGetpwuid();
      expect(home, isNotNull);
      expect(home, startsWith('/'));
      expect(home!.length, greaterThan(1));
    },
  );

  test(
    'linuxDatabaseDirectory without HOME uses passwd home, never temp',
    () async {
      final passwdHome = Directory('${root.path}/passwd-home')..createSync();
      final dataHome = Directory('${passwdHome.path}/.local/share')
        ..createSync(recursive: true);
      final oldDir = Directory('${dataHome.path}/$kLegacyLinuxApplicationId')
        ..createSync();
      _writeSqliteWithWord(oldDir, id: 'demo-taberu');

      final dir = await linuxDatabaseDirectory(
        environment: const <String, String>{},
        passwdHome: () => passwdHome.path,
      );

      expect(
        dir.absolute.path,
        Directory('${dataHome.path}/$kLinuxApplicationId').absolute.path,
      );
      expect(_wordIds(marker(dir)), ['demo-taberu']);
      expect(dir.absolute.path, isNot(Directory.systemTemp.absolute.path));
      expect(marker(dir).path.contains('/tmp/mangajp.sqlite'), isFalse);
      expect(logs.any((line) => line.contains('using passwd home')), isTrue);
    },
  );

  test(
    'linuxAppSupportStartupError returns StateError without HOME',
    skip: !Platform.isLinux,
    () {
      resetLinuxAppSupportDirectoryCache();
      final error = linuxAppSupportStartupError(
        environment: const <String, String>{},
        passwdHome: () => null,
      );
      expect(error, isA<StateError>());
      expect(
        (error! as StateError).message,
        contains('Not opening a database in temp'),
      );
    },
  );

  test(
    'linuxDatabaseDirectory without HOME or getpwuid throws, never temp',
    () async {
      await expectLater(
        linuxDatabaseDirectory(
          environment: const <String, String>{},
          passwdHome: () => null,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Not opening a database in temp'),
          ),
        ),
      );
      expect(
        logs.any(
          (line) => line.contains('Not creating an empty database in temp'),
        ),
        isTrue,
      );
    },
  );

  test(
    'merge failure before sqlite leaves no sqlite so the next run retries',
    () {
      final oldDir = dir(kLegacyLinuxApplicationId)..createSync();
      final newDir = dir(kLinuxApplicationId)..createSync();
      _writeSqliteWithWord(oldDir, id: 'demo-taberu');
      Directory('${oldDir.path}/pages').createSync();
      File('${oldDir.path}/pages/photo.bin').writeAsStringSync('img');
      File('${newDir.path}/leftover.txt').writeAsStringSync('keep');
      File('${newDir.path}/jmdict.sqlite').writeAsStringSync('keep-dict');
      final trap = Directory('${newDir.path}/pages')..createSync();
      _chmod(trap.path, '000');
      addTearDown(() {
        if (trap.existsSync()) {
          _chmod(trap.path, '755');
        }
      });
      if (_skipIfChmod000Ineffective(trap, what: 'pages.listSync()')) {
        return;
      }

      expect(
        migrateLinuxAppSupportDirectory(oldDir: oldDir, newDir: newDir),
        LinuxAppSupportMigrationResult.failed,
      );
      expect(marker(newDir).existsSync(), isFalse);
      expect(
        File('${newDir.path}/$kMangaJpDatabaseFileName.incoming').existsSync(),
        isFalse,
      );
      expect(
        File('${newDir.path}/jmdict.sqlite').readAsStringSync(),
        'keep-dict',
      );

      _chmod(trap.path, '755');

      expect(
        migrateLinuxAppSupportDirectory(oldDir: oldDir, newDir: newDir),
        LinuxAppSupportMigrationResult.migrated,
      );
      expect(_wordIds(marker(newDir)), ['demo-taberu']);
      expect(File('${newDir.path}/pages/photo.bin').readAsStringSync(), 'img');
      expect(
        File('${newDir.path}/jmdict.sqlite').readAsStringSync(),
        'keep-dict',
      );
    },
  );

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

  test('WAL-only transactions land in dest sqlite, without copying -wal after rename', () {
    final oldDir = dir(kLegacyLinuxApplicationId)..createSync();
    final newDir = dir(kLinuxApplicationId)..createSync();
    File('${newDir.path}/leftover.txt').writeAsStringSync('keep');
    File('${newDir.path}/jmdict.sqlite').writeAsStringSync('keep-dict');

    final sourcePath = '${oldDir.path}/$kMangaJpDatabaseFileName';
    final live = sqlite3.open(sourcePath);
    addTearDown(live.close);
    _createMangaJpSchema(live);
    live
      ..execute('PRAGMA journal_mode=WAL')
      ..execute('PRAGMA wal_autocheckpoint=0')
      ..execute(
        'INSERT INTO words (id, seq, lemma, reading, lemma_key, created_at) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        ['wal-only-word', 1, '食べる', 'たべる', '食べる', 0],
      );
    final wal = File('$sourcePath-wal');
    expect(wal.existsSync(), isTrue);
    expect(wal.lengthSync(), greaterThan(0));

    final result = migrateLinuxAppSupportDirectory(
      oldDir: oldDir,
      newDir: newDir,
    );

    expect(result, LinuxAppSupportMigrationResult.migrated);
    expect(_wordIds(marker(newDir)), ['wal-only-word']);
    expect(
      File('${newDir.path}/$kMangaJpDatabaseFileName-wal').existsSync(),
      isFalse,
    );
    expect(
      File('${newDir.path}/$kMangaJpDatabaseFileName-shm').existsSync(),
      isFalse,
    );
    expect(
      File('${newDir.path}/jmdict.sqlite').readAsStringSync(),
      'keep-dict',
    );
  });

  test('empty new sqlite is replaced when old user data lives only in WAL', () {
    final oldDir = dir(kLegacyLinuxApplicationId)..createSync();
    final newDir = dir(kLinuxApplicationId)..createSync();
    _writeEmptySqlite(newDir);
    File('${newDir.path}/jmdict.sqlite').writeAsStringSync('keep-dict');

    final sourcePath = '${oldDir.path}/$kMangaJpDatabaseFileName';
    final live = sqlite3.open(sourcePath);
    addTearDown(live.close);
    _createMangaJpSchema(live);
    live
      ..execute('PRAGMA journal_mode=WAL')
      ..execute('PRAGMA wal_autocheckpoint=0')
      ..execute(
        'INSERT INTO words (id, seq, lemma, reading, lemma_key, created_at) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        ['wal-probe-word', 1, '食べる', 'たべる', '食べる', 0],
      );
    expect(File('$sourcePath-wal').lengthSync(), greaterThan(0));

    final result = migrateLinuxAppSupportDirectory(
      oldDir: oldDir,
      newDir: newDir,
    );

    expect(result, LinuxAppSupportMigrationResult.migrated);
    expect(_wordIds(marker(newDir)), ['wal-probe-word']);
    expect(
      File('${newDir.path}/$kMangaJpDatabaseFileName-wal').existsSync(),
      isFalse,
    );
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

  test('newDir WAL-only data with unreadable shm is not overwritten', () {
    final oldDir = dir(kLegacyLinuxApplicationId)..createSync();
    final newDir = dir(kLinuxApplicationId)..createSync();
    _writeSqliteWithWord(oldDir, id: 'legacy-word');
    _snapshotWalSqlite(newDir, id: 'new-wal-word');
    File('${newDir.path}/jmdict.sqlite').writeAsStringSync('keep-dict');
    final shm = File('${newDir.path}/$kMangaJpDatabaseFileName-shm');
    expect(shm.existsSync(), isTrue);
    _chmod(shm.path, '000');
    addTearDown(() {
      if (shm.existsSync()) {
        _chmod(shm.path, '644');
      }
    });
    if (_skipIfChmod000Ineffective(
      shm,
      what: 'shm.openSync()',
      reason: 'WAL-copy fallback was not exercised',
    )) {
      return;
    }

    final result = migrateLinuxAppSupportDirectory(
      oldDir: oldDir,
      newDir: newDir,
    );

    expect(result, LinuxAppSupportMigrationResult.skippedNewHasData);
    _chmod(shm.path, '644');
    expect(_wordIds(marker(newDir)), ['new-wal-word']);
    expect(_wordIds(marker(oldDir)), ['legacy-word']);
    expect(
      File('${newDir.path}/jmdict.sqlite').readAsStringSync(),
      'keep-dict',
    );
  });

  test('WAL fold failure returns failed and leaves legacy sqlite intact', () {
    final oldDir = dir(kLegacyLinuxApplicationId)..createSync();
    final newDir = dir(kLinuxApplicationId);
    _snapshotWalSqlite(oldDir, id: 'fold-fail-word');
    final sqlite = marker(oldDir);
    final wal = File('${sqlite.path}-wal');
    final shm = File('${sqlite.path}-shm');
    expect(wal.existsSync(), isTrue);
    final beforeSqlite = sha256Hex(sqlite.readAsBytesSync());
    final beforeWal = sha256Hex(wal.readAsBytesSync());
    final beforeShm = shm.existsSync()
        ? sha256Hex(shm.readAsBytesSync())
        : null;

    linuxAppSupportForceWalFoldFailure = true;

    final result = migrateLinuxAppSupportDirectory(
      oldDir: oldDir,
      newDir: newDir,
    );

    expect(result, LinuxAppSupportMigrationResult.failed);
    expect(sha256Hex(sqlite.readAsBytesSync()), beforeSqlite);
    expect(sha256Hex(wal.readAsBytesSync()), beforeWal);
    if (beforeShm != null) {
      expect(sha256Hex(shm.readAsBytesSync()), beforeShm);
    }
    expect(marker(newDir).existsSync(), isFalse);
    expect(
      resolveLinuxAppSupportDirectoryFrom(oldDir: oldDir, newDir: newDir).path,
      oldDir.absolute.path,
    );
    expect(_wordIds(sqlite), ['fold-fail-word']);
  });
}

/// Freeze sqlite + WAL + SHM while a writer is still open (no checkpoint).
void _snapshotWalSqlite(Directory dest, {required String id}) {
  final tmp = Directory.systemTemp.createTempSync('wal-snap-');
  final path = '${tmp.path}/$kMangaJpDatabaseFileName';
  final live = sqlite3.open(path);
  try {
    _createMangaJpSchema(live);
    live
      ..execute('PRAGMA journal_mode=WAL')
      ..execute('PRAGMA wal_autocheckpoint=0')
      ..execute(
        'INSERT INTO words (id, seq, lemma, reading, lemma_key, created_at) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        [id, 1, '食べる', 'たべる', '食べる', 0],
      );
    dest.createSync(recursive: true);
    File(path).copySync('${dest.path}/$kMangaJpDatabaseFileName');
    for (final suffix in ['-wal', '-shm']) {
      final src = File('$path$suffix');
      if (src.existsSync()) {
        src.copySync('${dest.path}/$kMangaJpDatabaseFileName$suffix');
      }
    }
  } finally {
    live.close();
    tmp.deleteSync(recursive: true);
  }
}

void _createMangaJpSchema(Database db) {
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
}

void _writeEmptySqlite(Directory dir) {
  final db = sqlite3.open('${dir.path}/$kMangaJpDatabaseFileName');
  _createMangaJpSchema(db);
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

/// True when chmod 000 did not block reads (typical as root).
bool _chmod000StillReadable(FileSystemEntity entity) {
  try {
    if (entity is Directory) {
      entity.listSync();
    } else {
      final handle = File(entity.path).openSync();
      handle.closeSync();
    }
    return true;
  } on FileSystemException {
    return false;
  }
}

/// Skip when chmod 000 is a no-op, so the test does not pass without
/// exercising the unreadable-path fallback.
bool _skipIfChmod000Ineffective(
  FileSystemEntity entity, {
  required String what,
  String reason = 'unreadable-path fallback was not exercised',
}) {
  if (!_chmod000StillReadable(entity)) {
    return false;
  }
  markTestSkipped(
    'chmod 000 did not block $what (e.g. running as root); $reason',
  );
  return true;
}
