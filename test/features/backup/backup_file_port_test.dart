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
    await writeDesktopBackupIfEmpty(file, '{"ok":true}');
    expect(file.readAsStringSync(), '{"ok":true}');
  });

  test('writes when the picker left an empty file', () async {
    final file = File('${dir.path}/empty.json')..writeAsStringSync('');
    await writeDesktopBackupIfEmpty(file, '{"ok":true}');
    expect(file.readAsStringSync(), '{"ok":true}');
  });

  test('keeps picker bytes when the file already has content', () async {
    final file = File('${dir.path}/picked.json')
      ..writeAsStringSync('{"from":"picker"}');
    await writeDesktopBackupIfEmpty(file, '{"from":"app"}');
    expect(file.readAsStringSync(), '{"from":"picker"}');
  });

  test('rethrows when write fails and the file has no content', () async {
    final notADir = File('${dir.path}/not-a-dir')..writeAsStringSync('x');
    final file = File('${notADir.path}/mangajp-backup.json');

    await expectLater(
      writeDesktopBackupIfEmpty(file, '{"ok":true}'),
      throwsA(isA<FileSystemException>()),
    );
    expect(file.existsSync(), isFalse);
  });
}
