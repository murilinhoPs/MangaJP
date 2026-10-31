import 'dart:convert';
import 'dart:io';

import 'telas/telas_index.dart';

const _defaultRef = 'origin/pr-assets';
const _defaultOutput = 'docs/qa/telas.md';
const _defaultBranch = 'pr-assets';

void main(List<String> args) {
  exit(runGenTelas(args));
}

int runGenTelas(List<String> args) {
  var ref = _defaultRef;
  var output = _defaultOutput;
  var branch = _defaultBranch;
  String? repoUrl;
  var check = false;
  var strict = false;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    String next() {
      if (i + 1 >= args.length) {
        stderr.writeln('faltou valor para $arg');
        exitCode = 2;
        throw const FormatException('missing value');
      }
      return args[++i];
    }

    switch (arg) {
      case '--help':
      case '-h':
        stdout.writeln(_usage);
        return 0;
      case '--ref':
        ref = next();
      case '--output':
      case '-o':
      case '--out':
        output = next();
      case '--branch':
        branch = next();
      case '--repo-url':
        repoUrl = next();
      case '--check':
        check = true;
      case '--strict':
        strict = true;
      default:
        stderr.writeln('argumento desconhecido: $arg');
        stderr.writeln(_usage);
        return 2;
    }
  }

  try {
    final root = _git(['rev-parse', '--show-toplevel']).trim();
    repoUrl ??= stripGitRemote(
      _git(['remote', 'get-url', 'origin'], cwd: root),
    );
    String? existingMarkdown;
    if (check) {
      final file = File(output.startsWith('/') ? output : '$root/$output');
      if (!file.existsSync()) {
        stderr.writeln(
          '$output não existe. Rode: dart run tool/gen_telas.dart',
        );
        return 1;
      }
      existingMarkdown = utf8.decode(file.readAsBytesSync());
    }

    final names =
        _git(['ls-tree', '-r', '--name-only', ref], cwd: root)
            .split('\n')
            .where((p) => p.isNotEmpty && isPrintSizesCandidate(p))
            .toList()
          ..sort();

    if (names.isEmpty) {
      stderr.writeln('nenhum print_sizes.txt em $ref sob docs/pr-assets/');
      return 1;
    }

    final files = <({String path, String content})>[];
    for (final path in names) {
      files.add((path: path, content: _git(['show', '$ref:$path'], cwd: root)));
    }

    final addedAt = _loadSha7AddedAt(ref, root);
    final filesForIndex = existingMarkdown == null
        ? files
        : printSizesForTelasCheck(
            existingMarkdown: existingMarkdown,
            files: files,
          );
    if (check && filesForIndex.length != files.length) {
      stderr.writeln(
        '--check: ${files.length - filesForIndex.length} print_sizes.txt '
        'novo(s) em pr-assets ignorado(s) (índice pode ficar atrás)',
      );
    }

    // `--check --strict` looks at every candidate, including folders that
    // never entered telas.md because the file was skipped entirely.
    final warnIndex = buildTelasIndex(
      check ? files : filesForIndex,
      sha7AddedAt: addedAt,
    );
    final github = Platform.environment['GITHUB_ACTIONS'] == 'true';
    emitSkipWarnings(
      skippedFiles: warnIndex.skippedFiles,
      skippedLines: warnIndex.skipped,
      sink: stderr,
      githubAnnotations: github,
    );

    final index = check
        ? buildTelasIndex(filesForIndex, sha7AddedAt: addedAt)
        : warnIndex;
    final variantIds = (index.variants.map((v) => v.id).toList()..sort()).join(
      ', ',
    );
    stderr.writeln(
      'telas: ${index.prints.length} print(s), ${index.filesParsed} arquivo(s), '
      '${index.skippedFiles.length} arquivo(s) pulado(s), '
      'formatos: ${variantIds.isEmpty ? '(nenhum)' : variantIds}',
    );

    // `--check` still compares when the indexed subset is empty (telas.md
    // behind). candidateCount==0 only fails the generate path.
    if (!check) {
      final status = telasGeneratorExitCode(
        candidateCount: index.candidateCount,
        skippedFileCount: index.skippedFiles.length,
        strict: strict,
      );
      if (status != 0) {
        if (index.candidateCount == 0) {
          stderr.writeln('nenhum print_sizes.txt encontrado no ref');
        }
        if (strict && index.skippedFiles.isNotEmpty) {
          stderr.writeln(
            '--strict: ${index.skippedFiles.length} print_sizes.txt pulado(s)',
          );
        }
        return status;
      }
    } else {
      final markdown = existingMarkdown;
      if (markdown == null) {
        stderr.writeln(
          '$output não existe. Rode: dart run tool/gen_telas.dart',
        );
        return 1;
      }
      final status = telasCheckExitCode(
        existingMarkdown: markdown,
        files: files,
        sha7AddedAt: addedAt,
        repoUrl: repoUrl,
        assetsBranch: branch,
        strict: strict,
      );
      if (status != 0) {
        if (strict && warnIndex.skippedFiles.isNotEmpty) {
          stderr.writeln(
            '--strict: ${warnIndex.skippedFiles.length} print_sizes.txt '
            'pulado(s)',
          );
        }
        if (telasCheckExitCode(
              existingMarkdown: markdown,
              files: files,
              sha7AddedAt: addedAt,
              repoUrl: repoUrl,
              assetsBranch: branch,
            ) !=
            0) {
          stderr.writeln(
            '$output está desatualizado. Rode: dart run tool/gen_telas.dart',
          );
        }
        return status;
      }
      return 0;
    }

    final markdown = buildTelasMarkdown(
      index: index,
      repoUrl: repoUrl,
      assetsBranch: branch,
    );

    final outFile = File(output.startsWith('/') ? output : '$root/$output');
    outFile.parent.createSync(recursive: true);
    outFile.writeAsStringSync(markdown, encoding: utf8);
    return 0;
  } on ProcessException catch (e) {
    if (isMissingGitRefError(e.message)) {
      stderr.writeln(missingGitRefMessage(ref));
      return 1;
    }
    stderr.writeln('git falhou: $e');
    return 1;
  } on FormatException catch (e) {
    if (e.message == 'missing value') return 2;
    stderr.writeln(e);
    return 2;
  }
}

const _usage = '''
Gera docs/qa/telas.md a partir dos print_sizes.txt na branch pr-assets.

  dart run tool/gen_telas.dart
  dart run tool/gen_telas.dart --ref origin/pr-assets --out /tmp/telas.md
  dart run tool/gen_telas.dart --check
  dart run tool/gen_telas.dart --strict

Opções:
  --ref <git-ref>     Ref git (default: origin/pr-assets)
  --output, -o, --out Arquivo de saída (default: docs/qa/telas.md)
  --branch <name>     Nome da branch nas URLs (default: pr-assets)
  --repo-url <url>    URL https do GitHub (default: origin)
  --check             Falha se telas.md divergir das pastas que já indexa.
                      Prints novos válidos em pr-assets não falham (pode
                      ficar atrás). Com --strict, um print_sizes.txt pulado
                      inteiro falha mesmo que a pasta nunca tenha entrado
                      no índice.
  --strict            Falha se algum print_sizes.txt for pulado inteiro
                      (gerar e --check)
  --help              Esta ajuda
''';

Map<String, int> _loadSha7AddedAt(String ref, String cwd) {
  try {
    final log = _git([
      'log',
      '--reverse',
      '--diff-filter=A',
      '--pretty=format:COMMIT %ct',
      '--name-only',
      ref,
      '--',
      'docs/pr-assets',
    ], cwd: cwd);
    return parseSha7AddedAt(log);
  } on ProcessException catch (e) {
    stderr.writeln('aviso: git log de datas do pr-assets falhou: $e');
    return {};
  }
}

String _git(List<String> args, {String? cwd}) {
  final result = Process.runSync(
    'git',
    args,
    workingDirectory: cwd,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  if (result.exitCode != 0) {
    throw ProcessException(
      'git',
      args,
      result.stderr.toString(),
      result.exitCode,
    );
  }
  return result.stdout as String;
}
