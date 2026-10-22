import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/database/linux_app_support_migration.dart';

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('linux-app-support-');
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  Directory dir(String name) => Directory('${root.path}/$name');

  File marker(Directory folder, [String name = 'mangajp.sqlite']) {
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

  test('both exist with data: does not overwrite new', () {
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
}
