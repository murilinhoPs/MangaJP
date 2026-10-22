import 'print_sizes.dart';

final _printSizesPath = RegExp(
  r'^docs/pr-assets/pr-(\d+)/([0-9a-fA-F]{7})/(?:.+/)*[^/]*print_sizes\.txt$',
);

enum TelasPlatform {
  android,
  linuxDesktop,
  macos,
  ios,
  unknown;

  String get heading => switch (this) {
    TelasPlatform.android => 'Android',
    TelasPlatform.linuxDesktop => 'Linux desktop',
    TelasPlatform.macos => 'macOS',
    TelasPlatform.ios => 'iOS',
    TelasPlatform.unknown => 'Desconhecido',
  };

  static const List<TelasPlatform> displayOrder = [
    TelasPlatform.android,
    TelasPlatform.linuxDesktop,
    TelasPlatform.macos,
    TelasPlatform.ios,
    TelasPlatform.unknown,
  ];
}

class IndexedPrint {
  const IndexedPrint({
    required this.prNumber,
    required this.sha7,
    required this.blobPath,
    required this.relativePath,
    required this.platform,
    required this.feature,
    required this.screen,
    required this.width,
    required this.height,
    required this.violatesPrintRules,
    this.headSha,
    this.sha256,
    this.sha256Valid = true,
  });

  final int prNumber;
  final String sha7;
  final String? headSha;
  final String blobPath;
  final String relativePath;
  final TelasPlatform platform;
  final String feature;
  final String screen;
  final int width;
  final int height;
  final bool violatesPrintRules;
  final String? sha256;
  final bool sha256Valid;

  String get dimensionsLabel {
    final size = '$width×$height';
    if (violatesPrintRules) return '$size **fora da regra**';
    return size;
  }
}

class PrintSizesLocation {
  const PrintSizesLocation({
    required this.path,
    required this.prNumber,
    required this.sha7,
    required this.directory,
  });

  final String path;
  final int prNumber;
  final String sha7;
  final String directory;
}

PrintSizesLocation? parsePrintSizesLocation(String path) {
  final m = _printSizesPath.firstMatch(path);
  if (m == null) return null;
  final slash = path.lastIndexOf('/');
  return PrintSizesLocation(
    path: path,
    prNumber: int.parse(m.group(1)!),
    sha7: m.group(2)!.toLowerCase(),
    directory: slash < 0 ? '' : path.substring(0, slash),
  );
}

bool isPrintSizesPath(String path) => _printSizesPath.hasMatch(path);

TelasPlatform platformFrom(PrintSizesEntry entry, PrintSizesLocation loc) {
  final dir = entry.platformDir?.toLowerCase();
  final fromDir = _platformFromToken(dir);
  if (fromDir != TelasPlatform.unknown) return fromDir;

  // Nested print_sizes.txt under a platform folder (e.g. .../macos/print_sizes.txt).
  final parts = loc.directory.split('/');
  if (parts.isNotEmpty) {
    final nested = _platformFromToken(parts.last.toLowerCase());
    if (nested != TelasPlatform.unknown) return nested;
  }

  return platformFromFileName(entry.fileName);
}

TelasPlatform platformFromFileName(String fileName) {
  final n = fileName.toLowerCase();
  if (n.contains('_phone_') ||
      n.startsWith('phone_') ||
      n.contains('_mobile_') ||
      n.startsWith('mobile_')) {
    return TelasPlatform.android;
  }
  if (n.contains('_desktop_') || n.startsWith('desktop_')) {
    return TelasPlatform.linuxDesktop;
  }
  if (n.contains('_macos_') || n.startsWith('macos_')) {
    return TelasPlatform.macos;
  }
  if (n.contains('_ios_') || n.startsWith('ios_')) {
    return TelasPlatform.ios;
  }
  if (n.contains('_linux_') || n.startsWith('linux_')) {
    return TelasPlatform.linuxDesktop;
  }
  if (n.contains('_android_') || n.startsWith('android_')) {
    return TelasPlatform.android;
  }
  return TelasPlatform.unknown;
}

TelasPlatform _platformFromToken(String? token) {
  return switch (token) {
    'android' => TelasPlatform.android,
    'ios' => TelasPlatform.ios,
    'macos' => TelasPlatform.macos,
    'desktop' || 'linux' => TelasPlatform.linuxDesktop,
    _ => TelasPlatform.unknown,
  };
}

final _milestonePrefix = RegExp(r'^m\d+[a-z]*_');
final _platformPrefix = RegExp(
  r'^(phone|desktop|mobile|android|ios|macos|linux)_',
);

/// Stem used to group a tela (e.g. `caderno_list`, `home`).
String screenStem(String fileName) {
  var n = fileName.toLowerCase();
  if (n.endsWith('.png')) n = n.substring(0, n.length - 4);
  while (_milestonePrefix.hasMatch(n)) {
    n = n.replaceFirst(_milestonePrefix, '');
  }
  while (_platformPrefix.hasMatch(n)) {
    n = n.replaceFirst(_platformPrefix, '');
  }
  return n;
}

const _featureOrder = <String>[
  'Home',
  'Galeria',
  'Captura',
  'Recorte',
  'Leitor',
  'Dicionário',
  'Caderno',
  'Flashcards',
  'Revisão',
  'Ajustes',
];

String featureForStem(String stem) {
  if (stem == 'home' || stem.startsWith('home_')) {
    if (stem == 'home_cancel' || stem == 'home_galeria') return 'Galeria';
    return 'Home';
  }
  if (stem == 'nsopenpanel' || stem.startsWith('galeria')) return 'Galeria';
  if (stem == 'captura' || stem.startsWith('captura_')) return 'Captura';
  if (stem == 'crop' || stem.startsWith('crop_')) return 'Recorte';
  if (stem == 'page' ||
      stem.startsWith('page_') ||
      stem == 'pagina' ||
      stem.startsWith('pagina_') ||
      stem == 'swipe' ||
      stem.startsWith('swipe_')) {
    return 'Leitor';
  }
  if (stem.startsWith('lookup')) return 'Dicionário';
  if (stem == 'word' ||
      stem.startsWith('word_') ||
      stem.startsWith('caderno')) {
    return 'Caderno';
  }
  if (stem.startsWith('review') || stem == 'review') return 'Revisão';
  if (stem == 'deck' ||
      stem.startsWith('deck_') ||
      stem.startsWith('flashcard')) {
    return 'Flashcards';
  }
  if (stem == 'ajustes' || stem.startsWith('settings')) return 'Ajustes';
  return _titleCase(stem);
}

String _titleCase(String stem) {
  return stem
      .split('_')
      .where((p) => p.isNotEmpty)
      .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
      .join(' ');
}

/// Android 390×844 or integer DPR multiple; desktop/macOS 1280×800.
/// iOS resolution is pending in print-rules — never flagged.
bool violatesPrintRules(TelasPlatform platform, int width, int height) {
  switch (platform) {
    case TelasPlatform.android:
      return !androidDimensionsOk(width, height);
    case TelasPlatform.linuxDesktop:
    case TelasPlatform.macos:
      return width != 1280 || height != 800;
    case TelasPlatform.ios:
    case TelasPlatform.unknown:
      return false;
  }
}

bool androidDimensionsOk(int width, int height) {
  if (width <= 0 || height <= 0) return false;
  if (width % 390 != 0 || height % 844 != 0) return false;
  final n = width ~/ 390;
  return n >= 1 && height == 844 * n;
}

String posixJoin(String dir, String rel) {
  if (rel.startsWith('/')) return rel.substring(1);
  if (dir.isEmpty) return rel;
  if (dir.endsWith('/')) return '$dir$rel';
  return '$dir/$rel';
}

String stripGitRemote(String remote) {
  var s = remote.trim();
  if (s.endsWith('.git')) s = s.substring(0, s.length - 4);
  s = s.replaceFirst(RegExp(r'^https://[^/@]+@'), 'https://');
  final ssh = RegExp(r'^git@github\.com:([^/]+)/(.+)$').firstMatch(s);
  if (ssh != null) return 'https://github.com/${ssh.group(1)}/${ssh.group(2)}';
  final https = RegExp(r'^(https://github\.com/[^/]+/[^/]+)$').firstMatch(s);
  if (https != null) return https.group(1)!;
  final httpToken = RegExp(r'^https://github\.com/([^/]+)/(.+)$').firstMatch(s);
  if (httpToken != null) {
    return 'https://github.com/${httpToken.group(1)}/${httpToken.group(2)}';
  }
  return 'https://github.com/murilinhoPs/MangaJP';
}

class TelasIndex {
  const TelasIndex({
    required this.prints,
    required this.variants,
    required this.filesParsed,
    required this.skipped,
  });

  final List<IndexedPrint> prints;
  final Set<PrintSizesVariant> variants;
  final int filesParsed;
  final List<SkippedLine> skipped;
}

TelasIndex buildTelasIndex(List<({String path, String content})> files) {
  final prints = <IndexedPrint>[];
  final variants = <PrintSizesVariant>{};
  final skipped = <SkippedLine>[];
  var filesParsed = 0;

  for (final file in files) {
    final loc = parsePrintSizesLocation(file.path);
    if (loc == null) continue;
    filesParsed++;
    final parsed = parsePrintSizes(file.content);
    variants.addAll(parsed.variants);
    skipped.addAll(parsed.skipped);
    for (final entry in parsed.entries) {
      final platform = platformFrom(entry, loc);
      final stem = screenStem(entry.fileName);
      prints.add(
        IndexedPrint(
          prNumber: loc.prNumber,
          sha7: loc.sha7,
          headSha: parsed.headSha,
          blobPath: posixJoin(loc.directory, entry.relativePath),
          relativePath: entry.relativePath,
          platform: platform,
          feature: featureForStem(stem),
          screen: stem,
          width: entry.width,
          height: entry.height,
          violatesPrintRules: violatesPrintRules(
            platform,
            entry.width,
            entry.height,
          ),
          sha256: entry.sha256,
          sha256Valid: entry.sha256Valid,
        ),
      );
    }
  }

  prints.sort(_comparePrints);
  return TelasIndex(
    prints: List.unmodifiable(prints),
    variants: variants,
    filesParsed: filesParsed,
    skipped: List.unmodifiable(skipped),
  );
}

int _comparePrints(IndexedPrint a, IndexedPrint b) {
  final feat = _featureRank(a.feature).compareTo(_featureRank(b.feature));
  if (feat != 0) return feat;
  final featName = a.feature.compareTo(b.feature);
  if (featName != 0) return featName;
  final plat = a.platform.index.compareTo(b.platform.index);
  if (plat != 0) return plat;
  final screen = a.screen.compareTo(b.screen);
  if (screen != 0) return screen;
  final pr = b.prNumber.compareTo(a.prNumber);
  if (pr != 0) return pr;
  final sha = b.sha7.compareTo(a.sha7);
  if (sha != 0) return sha;
  return a.relativePath.compareTo(b.relativePath);
}

int _featureRank(String feature) {
  final i = _featureOrder.indexOf(feature);
  return i < 0 ? _featureOrder.length : i;
}

String buildTelasMarkdown({
  required TelasIndex index,
  required String repoUrl,
  String assetsBranch = 'pr-assets',
}) {
  final repo = repoUrl.endsWith('/')
      ? repoUrl.substring(0, repoUrl.length - 1)
      : repoUrl;
  final variantIds = (index.variants.map((v) => v.id).toList()..sort()).join(
    ', ',
  );

  final buf = StringBuffer();
  buf.writeln('<!-- Generated by tool/gen_telas.dart. Do not edit. -->');
  buf.writeln(
    '<!-- formatos: ${variantIds.isEmpty ? '(nenhum)' : variantIds} -->',
  );
  buf.writeln('# Índice de telas (QA)');
  buf.writeln();
  buf.writeln(
    'Este arquivo é **gerado** a partir dos `print_sizes.txt` na branch '
    '[`$assetsBranch`]($repo/tree/$assetsBranch/docs/pr-assets). '
    'Não edite à mão.',
  );
  buf.writeln();
  buf.writeln('Para regenerar (lê `pr-assets` via git, sem fazer checkout):');
  buf.writeln();
  buf.writeln('```bash');
  buf.writeln('dart run tool/gen_telas.dart');
  buf.writeln('```');
  buf.writeln();
  buf.writeln(
    'Dimensões obrigatórias: ver [`print-rules.md`](print-rules.md). '
    'Android 390×844 ou múltiplo inteiro de DPR; desktop/macOS 1280×800. '
    'Prints fora da regra são marcados com **fora da regra**. '
    'iOS: retrato, resolução pendente — não marcado.',
  );
  buf.writeln();
  buf.writeln(
    'Último print de cada tela primeiro (PR mais alto, depois sha7). '
    '${index.prints.length} print(s) em ${index.filesParsed} arquivo(s).',
  );
  buf.writeln();

  String? currentFeature;
  TelasPlatform? currentPlatform;
  var wroteRow = false;

  for (final p in index.prints) {
    if (p.feature != currentFeature) {
      if (wroteRow) buf.writeln();
      currentFeature = p.feature;
      currentPlatform = null;
      buf.writeln('## $currentFeature');
      buf.writeln();
    }
    if (p.platform != currentPlatform) {
      if (currentPlatform != null) buf.writeln();
      currentPlatform = p.platform;
      buf.writeln('### ${currentPlatform.heading}');
      buf.writeln();
      buf.writeln('| PR | sha7 | arquivo | dimensões | imagem |');
      buf.writeln('| --- | --- | --- | --- | --- |');
    }
    final pr = '[#${p.prNumber}]($repo/pull/${p.prNumber})';
    final blob = '$repo/blob/$assetsBranch/${p.blobPath}';
    final raw = '$repo/raw/$assetsBranch/${p.blobPath}';
    buf.writeln(
      '| $pr | `${p.sha7}` | `${p.relativePath}` | ${p.dimensionsLabel} | [blob]($blob) · [raw]($raw) |',
    );
    wroteRow = true;
  }

  if (index.prints.isEmpty) {
    buf.writeln('_Nenhum `print_sizes.txt` encontrado no ref._');
    buf.writeln();
  } else {
    buf.writeln();
  }

  return buf.toString();
}
