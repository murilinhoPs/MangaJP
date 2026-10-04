import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/deinflect/deinflector.dart';
import 'package:manga_jp/core/deinflect/rules.dart';
import 'package:manga_jp/features/dictionary/data/jmdict_service.dart';

import 'lemma_vectors.dart';

void main() {
  const deinflector = Deinflector();

  test('core deinflect is Dart-only (no Flutter import)', () {
    for (final path in [
      'lib/core/deinflect/deinflector.dart',
      'lib/core/deinflect/rules.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('package:flutter')), reason: path);
    }
  });

  test('rules table credits Yomitan and is non-empty', () {
    expect(
      kYomitanTransformsCommit,
      '67db60ddc2cbd7b5172d777c117e3201d7ddff0f',
    );
    expect(kYomitanTransformsPath, contains('japanese-transforms.js'));
    expect(japaneseTransforms, isNotEmpty);
    expect(japaneseTransforms.fold<int>(0, (n, t) => n + t.rules.length), 889);
  });

  test('spot checks: ichidan / godan / irregular', () {
    expect(deinflector.candidates('食べた'), contains('食べる'));
    expect(deinflector.candidates('書いて'), contains('書く'));
    expect(deinflector.candidates('した'), contains('する'));
    expect(deinflector.candidates('来て'), contains('来る'));
    expect(deinflector.candidates('行って'), contains('行く'));
    expect(deinflector.candidates('食べます'), contains('食べる'));
  });

  test('original surface is the first candidate', () {
    expect(deinflector.candidates('食べた').first, '食べた');
  });

  test('flagsFor maps dictionary POS ids to distinct bits', () {
    expect(deinflector.flagsFor(['v1']), isNot(0));
    expect(deinflector.flagsFor(['adj-i']), isNot(0));
    expect(deinflector.flagsFor(['v1']) & deinflector.flagsFor(['adj-i']), 0);
  });

  group('lemma hit rate', () {
    late Directory tmp;
    late String dbPath;
    late JmdictService jmdict;

    setUpAll(() async {
      tmp = await Directory.systemTemp.createTemp('deinflect_forms_');
      dbPath = '${tmp.path}${Platform.pathSeparator}jmdict.sqlite';
      final result = await Process.run('python3', [
        'tools/build_jmdict_sqlite/build_jmdict_sqlite.py',
        '--input',
        'test/core/deinflect/testdata/lemma_forms.xml',
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

    test('expected lemmas exist in baked forms', () {
      final lemmas = {for (final v in lemmaVectors) v.lemma};
      expect(lemmas, isNotEmpty);
      for (final lemma in lemmas) {
        expect(jmdict.hasForm(lemma), isTrue, reason: lemma);
      }
    });

    test('≥50 vectors, expected lemma among candidates, hit rate ≥80%', () {
      expect(lemmaVectors.length, greaterThanOrEqualTo(50));

      final groups = {for (final v in lemmaVectors) v.group.split('-').first};
      expect(groups, containsAll(<String>['ichidan', 'godan', 'irregular']));
      expect(
        lemmaVectors.map((v) => v.group),
        containsAll(<String>[
          'ichidan-te',
          'godan-te',
          'ichidan-past',
          'godan-past',
          'ichidan-negative',
          'godan-negative',
          'ichidan-polite',
          'godan-polite',
          'irregular-past',
        ]),
      );
      expect(lemmaVectors.where((v) => v.lemma == 'する'), isNotEmpty);
      expect(lemmaVectors.where((v) => v.lemma == '来る'), isNotEmpty);
      expect(lemmaVectors.where((v) => v.lemma == '行く'), isNotEmpty);

      var hits = 0;
      final misses = <LemmaVector>[];
      for (final vector in lemmaVectors) {
        final candidates = deinflector.candidates(vector.surface);
        // Honest score: expected dictionary form is among deinflect results
        // *and* that form exists in JMdict `forms`.
        final hit =
            candidates.contains(vector.lemma) && jmdict.hasForm(vector.lemma);
        if (hit) {
          hits++;
        } else {
          misses.add(vector);
        }
      }

      final percent = 100.0 * hits / lemmaVectors.length;
      // ignore: avoid_print
      print(
        'deinflect lemma hit rate: ${percent.toStringAsFixed(1)}% '
        '($hits/${lemmaVectors.length})',
      );
      if (misses.isNotEmpty) {
        // ignore: avoid_print
        print('misses: $misses');
      }

      expect(
        percent,
        greaterThanOrEqualTo(80.0),
        reason:
            'hit rate ${percent.toStringAsFixed(1)}% '
            '($hits/${lemmaVectors.length}); misses: $misses',
      );
    });
  });
}
