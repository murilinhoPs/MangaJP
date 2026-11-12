class MangaPage {
  const MangaPage({
    required this.id,
    required this.sha256,
    required this.createdAt,
    this.imagePath,
  });

  final String id;
  final String sha256;
  final DateTime createdAt;

  /// Absolute path of the copied page image. Null on pre-schema-10 pages.
  final String? imagePath;
}
