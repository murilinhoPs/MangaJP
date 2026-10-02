import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/features/dictionary/data/jmdict_service.dart';

/// Known fixture entry: 食べる (JMdict seq 1358280), POS v1/vt.
const taberuSeq = 1358280;

void main() {
  late Directory tmp;
  late String dbPath;
  late JmdictService jmdict;

  setUpAll(() async {
    tmp = await Directory.systemTemp.createTemp('jmdict_fixture_');
    dbPath = '${tmp.path}${Platform.pathSeparator}jmdict.sqlite';
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
  });

  tearDownAll(() async {
    if (tmp.existsSync()) {
      await tmp.delete(recursive: true);
    }
  });

  setUp(() {
    jmdict = JmdictService()..openFile(dbPath);
  });

  tearDown(() {
    jmdict.close();
  });

  test('opens fixture with PRD tables and 食べる sense_pos', () {
    expect(
      jmdict.tableNames(),
      containsAll(<String>['entries', 'forms', 'sense_pos']),
    );
    expect(jmdict.posForSeq(taberuSeq), containsAll(<String>['v1', 'vt']));
  });
}
