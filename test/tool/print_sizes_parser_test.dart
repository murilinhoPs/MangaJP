import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/telas/print_sizes.dart';
import '../../tool/telas/telas_index.dart';

String _fixture(String name) =>
    File('test/tool/fixtures/$name').readAsStringSync();

void main() {
  test('v0 filename WxH bytes (pr-41 m125_print_sizes.txt)', () {
    final parsed = parsePrintSizes(_fixture('v0_m125_print_sizes.txt'));
    expect(parsed.variants, {PrintSizesVariant.v0FilenameWxHBytes});
    expect(parsed.headSha, isNull);
    expect(parsed.entries, hasLength(13));
    expect(
      parsed.entries.first.relativePath,
      'm125_desktop_caderno_detail_learning.png',
    );
    expect(parsed.entries.first.width, 1280);
    expect(parsed.entries.first.height, 800);
    expect(parsed.entries.first.byteSize, 42585);
    expect(parsed.entries.first.sha256, isNull);
    expect(
      parsed.entries
          .map((e) => e.relativePath)
          .where((p) => p.startsWith('m125_phone_')),
      hasLength(7),
    );
    expect(parsed.skipped, isEmpty);
  });

  test('v0 short file (pr-42 m123_print_sizes.txt)', () {
    final parsed = parsePrintSizes(_fixture('v0_m123_print_sizes.txt'));
    expect(parsed.variants, {PrintSizesVariant.v0FilenameWxHBytes});
    expect(parsed.entries, hasLength(2));
    expect(parsed.entries[0].width, 1280);
    expect(parsed.entries[1].width, 390);
    expect(parsed.entries[1].height, 844);
  });

  test('v1 head_sha + platform/file WxH bytes (pr-46/038d401)', () {
    final parsed = parsePrintSizes(_fixture('v1_head_sha.txt'));
    expect(parsed.variants, {PrintSizesVariant.v1HeadShaWxHBytes});
    expect(parsed.headSha, '038d4010db2d842b939c7e0b5907f47a49f0cb98');
    expect(parsed.headSha7, '038d401');
    expect(parsed.entries, hasLength(9));
    expect(parsed.entries.map((e) => e.platformDir).toSet(), {
      'ios',
      'android',
      'desktop',
    });
    expect(parsed.entries.every((e) => e.sha256 == null), isTrue);
    expect(parsed.entries[3].relativePath, 'android/page.png');
    expect(parsed.entries[3].width, 390);
    expect(parsed.entries[6].relativePath, 'desktop/page.png');
    expect(parsed.entries[6].height, 800);
    expect(parsed.skipped, isEmpty);
  });

  test('v1b indented sha256 continuation (pr-46/b32d250)', () {
    final parsed = parsePrintSizes(_fixture('v1b_sha256_continued.txt'));
    expect(parsed.variants, {PrintSizesVariant.v1HeadShaSha256Continued});
    expect(parsed.headSha, 'b32d2503985b1566b6f5dfdd3fd234698f6a4d95');
    expect(parsed.entries, hasLength(10));
    expect(
      parsed.entries.every(
        (e) => e.sha256 != null && e.sha256!.length == 64 && e.sha256Valid,
      ),
      isTrue,
    );
    expect(parsed.entries[3].relativePath, 'ios/swipe.png');
    expect(
      parsed.entries[3].sha256,
      '8c312c2d791a11f58f0f4a64dc6182e45d968d63be5977eb43b4ae6fd3bcd657',
    );
  });

  test('v2 head: + inline sha256: (pr-50, print-rules canonical)', () {
    final parsed = parsePrintSizes(_fixture('v2_head_colon.txt'));
    expect(parsed.variants, {PrintSizesVariant.v2HeadColonInlineSha256});
    expect(parsed.headSha, 'fbb15b51adbc69c39d0737bdbb70678e686ecd54');
    expect(parsed.headSha7, 'fbb15b5');
    expect(parsed.entries, hasLength(3));
    expect(parsed.entries[0].relativePath, 'macos/nsopenpanel.png');
    expect(parsed.entries[0].width, 1280);
    expect(parsed.entries[0].coral, 3319);
    expect(parsed.entries[0].bg, 511495);
    expect(
      parsed.entries[0].sha256,
      '3251d918bc0e257eb5a7ff85207547052a05a1d55c034ed1aeb50ce3ded39a17',
    );
    expect(parsed.entries.every((e) => e.sha256Valid), isTrue);
  });

  test('malformed sha256 of 62 hex from pr-48 still yields the print', () {
    final parsed = parsePrintSizes(_fixture('v1b_malformed_sha256.txt'));
    expect(parsed.variants, {PrintSizesVariant.v1HeadShaSha256Continued});
    final crop = parsed.entries
        .where((e) => e.relativePath == 'android/crop.png')
        .single;
    expect(crop.width, 390);
    expect(crop.height, 844);
    expect(
      crop.sha256,
      '2e713c9668e00baad2abd047d874fcdc4a851b1aeb9cbf2e689787edfe8d8a',
    );
    expect(crop.sha256, hasLength(62));
    expect(crop.sha256Valid, isFalse);
    expect(
      parsed.skipped.any((s) => s.reason.contains('sha256 tem 62 hex')),
      isTrue,
    );
    expect(parsed.entries, hasLength(9));
  });

  test('malformed lines are skipped without dropping valid prints', () {
    final parsed = parsePrintSizes(_fixture('malformed.txt'));
    expect(parsed.entries, hasLength(1));
    expect(parsed.entries.single.relativePath, 'android/ok.png');
    expect(parsed.entries.single.sha256Valid, isTrue);
    expect(parsed.headSha, isNull);
    expect(parsed.skipped, isNotEmpty);
    expect(
      parsed.skipped.map((s) => s.reason).toList(),
      containsAll([
        'head: SHA-1 não tem 40 hex',
        'head_sha não tem 40 hex',
        'head_sha7 inválido',
        'linha não reconhecida',
        'sha256 continuado sem linha de print',
      ]),
    );
  });

  test('platform and feature mapping from real paths', () {
    expect(
      platformFromFileName('m125_phone_caderno_list.png'),
      TelasPlatform.android,
    );
    expect(
      platformFromFileName('m125_desktop_captura.png'),
      TelasPlatform.linuxDesktop,
    );
    expect(screenStem('m125_phone_caderno_list.png'), 'caderno_list');
    expect(featureForStem('caderno_list'), 'Caderno');
    expect(featureForStem('nsopenpanel'), 'Galeria');
    expect(featureForStem('home_cancel'), 'Galeria');
    expect(featureForStem('crop'), 'Recorte');
    expect(featureForStem('review_dialog'), 'Revisão');
    expect(featureForStem('swipe'), 'Leitor');
    expect(featureForStem('word'), 'Caderno');

    final loc = parsePrintSizesLocation(
      'docs/pr-assets/pr-50/fbb15b5/print_sizes.txt',
    )!;
    expect(loc.prNumber, 50);
    expect(loc.sha7, 'fbb15b5');
    final parsed = parsePrintSizes(_fixture('v2_head_colon.txt'));
    expect(platformFrom(parsed.entries.first, loc), TelasPlatform.macos);
  });

  test('print-rules dimension checks', () {
    expect(androidDimensionsOk(390, 844), isTrue);
    expect(androidDimensionsOk(780, 1688), isTrue);
    expect(androidDimensionsOk(1170, 2532), isTrue);
    expect(androidDimensionsOk(389, 844), isFalse);
    expect(androidDimensionsOk(390, 843), isFalse);
    expect(androidDimensionsOk(780, 844), isFalse);
    expect(violatesPrintRules(TelasPlatform.android, 390, 844), isFalse);
    expect(violatesPrintRules(TelasPlatform.linuxDesktop, 1280, 800), isFalse);
    expect(violatesPrintRules(TelasPlatform.linuxDesktop, 1280, 801), isTrue);
    expect(violatesPrintRules(TelasPlatform.macos, 1280, 800), isFalse);
    expect(violatesPrintRules(TelasPlatform.macos, 2560, 1600), isTrue);
    expect(violatesPrintRules(TelasPlatform.ios, 1206, 2622), isFalse);
    expect(
      violatesPrintRules(TelasPlatform.macos, 900, 800, declaredCrop: true),
      isFalse,
    );
  });

  test('declared crop off-size is not a print-rules violation', () {
    const content = '''
head: dddddddddddddddddddddddddddddddddddddddd
macos/nsopenpanel.png 900x800 recorte sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
''';
    final parsed = parsePrintSizes(content);
    expect(parsed.entries.single.declaredCrop, isTrue);
    final index = buildTelasIndex([
      (path: 'docs/pr-assets/pr-50/ddddddd/print_sizes.txt', content: content),
    ]);
    expect(index.prints.single.violatesPrintRules, isFalse);
    final md = buildTelasMarkdown(
      index: index,
      repoUrl: 'https://github.com/murilinhoPs/MangaJP',
    );
    expect(md, contains('| `macos/nsopenpanel.png` | 900×800 |'));
    expect(md, isNot(contains('900×800 **fora da regra**')));
  });

  test('cropped print without declaration violates print-rules', () {
    const content = '''
head: eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
macos/nsopenpanel.png 900x800 sha256:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
''';
    final parsed = parsePrintSizes(content);
    expect(parsed.entries.single.declaredCrop, isFalse);
    final index = buildTelasIndex([
      (path: 'docs/pr-assets/pr-50/eeeeeee/print_sizes.txt', content: content),
    ]);
    expect(index.prints.single.violatesPrintRules, isTrue);
    final md = buildTelasMarkdown(
      index: index,
      repoUrl: 'https://github.com/murilinhoPs/MangaJP',
    );
    expect(md, contains('900×800 **fora da regra**'));
  });

  test('blurred print at required size is not a print-rules violation', () {
    const content = '''
head: ffffffffffffffffffffffffffffffffffffffff
macos/nsopenpanel.png 1280x800 sha256:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
android/home.png 390x844 sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
''';
    final parsed = parsePrintSizes(content);
    expect(parsed.entries.every((e) => !e.declaredCrop), isTrue);
    final index = buildTelasIndex([
      (path: 'docs/pr-assets/pr-50/fffffff/print_sizes.txt', content: content),
    ]);
    expect(index.prints.every((p) => !p.violatesPrintRules), isTrue);
    final md = buildTelasMarkdown(
      index: index,
      repoUrl: 'https://github.com/murilinhoPs/MangaJP',
    );
    expect(md, contains('| `macos/nsopenpanel.png` | 1280×800 |'));
    expect(md, contains('| `android/home.png` | 390×844 |'));
    expect(md, isNot(contains('**fora da regra** |')));
  });

  test('index + markdown is deterministic and marks violations', () {
    final files = [
      (
        path: 'docs/pr-assets/pr-41/9029318/m125_print_sizes.txt',
        content: _fixture('v0_m125_print_sizes.txt'),
      ),
      (
        path: 'docs/pr-assets/pr-50/fbb15b5/print_sizes.txt',
        content: _fixture('v2_head_colon.txt'),
      ),
      (
        path: 'docs/pr-assets/pr-46/038d401/print_sizes.txt',
        content: _fixture('v1_head_sha.txt'),
      ),
    ];
    final index = buildTelasIndex(files);
    expect(index.filesParsed, 3);
    expect(index.prints, isNotEmpty);

    final iosPage = index.prints
        .where((p) => p.relativePath == 'ios/page.png' && p.prNumber == 46)
        .single;
    expect(iosPage.violatesPrintRules, isFalse);
    expect(iosPage.width, 1206);

    final androidPage = index.prints
        .where((p) => p.relativePath == 'android/page.png')
        .single;
    expect(androidPage.violatesPrintRules, isFalse);

    final md1 = buildTelasMarkdown(
      index: index,
      repoUrl: 'https://github.com/murilinhoPs/MangaJP',
    );
    final md2 = buildTelasMarkdown(
      index: index,
      repoUrl: 'https://github.com/murilinhoPs/MangaJP',
    );
    expect(md1, md2);
    expect(
      md1.startsWith(
        '<!-- Generated by tool/gen_telas.dart. Do not edit. -->\n',
      ),
      isTrue,
    );
    expect(md1, contains('dart run tool/gen_telas.dart'));
    expect(
      md1,
      contains('[#50](https://github.com/murilinhoPs/MangaJP/pull/50)'),
    );
    expect(
      md1,
      contains(
        '[blob](https://github.com/murilinhoPs/MangaJP/blob/pr-assets/docs/pr-assets/pr-50/fbb15b5/macos/nsopenpanel.png)',
      ),
    );
    expect(
      md1,
      contains(
        '[raw](https://github.com/murilinhoPs/MangaJP/raw/pr-assets/docs/pr-assets/pr-50/fbb15b5/macos/nsopenpanel.png)',
      ),
    );
    expect(md1, contains('### Linux desktop'));
    expect(md1, contains('### macOS'));
    expect(md1, contains('simulador iPhone 17, qualquer resolução'));
    expect(md1, isNot(contains('resolução pendente')));
    expect(md1, contains('v0-filename-wxh-bytes'));
    expect(md1, contains('v2-head-colon-inline-sha256'));

    // Latest PR first within a screen: pr-50 galeria before nothing else on macos.
    final macosNs = md1.indexOf('macos/nsopenpanel.png');
    expect(macosNs, greaterThan(0));
  });

  test(
    'latest print per screen is listed first (higher PR, then add date)',
    () {
      const older = '''
head: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
android/home.png 390x844 sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
''';
      const newer = '''
head: bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
android/home.png 390x844 sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
''';
      final index = buildTelasIndex(
        [
          (
            path: 'docs/pr-assets/pr-10/aaaaaaa/print_sizes.txt',
            content: older,
          ),
          (
            path: 'docs/pr-assets/pr-40/bbbbbbb/print_sizes.txt',
            content: newer,
          ),
        ],
        sha7AddedAt: {'pr-10/aaaaaaa': 999, 'pr-40/bbbbbbb': 1},
      );
      final homes = index.prints.where((p) => p.screen == 'home').toList();
      expect(homes, hasLength(2));
      expect(homes.first.prNumber, 40);
      expect(homes.last.prNumber, 10);
    },
  );

  test('same PR: newer pr-assets folder first, not sha7 alphabetical', () {
    const row = '''
head: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
android/home.png 390x844 sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
''';
    final index = buildTelasIndex(
      [
        (path: 'docs/pr-assets/pr-49/bbbbbbb/print_sizes.txt', content: row),
        (path: 'docs/pr-assets/pr-49/aaaaaaa/print_sizes.txt', content: row),
      ],
      sha7AddedAt: {'pr-49/bbbbbbb': 100, 'pr-49/aaaaaaa': 200},
    );
    final homes = index.prints.where((p) => p.screen == 'home').toList();
    expect(homes.first.sha7, 'aaaaaaa');
    expect(homes.last.sha7, 'bbbbbbb');
    expect(homes.first.addedAt, 200);
  });

  test('parseSha7AddedAt keeps first add under --reverse git log', () {
    const log = '''
COMMIT 100
docs/pr-assets/pr-49/bbbbbbb/android/home.png
COMMIT 200
docs/pr-assets/pr-49/aaaaaaa/print_sizes.txt
COMMIT 300
docs/pr-assets/pr-49/bbbbbbb/android/review.png
''';
    final map = parseSha7AddedAt(log);
    expect(map['pr-49/bbbbbbb'], 100);
    expect(map['pr-49/aaaaaaa'], 200);
  });

  test('skip stderr example: arquivo sem prints reconhecidos', () {
    final index = buildTelasIndex([
      (
        path: 'docs/pr-assets/pr-99/deadbee/print_sizes.txt',
        content: 'isto nao e um print\n',
      ),
    ]);
    expect(index.prints, isEmpty);
    expect(index.skippedFiles, hasLength(1));
    expect(index.skippedFiles.single.reason, 'nenhum print reconhecido');
    final buf = StringBuffer();
    emitSkipWarnings(
      skippedFiles: index.skippedFiles,
      skippedLines: index.skipped,
      sink: buf,
      githubAnnotations: false,
    );
    expect(
      buf.toString(),
      contains(
        'skip: docs/pr-assets/pr-99/deadbee/print_sizes.txt: nenhum print reconhecido',
      ),
    );
    expect(
      telasGeneratorExitCode(
        candidateCount: index.candidateCount,
        skippedFileCount: index.skippedFiles.length,
        strict: false,
      ),
      0,
    );
    expect(
      telasGeneratorExitCode(
        candidateCount: index.candidateCount,
        skippedFileCount: index.skippedFiles.length,
        strict: true,
      ),
      1,
    );
  });

  test('CI skip is warning with ::warning:: and exit 0', () {
    final index = buildTelasIndex([
      (
        path: 'docs/pr-assets/pr-99/deadbee/print_sizes.txt',
        content: 'isto nao e um print\n',
      ),
    ]);
    final buf = StringBuffer();
    emitSkipWarnings(
      skippedFiles: index.skippedFiles,
      skippedLines: const [],
      sink: buf,
      githubAnnotations: true,
    );
    expect(
      buf.toString(),
      contains(
        '::warning file=docs/pr-assets/pr-99/deadbee/print_sizes.txt::skip: docs/pr-assets/pr-99/deadbee/print_sizes.txt: nenhum print reconhecido',
      ),
    );
    expect(
      telasGeneratorExitCode(
        candidateCount: 1,
        skippedFileCount: 1,
        strict: false,
      ),
      0,
    );
    expect(
      telasGeneratorExitCode(
        candidateCount: 0,
        skippedFileCount: 0,
        strict: false,
      ),
      1,
    );
  });

  test('pr-48 malformed sha256 is a line warning, not a skipped file', () {
    final index = buildTelasIndex([
      (
        path: 'docs/pr-assets/pr-48/2182efb/print_sizes.txt',
        content: _fixture('v1b_malformed_sha256.txt'),
      ),
    ]);
    expect(index.skippedFiles, isEmpty);
    expect(index.prints, hasLength(9));
    expect(
      index.skipped.any((s) => s.reason.contains('sha256 tem 62 hex')),
      isTrue,
    );
    final buf = StringBuffer();
    emitSkipWarnings(
      skippedFiles: index.skippedFiles,
      skippedLines: index.skipped,
      sink: buf,
      githubAnnotations: false,
    );
    expect(buf.toString(), contains('sha256 tem 62 hex'));
    expect(
      telasGeneratorExitCode(
        candidateCount: index.candidateCount,
        skippedFileCount: index.skippedFiles.length,
        strict: true,
      ),
      0,
    );
  });

  test('markdown marks Android/desktop dimension violations', () {
    const bad = '''
head: cccccccccccccccccccccccccccccccccccccccc
android/home.png 100x200 sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
desktop/home.png 1024x768 sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
''';
    final index = buildTelasIndex([
      (path: 'docs/pr-assets/pr-1/ccccccc/print_sizes.txt', content: bad),
    ]);
    expect(index.prints.every((p) => p.violatesPrintRules), isTrue);
    final md = buildTelasMarkdown(
      index: index,
      repoUrl: 'https://github.com/murilinhoPs/MangaJP',
    );
    expect(md, contains('100×200 **fora da regra**'));
    expect(md, contains('1024×768 **fora da regra**'));
  });

  test('stripGitRemote drops tokens and normalizes ssh', () {
    expect(
      stripGitRemote(
        'https://x-access-token:ghs_secret@github.com/murilinhoPs/MangaJP.git',
      ),
      'https://github.com/murilinhoPs/MangaJP',
    );
    expect(
      stripGitRemote('git@github.com:murilinhoPs/MangaJP.git'),
      'https://github.com/murilinhoPs/MangaJP',
    );
    expect(
      stripGitRemote('https://github.com/murilinhoPs/MangaJP'),
      'https://github.com/murilinhoPs/MangaJP',
    );
  });

  test('missing origin/pr-assets git error is a fetch hint', () {
    expect(
      isMissingGitRefError('fatal: Not a valid object name origin/pr-assets\n'),
      isTrue,
    );
    expect(
      isMissingGitRefError(
        "fatal: ambiguous argument 'origin/pr-assets': "
        'unknown revision or path not in the working tree.\n',
      ),
      isTrue,
    );
    expect(isMissingGitRefError('git falhou: permission denied'), isFalse);
    expect(
      missingGitRefMessage('origin/pr-assets'),
      'ref origin/pr-assets não encontrada; rode git fetch origin pr-assets',
    );
  });

  test('ignores print_sizes paths outside pr-N/sha7', () {
    expect(
      isPrintSizesPath('docs/pr-assets/m2.1-smoke/3a69ab8/print_sizes.txt'),
      isFalse,
    );
    expect(
      isPrintSizesPath('docs/pr-assets/pr-41/9029318/m125_print_sizes.txt'),
      isTrue,
    );
    expect(isPrintSizesPath('linux/CMakeLists.txt'), isFalse);
  });
}
