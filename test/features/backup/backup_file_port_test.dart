import 'dart:io';

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

  test('writes when the picker left no file', () async {
    final file = File('${dir.path}/mangajp-backup.json');
    await writeDesktopBackupAtomically(file, '{"ok":true}');
    expect(file.readAsStringSync(), '{"ok":true}');
    expect(File('${file.path}.tmp').existsSync(), isFalse);
  });

  test('writes when the picker left an empty file', () async {
    final file = File('${dir.path}/empty.json')..writeAsStringSync('');
    await writeDesktopBackupAtomically(file, '{"ok":true}');
    expect(file.readAsStringSync(), '{"ok":true}');
  });

  test('replaces picker bytes after a verified temp write', () async {
    final file = File('${dir.path}/picked.json')
      ..writeAsStringSync('{"from":"picker"}');
    await writeDesktopBackupAtomically(file, '{"from":"app"}');
    expect(file.readAsStringSync(), '{"from":"app"}');
  });

  test('rethrows when write fails and the file has no content', () async {
    final notADir = File('${dir.path}/not-a-dir')..writeAsStringSync('x');
    final file = File('${notADir.path}/mangajp-backup.json');

    await expectLater(
      writeDesktopBackupAtomically(file, '{"ok":true}'),
      throwsA(isA<FileSystemException>()),
    );
    expect(file.existsSync(), isFalse);
  });

  test('mid-write failure deletes the partial and does not count as success',
      () async {
    final file = File('${dir.path}/mangajp-backup.json');
    const contents = '{"ok":true,"schema_version":10}';

    await expectLater(
      writeDesktopBackupAtomically(
        file,
        contents,
        writeTmp: (tmp, bytes) async {
          await tmp.writeAsBytes(bytes.sublist(0, 3), flush: true);
          throw const FileSystemException('No space left on device', '');
        },
      ),
      throwsA(isA<FileSystemException>()),
    );

    expect(file.existsSync(), isFalse);
    expect(File('${file.path}.tmp').existsSync(), isFalse);
  });

  test('length mismatch after a short write is failure, dest stays untouched',
      () async {
    final file = File('${dir.path}/mangajp-backup.json')
      ..writeAsStringSync('{"keep":true}');

    await expectLater(
      writeDesktopBackupAtomically(
        file,
        '{"ok":true}',
        writeTmp: (tmp, bytes) async {
          await tmp.writeAsBytes(bytes.sublist(0, 4), flush: true);
        },
      ),
      throwsA(isA<FileSystemException>()),
    );

    expect(file.readAsStringSync(), '{"keep":true}');
    expect(File('${file.path}.tmp').existsSync(), isFalse);
  });

  test('rejects non-JSON after write and deletes the temp', () async {
    final file = File('${dir.path}/mangajp-backup.json');
    await expectLater(
      writeDesktopBackupAtomically(file, 'not-json{'),
      throwsA(isA<FormatException>()),
    );
    expect(file.existsSync(), isFalse);
    expect(File('${file.path}.tmp').existsSync(), isFalse);
  });
}
