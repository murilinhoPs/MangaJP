import 'dart:typed_data';

/// Image handed to `/capture` (share intent, gallery pick, or test extra).
class IncomingImage {
  const IncomingImage({this.path, this.bytes, this.errorMessage})
    : assert(path != null || bytes != null || errorMessage != null);

  final String? path;
  final Uint8List? bytes;

  /// Already-resolved PT-BR error (share without URI permission).
  final String? errorMessage;
}
