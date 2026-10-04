import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Bake `tools/build_jmdict_sqlite/testdata/jmdict_fixture.xml` to [tmp].
Future<String> bakeJmdictFixture(Directory tmp) async {
  final dbPath = '${tmp.path}${Platform.pathSeparator}jmdict.sqlite';
  final result = await Process.run('python3', [
    'tools/build_jmdict_sqlite/build_jmdict_sqlite.py',
    '--input',
    'tools/build_jmdict_sqlite/testdata/jmdict_fixture.xml',
    '--kanjidic',
    'tools/build_jmdict_sqlite/testdata/kanjidic2_fixture.xml',
    '--no-download',
    '--output',
    dbPath,
  ]);
  expect(
    result.exitCode,
    0,
    reason: 'stdout:\n${result.stdout}\nstderr:\n${result.stderr}',
  );
  return dbPath;
}
