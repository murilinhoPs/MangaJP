import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/database/linux_app_support_migration.dart';

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

      final result = migrateLinuxAppSupportDirectory(
        oldDir: oldDir,
        newDir: newDir,
      );

      expect(result, LinuxAppSupportMigrationResult.migrated);
      expect(marker(newDir).readAsStringSync(), 'legacy-db');
      expect(File('${newDir.path}/leftover.txt').existsSync(), isFalse);
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
}

void _chmod(String path, String mode) {
  final result = Process.runSync('chmod', [mode, path]);
  expect(result.exitCode, 0, reason: result.stderr.toString());
}
