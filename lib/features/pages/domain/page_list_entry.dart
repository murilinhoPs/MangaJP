import 'page_title.dart';

/// One row of the `/pages` history list.
///
/// Pages have no title or thumbnail bytes in Drift. [ocrPreview] is the
/// first crop's OCR when that exists; the tile draws it as the thumb.
class PageListEntry {
  const PageListEntry({
    required this.id,
    required this.createdAt,
    this.ocrPreview,
  });

  final String id;
  final DateTime createdAt;
  final String? ocrPreview;

  String get title => PageTitle.fromOcr(ocrPreview);
}
