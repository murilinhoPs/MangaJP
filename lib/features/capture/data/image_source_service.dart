import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/incoming_image.dart';

part 'image_source_service.g.dart';

@Riverpod(keepAlive: true)
ImageSourceService imageSourceService(Ref ref) => ImageSourceService();

/// Share intent + gallery pick (camera is Could / F28, not M0.8).
///
/// Native share is Android + iOS. `flutter test` on desktop never touches the
/// plugin (`defaultTargetPlatform` is not Android/iOS on the CI host). Web
/// has no share target either (`kIsWeb`).
class ImageSourceService {
  ImageSourceService();

  bool get _nativeShare {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Cold-start share (app launched as the SEND / Share Extension target).
  Future<IncomingImage?> initialMedia() async {
    if (!_nativeShare) return null;
    try {
      final image = _firstImage(
        await ReceiveSharingIntent.instance.getInitialMedia(),
      );
      if (image != null) {
        await ReceiveSharingIntent.instance.reset();
      }
      return image;
    } catch (error, stack) {
      debugPrint('ImageSourceService.initialMedia: $error\n$stack');
      return null;
    }
  }

  /// Warm share while the host app is already running.
  Stream<IncomingImage> get mediaStream {
    if (!_nativeShare) return const Stream.empty();
    return ReceiveSharingIntent.instance
        .getMediaStream()
        .map(_firstImage)
        .where((e) => e != null)
        .cast<IncomingImage>();
  }

  Future<IncomingImage?> pickFromGallery() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    return IncomingImage(bytes: await file.readAsBytes());
  }

  IncomingImage? _firstImage(List<SharedMediaFile> files) {
    for (final file in files) {
      final mime = file.mimeType ?? '';
      if (file.type == SharedMediaType.image || mime.startsWith('image/')) {
        return IncomingImage(path: file.path);
      }
    }
    return null;
  }
}
