import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/features/dictionary/data/dictionary_lookup.dart';
import 'package:manga_jp/features/dictionary/data/jmdict_service.dart';

import 'bake_jmdict_fixture.dart';

const taberuSeq = 1358280;
const highHomographSeq = 9990001;
const lowHomographSeq = 9990002;

void main() {
  late Directory tmp;
  late String dbPath;
  late JmdictService jmdict;
  late DictionaryLookup lookup;

  setUpAll(() async {
    tmp = await Directory.systemTemp.createTemp('lookup_fixture_');
    dbPath = await bakeJmdictFixture(tmp);
  });

  tearDownAll(() async {
    if (tmp.existsSync()) {
      await tmp.delete(recursive: true);
    }
  });

  setUp(() {
    jmdict = JmdictService()..openFile(dbPath);
    lookup = DictionaryLookup(jmdict);
  });

  tearDown(() {
    jmdict.close();
  });

  test('real app path is the M0.5 asset, not a hardcoded gloss', () {
    expect(JmdictService.assetPath, 'assets/dict/jmdict.sqlite');
    final providerSrc = File(
      'lib/features/dictionary/data/jmdict_provider.dart',
    ).readAsStringSync();
    expect(providerSrc, contains('openJmdictFromAsset'));
    final nativeOpenSrc = File(
      'lib/features/dictionary/data/jmdict_open_io.dart',
    ).readAsStringSync();
    expect(nativeOpenSrc, contains('ensureJmdictFile'));
    expect(nativeOpenSrc, contains('JmdictService.assetPath'));
    for (final path in [
      'lib/features/dictionary/data/dictionary_lookup.dart',
      'lib/features/dictionary/data/jmdict_provider.dart',
      'lib/features/dictionary/presentation/lookup_sheet.dart',
      'lib/features/notebook/presentation/notebook_word_page.dart',
      'lib/features/notebook/presentation/notebook_controller.dart',
      'lib/features/notebook/data/notebook_repository.dart',
    ]) {
      final src = File(path).readAsStringSync();
      expect(src, isNot(contains('to eat')), reason: path);
      expect(
        src,
        isNot(contains('high-priority fixture homograph')),
        reason: path,
      );
    }
  });

  test('conjugated 食べた resolves to 食べる gloss from JMdict data_json', () {
    final result = lookup.findAt('食べた');
    expect(result, isNotNull);
    expect(result!.entries, hasLength(1));
    expect(result.selected.seq, taberuSeq);
    expect(result.selected.lemma, '食べる');
    expect(result.selected.glosses, contains('to eat'));
    expect(result.selected.glossText, contains('to live on (e.g. a salary)'));

    final rows = jmdict.database.select(
      'SELECT data_json FROM entries WHERE seq = ?',
      [taberuSeq],
    );
    expect(rows, hasLength(1));
    final dataJson = rows.single['data_json'] as String;
    expect(dataJson, contains('to eat'));
    expect(result.selected.glossText, contains('to eat'));
    for (final gloss in result.selected.glosses) {
      expect(dataJson, contains(gloss));
    }
  });

  test('食べます / 高くない also resolve via deinflector', () {
    final ate = lookup.findAt('食べます');
    expect(ate, isNotNull);
    expect(ate!.selected.lemma, '食べる');
    expect(ate.selected.glosses, contains('to eat'));

    final tall = lookup.findAt('高くない');
    expect(tall, isNotNull);
    expect(tall!.selected.lemma, '高い');
    expect(tall.selected.glosses, contains('high'));
    expect(tall.selected.glosses, contains('expensive'));
  });

  test('tap on 食べた inside 猫を食べた still hits 食べる, not 猫', () {
    const text = '猫を食べた';
    final atCat = lookup.findAt(text, tapIndex: 0);
    expect(atCat, isNotNull);
    expect(atCat!.selected.lemma, '猫');
    expect(
      atCat.selected.glosses,
      contains('cat (esp. the domestic cat, Felis catus)'),
    );

    final atEat = lookup.findAt(text, tapIndex: text.indexOf('食'));
    expect(atEat, isNotNull);
    expect(atEat!.surface, '食べた');
    expect(atEat.selected.lemma, '食べる');
    expect(atEat.selected.glosses, contains('to eat'));
  });

  test('several entries: default is highest forms.priority', () {
    final result = lookup.findAt('優先語');
    expect(result, isNotNull);
    expect(result!.entries.map((e) => e.seq), [
      highHomographSeq,
      lowHomographSeq,
    ]);
    expect(result.selectedSeq, highHomographSeq);
    expect(result.selected.priority, 90);
    expect(result.entries.last.priority, isNull);
    expect(result.selected.glosses, ['high-priority fixture homograph']);
    expect(result.entries.last.glosses, ['low-priority fixture homograph']);
  });
}
