/// Note merge and survivor choice for custom words that collide after
/// [stripVariationSelectors] (M1.28).
///
/// Survivor: most SRS progress — higher [CustomWordMergeCandidate.repetitions],
/// then later [CustomWordMergeCandidate.latestReview], then oldest
/// [CustomWordMergeCandidate.createdAt]. [CustomWordMergeCandidate.id] is the
/// last tie-break so the choice is stable.
///
/// Notes: distinct trimmed non-empty **whole** notes (not split on newlines),
/// survivor first, then the other rows in the order given, joined with a
/// newline. Identical notes appear once.
library;

class CustomWordMergeCandidate {
  const CustomWordMergeCandidate({
    required this.id,
    required this.createdAt,
    this.repetitions = 0,
    this.latestReview,
  });

  final String id;
  final DateTime createdAt;
  final int repetitions;
  final DateTime? latestReview;
}

String? mergeUserNotes(String? primary, Iterable<String?> others) {
  final parts = <String>[];
  final seen = <String>{};
  void add(String? raw) {
    final note = raw?.trim() ?? '';
    if (note.isEmpty) {
      return;
    }
    if (seen.add(note)) {
      parts.add(note);
    }
  }

  add(primary);
  for (final other in others) {
    add(other);
  }
  if (parts.isEmpty) {
    return null;
  }
  return parts.join('\n');
}

CustomWordMergeCandidate pickCustomWordSurvivor(
  Iterable<CustomWordMergeCandidate> rows,
) {
  final list = rows.toList();
  if (list.isEmpty) {
    throw ArgumentError.value(rows, 'rows', 'non-empty');
  }
  list.sort((a, b) {
    final byReps = b.repetitions.compareTo(a.repetitions);
    if (byReps != 0) {
      return byReps;
    }
    final aReview = a.latestReview;
    final bReview = b.latestReview;
    if (aReview != null && bReview != null) {
      final byReview = bReview.compareTo(aReview);
      if (byReview != 0) {
        return byReview;
      }
    } else if (aReview != null) {
      return -1;
    } else if (bReview != null) {
      return 1;
    }
    final byCreated = a.createdAt.compareTo(b.createdAt);
    if (byCreated != 0) {
      return byCreated;
    }
    return a.id.compareTo(b.id);
  });
  return list.first;
}
