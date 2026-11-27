import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/features/backup/data/backup_file_port.dart';

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('mj-backup-write-');
  });

  tearDown(() {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  List<File> sidecarTemps(File dest) {
    final parent = dest.parent;
    if (!parent.existsSync() ||
        parent.statSync().type != FileSystemEntityType.directory) {
      return const [];
    }
    return parent
        .listSync()
        .whereType<File>()
        .where(
          (file) =>
              file.path != dest.path &&
              file.path.startsWith('${dest.path}.') &&
              file.path.endsWith('.tmp'),
        )
        .toList();
  }

  test('macOS mode is in-place; Linux/Windows use a sidecar', () {
    expect(
      desktopBackupWriteModeFor(macos: true, linux: false, windows: false),
      DesktopBackupWriteMode.inPlace,
    );
    expect(
      desktopBackupWriteModeFor(macos: false, linux: true, windows: false),
      DesktopBackupWriteMode.atomicSidecar,
    );
    expect(
      desktopBackupWriteModeFor(macos: false, linux: false, windows: true),
      DesktopBackupWriteMode.atomicSidecar,
    );
  });

  test('Linux/Windows picker must not receive bytes (would clobber dest)', () {
    final bytes = Uint8List.fromList(utf8.encode('{"ok":true}'));
    expect(
      desktopPickerBytes(DesktopBackupWriteMode.atomicSidecar, bytes),
      isNull,
    );
    expect(desktopPickerBytes(DesktopBackupWriteMode.inPlace, bytes), bytes);
  });

  test('atomic sidecar writes when the picker left no file', () async {
    final file = File('${dir.path}/mangajp-backup.json');
    await persistPickedDesktopBackup(
      file,
      '{"ok":true}',
      mode: DesktopBackupWriteMode.atomicSidecar,
    );
    expect(file.readAsStringSync(), '{"ok":true}');
    expect(sidecarTemps(file), isEmpty);
    expect(File('${file.path}.tmp').existsSync(), isFalse);
  });

  test('atomic sidecar writes when the picker left an empty file', () async {
    final file = File('${dir.path}/empty.json')..writeAsStringSync('');
    await persistPickedDesktopBackup(
      file,
      '{"ok":true}',
      mode: DesktopBackupWriteMode.atomicSidecar,
    );
    expect(file.readAsStringSync(), '{"ok":true}');
  });

  test(
    'atomic sidecar replaces picker bytes after a verified temp write',
    () async {
      final file = File('${dir.path}/picked.json')
        ..writeAsStringSync('{"from":"picker"}');
      await persistPickedDesktopBackup(
        file,
        '{"from":"app"}',
        mode: DesktopBackupWriteMode.atomicSidecar,
      );
      expect(file.readAsStringSync(), '{"from":"app"}');
    },
  );

  test(
    'atomic sidecar rethrows when write fails and the file has no content',
    () async {
      final notADir = File('${dir.path}/not-a-dir')..writeAsStringSync('x');
      final file = File('${notADir.path}/mangajp-backup.json');

      await expectLater(
        persistPickedDesktopBackup(
          file,
          '{"ok":true}',
          mode: DesktopBackupWriteMode.atomicSidecar,
        ),
        throwsA(isA<FileSystemException>()),
      );
      expect(file.existsSync(), isFalse);
    },
  );

  test(
    'mid-write failure deletes the partial and does not count as success',
    () async {
      final file = File('${dir.path}/mangajp-backup.json');
      const contents = '{"ok":true,"schema_version":10}';

      await expectLater(
        persistPickedDesktopBackup(
          file,
          contents,
          mode: DesktopBackupWriteMode.atomicSidecar,
          writeTmp: (tmp, bytes) async {
            await tmp.writeAsBytes(bytes.sublist(0, 3), flush: true);
            throw const FileSystemException('No space left on device', '');
          },
        ),
        throwsA(isA<FileSystemException>()),
      );

      expect(file.existsSync(), isFalse);
      expect(sidecarTemps(file), isEmpty);
    },
  );

  test(
    'length mismatch after a short write is failure, dest stays untouched',
    () async {
      final file = File('${dir.path}/mangajp-backup.json')
        ..writeAsStringSync('{"keep":true}');

      await expectLater(
        persistPickedDesktopBackup(
          file,
          '{"ok":true}',
          mode: DesktopBackupWriteMode.atomicSidecar,
          writeTmp: (tmp, bytes) async {
            await tmp.writeAsBytes(bytes.sublist(0, 4), flush: true);
          },
        ),
        throwsA(isA<FileSystemException>()),
      );

      expect(file.readAsStringSync(), '{"keep":true}');
      expect(sidecarTemps(file), isEmpty);
    },
  );

  test('rejects non-JSON after write and deletes the temp', () async {
    final file = File('${dir.path}/mangajp-backup.json');
    await expectLater(
      persistPickedDesktopBackup(
        file,
        'not-json{',
        mode: DesktopBackupWriteMode.atomicSidecar,
      ),
      throwsA(isA<FormatException>()),
    );
    expect(file.existsSync(), isFalse);
    expect(sidecarTemps(file), isEmpty);
  });

  test('macOS in-place accepts picker bytes that already match', () async {
    const contents = '{"ok":true,"schema_version":10}';
    final file = File('${dir.path}/mangajp-backup.json')
      ..writeAsStringSync(contents);

    await persistPickedDesktopBackup(
      file,
      contents,
      mode: DesktopBackupWriteMode.inPlace,
    );

    expect(file.readAsStringSync(), contents);
    expect(sidecarTemps(file), isEmpty);
    expect(File('${file.path}.tmp').existsSync(), isFalse);
  });

  test(
    'macOS in-place rewrites the chosen path when picker bytes are wrong',
    () async {
      const contents = '{"ok":true,"schema_version":10}';
      final file = File('${dir.path}/mangajp-backup.json')
        ..writeAsStringSync('{"from":"picker-truncated"');

      await persistPickedDesktopBackup(
        file,
        contents,
        mode: DesktopBackupWriteMode.inPlace,
      );

      expect(file.readAsStringSync(), contents);
      expect(sidecarTemps(file), isEmpty);
      expect(desktopBackupMatches(file, contents), isTrue);
    },
  );

  test('macOS in-place writes when the picker left no file', () async {
    final file = File('${dir.path}/mangajp-backup.json');
    await persistPickedDesktopBackup(
      file,
      '{"ok":true}',
      mode: DesktopBackupWriteMode.inPlace,
    );
    expect(file.readAsStringSync(), '{"ok":true}');
    expect(sidecarTemps(file), isEmpty);
  });

  test(
    'macOS in-place does not report success when dest stays invalid',
    () async {
      final notADir = File('${dir.path}/not-a-dir')..writeAsStringSync('x');
      final file = File('${notADir.path}/mangajp-backup.json');

      await expectLater(
        persistPickedDesktopBackup(
          file,
          '{"ok":true}',
          mode: DesktopBackupWriteMode.inPlace,
        ),
        throwsA(isA<FileSystemException>()),
      );
      expect(file.existsSync(), isFalse);
      expect(sidecarTemps(file), isEmpty);
    },
  );
}
