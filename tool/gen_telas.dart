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
        output = next();
      case '--branch':
        branch = next();
      case '--repo-url':
        repoUrl = next();
      case '--check':
        check = true;
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
    final names =
        _git(['ls-tree', '-r', '--name-only', ref], cwd: root)
            .split('\n')
            .where((p) => p.isNotEmpty && isPrintSizesPath(p))
            .toList()
          ..sort();

    final files = <({String path, String content})>[];
    for (final path in names) {
      files.add((path: path, content: _git(['show', '$ref:$path'], cwd: root)));
    }

    final index = buildTelasIndex(files);
    final markdown = buildTelasMarkdown(
      index: index,
      repoUrl: repoUrl,
      assetsBranch: branch,
    );

    final variantIds = (index.variants.map((v) => v.id).toList()..sort()).join(
      ', ',
    );
    stderr.writeln(
      'telas: ${index.prints.length} print(s), ${index.filesParsed} arquivo(s), '
      'formatos: ${variantIds.isEmpty ? '(nenhum)' : variantIds}',
    );

    if (check) {
      final file = File('$root/$output');
      if (!file.existsSync()) {
        stderr.writeln(
          '$output não existe. Rode: dart run tool/gen_telas.dart',
        );
        return 1;
      }
      final existing = file.readAsBytesSync();
      final generated = utf8.encode(markdown);
      if (!_bytesEqual(existing, generated)) {
        stderr.writeln(
          '$output está desatualizado. Rode: dart run tool/gen_telas.dart',
        );
        return 1;
      }
      return 0;
    }

    final outFile = File(output.startsWith('/') ? output : '$root/$output');
    outFile.parent.createSync(recursive: true);
    outFile.writeAsStringSync(markdown, encoding: utf8);
    return 0;
  } on ProcessException catch (e) {
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
  dart run tool/gen_telas.dart --ref origin/pr-assets --check

Opções:
  --ref <git-ref>     Ref git (default: origin/pr-assets)
  --output, -o <path> Arquivo de saída (default: docs/qa/telas.md)
  --branch <name>     Nome da branch nas URLs (default: pr-assets)
  --repo-url <url>    URL https do GitHub (default: origin)
  --check             Falha se o arquivo gerado divergir
  --help              Esta ajuda
''';

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

bool _bytesEqual(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
