import 'dart:convert';

/// One KANJIDIC2 row from `jmdict.sqlite` table `kanji` (F24).
class KanjiEntry {
  const KanjiEntry({
    required this.character,
    required this.onReadings,
    required this.kunReadings,
    required this.meanings,
    this.strokeCount,
    this.freq,
  });

  final String character;
  final List<String> onReadings;
  final List<String> kunReadings;
  final List<String> meanings;
  final int? strokeCount;
  final int? freq;

  /// True when the bake filled at least one KANJIDIC2 field.
  bool get hasKanjidic =>
      onReadings.isNotEmpty ||
      kunReadings.isNotEmpty ||
      meanings.isNotEmpty ||
      strokeCount != null;

  factory KanjiEntry.fromRow({
    required String character,
    required String? readingsJson,
    required String? meaningsJson,
    required int? strokeCount,
    required int? freq,
  }) {
    var onReadings = const <String>[];
    var kunReadings = const <String>[];
    if (readingsJson != null && readingsJson.isNotEmpty) {
      final decoded = jsonDecode(readingsJson);
      if (decoded is Map) {
        onReadings = _strings(decoded['on']);
        kunReadings = _strings(decoded['kun']);
      }
    }
    var meanings = const <String>[];
    if (meaningsJson != null && meaningsJson.isNotEmpty) {
      meanings = _strings(jsonDecode(meaningsJson));
    }
    return KanjiEntry(
      character: character,
      onReadings: onReadings,
      kunReadings: kunReadings,
      meanings: meanings,
      strokeCount: strokeCount,
      freq: freq,
    );
  }

  /// Substring match on the literal, on/kun (dots optional), or meanings.
  bool matchesSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return true;
    }
    if (character.contains(trimmed)) {
      return true;
    }
    final q = trimmed.toLowerCase();
    final qNoDot = q.replaceAll('.', '');
    bool readingHits(String reading) {
      final lower = reading.toLowerCase();
      return lower.contains(q) || lower.replaceAll('.', '').contains(qNoDot);
    }

    return onReadings.any(readingHits) ||
        kunReadings.any(readingHits) ||
        meanings.any((meaning) => meaning.toLowerCase().contains(q));
  }

  static List<String> _strings(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    return [
      for (final item in raw)
        if (item is String && item.isNotEmpty) item,
    ];
  }
}
