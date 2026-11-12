import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'page_image_store_stub.dart'
    if (dart.library.io) 'page_image_store_io.dart'
    as impl;

part 'page_image_store.g.dart';

@Riverpod(keepAlive: true)
PageImageStore pageImageStore(Ref ref) => const PageImageStore();

/// Copies the captured page image into app storage and returns the path.
///
/// Native: `{documents}/pages/{pageId}.png` via `path_provider`.
/// Web: always `null` (no overlay image).
class PageImageStore {
  const PageImageStore({this.documentsPath});

  /// Test override. Production uses `getApplicationDocumentsDirectory()`.
  final String? documentsPath;

  Future<String?> savePageImage({
    required String pageId,
    required Uint8List bytes,
  }) {
    return impl.savePageImage(
      pageId: pageId,
      bytes: bytes,
      documentsPath: documentsPath,
    );
  }
}
