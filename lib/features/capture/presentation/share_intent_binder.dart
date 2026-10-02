import 'dart:async';

import 'package:go_router/go_router.dart';

import '../data/image_source_service.dart';
import '../domain/incoming_image.dart';

/// Listens for Android share-target images and `go`s to `/capture`.
///
/// Capture is **not** a tab (PRD §11). Share must open `/capture` with the
/// image extra, without requiring a Home hop (F2 / AC-share).
class ShareIntentBinder {
  ShareIntentBinder({required this.router, required this.source});

  final GoRouter router;
  final ImageSourceService source;

  StreamSubscription<IncomingImage>? _sub;
  bool _disposed = false;

  void start() {
    _sub = source.mediaStream.listen(_open);
    source.initialMedia().then((image) {
      if (_disposed || image == null) return;
      _open(image);
    });
  }

  void _open(IncomingImage image) {
    if (_disposed) return;
    router.go('/capture', extra: image);
  }

  void dispose() {
    _disposed = true;
    _sub?.cancel();
    _sub = null;
  }
}
