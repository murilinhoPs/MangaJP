class DictEntry {
  const DictEntry({
    required this.seq,
    required this.surface,
    this.reading,
  });

  final int seq;
  final String surface;
  final String? reading;
}
