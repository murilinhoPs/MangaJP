import 'dart:math' as math;

import '../../../core/deinflect/deinflector.dart';
import '../domain/dict_entry.dart';
import '../domain/lookup_result.dart';
import 'jmdict_service.dart';

/// Deinflect + local JMdict `forms` / `sense_pos` / `data_json` (M1.3).
///
/// Gloss text is always copied from JMdict `data_json`. Homographs are sorted
/// by `forms.priority` (highest first); that first entry is the default.
class DictionaryLookup {
  DictionaryLookup(this._jmdict, {this.deinflector = const Deinflector()});

  final JmdictService _jmdict;
  final Deinflector deinflector;

  /// Longest `forms` hit whose span covers [tapIndex] (UTF-16 offset).
  LookupResult? findAt(String text, {int tapIndex = 0}) {
    if (text.isEmpty) {
      return null;
    }
    final cover = tapIndex < 0
        ? 0
        : (tapIndex >= text.length ? text.length - 1 : tapIndex);
    final cache = <String, List<DictEntry>>{};

    LookupResult? best;
    var bestLen = -1;
    var bestStart = 1 << 30;

    for (var start = 0; start <= cover; start++) {
      final maxLen = math.min(text.length - start, 24);
      for (var len = maxLen; len >= 1; len--) {
        if (start + len <= cover) {
          break;
        }
        final surface = text.substring(start, start + len);
        final entries = cache.putIfAbsent(
          surface,
          () => _entriesForSurface(surface),
        );
        if (entries.isEmpty) {
          continue;
        }
        if (len > bestLen || (len == bestLen && start < bestStart)) {
          bestLen = len;
          bestStart = start;
          best = LookupResult(surface: surface, entries: entries);
        }
        break;
      }
    }
    return best;
  }

  List<DictEntry> _entriesForSurface(String surface) {
    final transformed = deinflector.transform(surface);
    final byText = <String, List<DeinflectedText>>{};
    for (final item in transformed) {
      byText.putIfAbsent(item.text, () => []).add(item);
    }

    final hits = _jmdict.formHits(byText.keys);
    if (hits.isEmpty) {
      return const [];
    }

    final posCache = <int, List<String>>{};
    final best = <int, FormHit>{};

    for (final hit in hits) {
      final candidates = byText[hit.text];
      if (candidates == null) {
        continue;
      }
      final pos = posCache.putIfAbsent(
        hit.seq,
        () => _jmdict.posForSeq(hit.seq),
      );
      final ok = candidates.any((item) => _posMatches(item.conditions, pos));
      if (!ok) {
        continue;
      }
      final prev = best[hit.seq];
      if (prev == null || _priorityBetter(hit.priority, prev.priority)) {
        best[hit.seq] = hit;
      }
    }

    final entries = [
      for (final hit in best.values)
        JmdictService.entryFromDataJson(
          seq: hit.seq,
          dataJson: hit.dataJson,
          priority: hit.priority,
        ),
    ];
    entries.sort(_byPriorityThenSeq);
    return entries;
  }

  bool _posMatches(int conditions, List<String> jmdictPos) {
    if (conditions == 0) {
      return true;
    }
    final ids = <String>[];
    for (final pos in jmdictPos) {
      final id = _yomitanCondition(pos);
      if (id != null) {
        ids.add(id);
      }
    }
    if (ids.isEmpty) {
      return false;
    }
    return (conditions & deinflector.flagsFor(ids)) != 0;
  }

  static int _byPriorityThenSeq(DictEntry a, DictEntry b) {
    final pa = a.priority ?? -1;
    final pb = b.priority ?? -1;
    final byPri = pb.compareTo(pa);
    if (byPri != 0) {
      return byPri;
    }
    return a.seq.compareTo(b.seq);
  }

  static bool _priorityBetter(int? next, int? current) {
    return (next ?? -1) > (current ?? -1);
  }
}

/// JMdict POS tag → Yomitan deinflect condition id.
String? _yomitanCondition(String pos) {
  if (pos == 'adj-i' || pos == 'adj-ix') {
    return 'adj-i';
  }
  if (pos.startsWith('v1')) {
    return 'v1';
  }
  if (pos.startsWith('v5')) {
    return 'v5';
  }
  if (pos == 'vk') {
    return 'vk';
  }
  if (pos.startsWith('vs')) {
    return 'vs';
  }
  if (pos == 'vz') {
    return 'vz';
  }
  return null;
}
