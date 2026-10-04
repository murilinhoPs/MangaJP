class MangaPage {
  const MangaPage({
    required this.id,
    required this.sha256,
    required this.createdAt,
  });

  final String id;
  final String sha256;
  final DateTime createdAt;
}
