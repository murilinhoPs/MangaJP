import 'dart:typed_data';

/// Image handed to `/capture` (share intent, gallery pick, or test extra).
class IncomingImage {
  const IncomingImage({this.path, this.bytes})
    : assert(path != null || bytes != null);

  final String? path;
  final Uint8List? bytes;
}
