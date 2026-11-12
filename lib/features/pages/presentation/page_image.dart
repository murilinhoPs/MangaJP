import 'package:flutter/widgets.dart';

import 'page_image_stub.dart' if (dart.library.io) 'page_image_io.dart' as impl;

/// When true, [PageImageView] paints a solid surface instead of `Image.file`
/// (`FileImage` never settles under `AutomatedTestWidgetsFlutterBinding`).
@visibleForTesting
bool debugPageImageUsePlaceholder = false;

/// True when [path] points at a readable file (native). Always false on web.
bool pageImageFileExists(String? path) => impl.pageImageFileExists(path);

/// Pixel size of the file, or null if missing / unreadable / web.
Size? pageImagePixelSize(String? path) {
  if (debugPageImageUsePlaceholder) {
    if (path == null || path.isEmpty) {
      return null;
    }
    return const Size(200, 300);
  }
  return impl.pageImagePixelSize(path);
}

/// Page PNG from [path], contained. Empty on web / missing file.
class PageImageView extends StatelessWidget {
  const PageImageView({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    if (debugPageImageUsePlaceholder) {
      return const ColoredBox(color: Color(0xFF18171E));
    }
    return impl.buildPageImage(path);
  }
}
