/// Parser for `print_sizes.txt` files that exist on `pr-assets`.
///
/// Real variants found on `origin/pr-assets` (see tests/fixtures):
/// - v0: `file.png  WxH  N bytes` (no head, platform in the filename)
/// - v1: `head_sha` / `head_sha7` + `platform/file.png WxH N bytes`
/// - v1b: v1 plus a following `  sha256 <hex>` line
/// - v2: `head: <SHA-1>` + `platform/file.png WxH sha256:<hex>`
///   (optional `coral=` / `bg=` tokens before sha256)
library;

/// Format families that actually appear on `pr-assets`.
enum PrintSizesVariant {
  /// `name.png  1280x800  42585 bytes` — pr-41 / pr-42 (`m125_print_sizes.txt`).
  v0FilenameWxHBytes('v0-filename-wxh-bytes'),

  /// `head_sha` + `platform/file.png WxH N bytes` — pr-46/038d401, pr-46/bd489f7.
  v1HeadShaWxHBytes('v1-head_sha-wxh-bytes'),

  /// v1 plus indented `sha256 <hex>` continuation — pr-46/b32d250, pr-48, pr-49.
  v1HeadShaSha256Continued('v1-head_sha-sha256-continued'),

  /// Canonical print-rules: `head:` + inline `sha256:` — pr-50.
  v2HeadColonInlineSha256('v2-head-colon-inline-sha256');

  const PrintSizesVariant(this.id);
  final String id;
}

class PrintSizesParse {
  const PrintSizesParse({
    required this.entries,
    required this.skipped,
    required this.variants,
    this.headSha,
    this.headSha7,
  });

  final List<PrintSizesEntry> entries;
  final List<SkippedLine> skipped;
  final Set<PrintSizesVariant> variants;
  final String? headSha;
  final String? headSha7;
}

class SkippedLine {
  const SkippedLine({
    required this.lineNumber,
    required this.line,
    required this.reason,
    this.sourcePath,
  });

  final int lineNumber;
  final String line;
  final String reason;
  final String? sourcePath;

  SkippedLine withSource(String path) => SkippedLine(
    lineNumber: lineNumber,
    line: line,
    reason: reason,
    sourcePath: path,
  );
}

class FileSkip {
  const FileSkip({required this.path, required this.reason});

  final String path;
  final String reason;
}

class PrintSizesEntry {
  const PrintSizesEntry({
    required this.relativePath,
    required this.width,
    required this.height,
    this.byteSize,
    this.sha256,
    this.sha256Valid = true,
    this.coral,
    this.bg,
    this.declaredCrop = false,
  });

  /// Path as written in the file (`macos/crop.png` or `m125_phone_home.png`).
  final String relativePath;
  final int width;
  final int height;
  final int? byteSize;
  final String? sha256;
  final bool sha256Valid;
  final int? coral;
  final int? bg;

  /// PR-declared crop for sensitive data (`recorte` / `recorte=` on the line).
  /// Off-size prints with this flag are allowed by print-rules.
  final bool declaredCrop;

  String get fileName {
    final i = relativePath.lastIndexOf('/');
    return i < 0 ? relativePath : relativePath.substring(i + 1);
  }

  String? get platformDir {
    final i = relativePath.indexOf('/');
    if (i <= 0) return null;
    return relativePath.substring(0, i);
  }
}

final _headColon = RegExp(r'^head:\s*([0-9a-fA-F]+)\s*$');
final _headSha = RegExp(r'^head_sha\s+([0-9a-fA-F]+)\s*$');
final _headSha7 = RegExp(r'^head_sha7\s+([0-9a-fA-F]+)\s*$');
final _printLine = RegExp(
  r'^((?:[A-Za-z0-9._-]+/)*[A-Za-z0-9._-]+\.png)\s+(\d+)x(\d+)(?:\s+(\d+)\s+bytes)?(?:\s+(.+?))?\s*$',
);
final _sha256Continued = RegExp(r'^\s+sha256[:\s]+([0-9a-fA-F]+)\s*$');
final _sha256Inline = RegExp(r'sha256:([0-9a-fA-F]+)');
final _coral = RegExp(r'coral=(\d+)');
final _bg = RegExp(r'bg=(\d+)');

/// `recorte` or `recorte=<reason>` on the print line (print-rules edição).
bool hasDeclaredCropToken(String? rest) {
  if (rest == null || rest.isEmpty) return false;
  return rest
      .split(RegExp(r'\s+'))
      .any((t) => t == 'recorte' || t.startsWith('recorte='));
}

final _hex40 = RegExp(r'^[0-9a-fA-F]{40}$');
final _hex7 = RegExp(r'^[0-9a-fA-F]{7,40}$');

/// Notes / device legends that are not print rows.
bool _isLegend(String line) {
  final t = line.trim();
  if (t.isEmpty) return true;
  if (t.startsWith('Pixel checks')) return true;
  if (t.startsWith('- ')) return true;
  if (t.startsWith('iOS ')) return true;
  if (t.startsWith('Android ')) return true;
  if (t.startsWith('Desktop ')) return true;
  if (t.startsWith('crop.png files ')) return true;
  return false;
}

PrintSizesParse parsePrintSizes(String content) {
  final entries = <PrintSizesEntry>[];
  final skipped = <SkippedLine>[];
  final variants = <PrintSizesVariant>{};
  String? headSha;
  String? headSha7;
  var sawHeadColon = false;
  var sawHeadSha = false;
  var sawInlineSha256 = false;
  var sawContinuedSha256 = false;
  var sawBytes = false;

  PrintSizesEntry? pending;

  void flushPending() {
    final p = pending;
    if (p != null) entries.add(p);
    pending = null;
  }

  final lines = content.split('\n');
  for (var i = 0; i < lines.length; i++) {
    var raw = lines[i];
    if (raw.endsWith('\r')) raw = raw.substring(0, raw.length - 1);
    final lineNo = i + 1;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      flushPending();
      continue;
    }

    final headColon = _headColon.firstMatch(trimmed);
    if (headColon != null) {
      flushPending();
      sawHeadColon = true;
      final sha = headColon.group(1)!;
      if (!_hex40.hasMatch(sha)) {
        skipped.add(
          SkippedLine(
            lineNumber: lineNo,
            line: raw,
            reason: 'head: SHA-1 não tem 40 hex',
          ),
        );
        continue;
      }
      headSha = sha.toLowerCase();
      headSha7 ??= headSha.substring(0, 7);
      continue;
    }

    final headShaMatch = _headSha.firstMatch(trimmed);
    if (headShaMatch != null) {
      flushPending();
      sawHeadSha = true;
      final sha = headShaMatch.group(1)!;
      if (!_hex40.hasMatch(sha)) {
        skipped.add(
          SkippedLine(
            lineNumber: lineNo,
            line: raw,
            reason: 'head_sha não tem 40 hex',
          ),
        );
        continue;
      }
      headSha = sha.toLowerCase();
      continue;
    }

    final headSha7Match = _headSha7.firstMatch(trimmed);
    if (headSha7Match != null) {
      flushPending();
      sawHeadSha = true;
      final sha = headSha7Match.group(1)!;
      if (!_hex7.hasMatch(sha)) {
        skipped.add(
          SkippedLine(
            lineNumber: lineNo,
            line: raw,
            reason: 'head_sha7 inválido',
          ),
        );
        continue;
      }
      headSha7 = sha.toLowerCase();
      continue;
    }

    final cont = _sha256Continued.firstMatch(raw);
    if (cont != null) {
      final hex = cont.group(1)!.toLowerCase();
      final ok = hex.length == 64;
      if (pending == null) {
        skipped.add(
          SkippedLine(
            lineNumber: lineNo,
            line: raw,
            reason: 'sha256 continuado sem linha de print',
          ),
        );
        continue;
      }
      sawContinuedSha256 = true;
      pending = PrintSizesEntry(
        relativePath: pending!.relativePath,
        width: pending!.width,
        height: pending!.height,
        byteSize: pending!.byteSize,
        sha256: hex,
        sha256Valid: ok,
        coral: pending!.coral,
        bg: pending!.bg,
        declaredCrop: pending!.declaredCrop,
      );
      if (!ok) {
        skipped.add(
          SkippedLine(
            lineNumber: lineNo,
            line: raw,
            reason: 'sha256 tem ${hex.length} hex (esperado 64)',
          ),
        );
      }
      flushPending();
      continue;
    }

    final printMatch = _printLine.firstMatch(trimmed);
    if (printMatch != null) {
      flushPending();
      final rest = printMatch.group(5);
      final shaInline = rest == null ? null : _sha256Inline.firstMatch(rest);
      final coral = rest == null ? null : _coral.firstMatch(rest);
      final bg = rest == null ? null : _bg.firstMatch(rest);
      final bytesRaw = printMatch.group(4);
      if (bytesRaw != null) sawBytes = true;
      if (shaInline != null) sawInlineSha256 = true;
      final shaHex = shaInline?.group(1)?.toLowerCase();
      final shaOk = shaHex == null || shaHex.length == 64;
      if (shaHex != null && !shaOk) {
        skipped.add(
          SkippedLine(
            lineNumber: lineNo,
            line: raw,
            reason: 'sha256 tem ${shaHex.length} hex (esperado 64)',
          ),
        );
      }
      pending = PrintSizesEntry(
        relativePath: printMatch.group(1)!,
        width: int.parse(printMatch.group(2)!),
        height: int.parse(printMatch.group(3)!),
        byteSize: bytesRaw == null ? null : int.parse(bytesRaw),
        sha256: shaHex,
        sha256Valid: shaOk,
        coral: coral == null ? null : int.parse(coral.group(1)!),
        bg: bg == null ? null : int.parse(bg.group(1)!),
        declaredCrop: hasDeclaredCropToken(rest),
      );
      continue;
    }

    flushPending();
    if (_isLegend(raw)) continue;
    skipped.add(
      SkippedLine(
        lineNumber: lineNo,
        line: raw,
        reason: 'linha não reconhecida',
      ),
    );
  }
  flushPending();

  if (sawHeadColon && sawInlineSha256) {
    variants.add(PrintSizesVariant.v2HeadColonInlineSha256);
  }
  if (sawHeadSha && sawContinuedSha256) {
    variants.add(PrintSizesVariant.v1HeadShaSha256Continued);
  }
  if (sawHeadSha && sawBytes && !sawContinuedSha256 && !sawInlineSha256) {
    variants.add(PrintSizesVariant.v1HeadShaWxHBytes);
  }
  if (!sawHeadColon && !sawHeadSha && sawBytes) {
    variants.add(PrintSizesVariant.v0FilenameWxHBytes);
  }

  return PrintSizesParse(
    entries: List.unmodifiable(entries),
    skipped: List.unmodifiable(skipped),
    variants: variants,
    headSha: headSha,
    headSha7: headSha7,
  );
}
