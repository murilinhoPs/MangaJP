import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Bake `tools/build_jmdict_sqlite/testdata/jmdict_fixture.xml` to [tmp].
///
/// Pass [withKanji] false to leave the `kanji` table empty (same schema).
Future<String> bakeJmdictFixture(Directory tmp, {bool withKanji = true}) async {
  tmp.createSync(recursive: true);
  final dbPath = '${tmp.path}${Platform.pathSeparator}jmdict.sqlite';
  final args = <String>[
    'tools/build_jmdict_sqlite/build_jmdict_sqlite.py',
    '--input',
    'tools/build_jmdict_sqlite/testdata/jmdict_fixture.xml',
    '--no-download',
    '--output',
    dbPath,
  ];
  if (withKanji) {
    args.addAll([
      '--kanjidic',
      'tools/build_jmdict_sqlite/testdata/kanjidic2_fixture.xml',
    ]);
  }
  final result = await Process.run('python3', args);
  expect(
    result.exitCode,
    0,
    reason: 'stdout:\n${result.stdout}\nstderr:\n${result.stderr}',
  );
  return dbPath;
}
