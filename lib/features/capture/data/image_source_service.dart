import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/capture_labels.dart';
import '../domain/capture_shot.dart';
import '../domain/incoming_image.dart';
import '../domain/share_access.dart';
import 'share_supported.dart';

part 'image_source_service.g.dart';

@Riverpod(keepAlive: true)
ImageSourceService imageSourceService(Ref ref) => ImageSourceService();

/// Share intent + gallery pick (camera is Could / F28, not M0.8).
///
/// Native share is Android + iOS. `flutter test` on desktop never touches the
/// plugin (`Platform.isAndroid` / `Platform.isIOS` are false on the CI host).
/// Web has no share target (`nativeShareSupported` is false).
/// Home **Galeria** and `/capture` empty-state both call [pickFromGallery].
class ImageSourceService {
  ImageSourceService({
    bool? nativeShare,
    Future<Uint8List> Function(String path)? readPath,
    this.initialShared,
    this.sharedStream,
  }) : _nativeShareOverride = nativeShare,
       _readPath = readPath ?? _defaultReadPath;

  final bool? _nativeShareOverride;
  final Future<Uint8List> Function(String path) _readPath;

  /// Test seams for share-intent fakes. Production leaves these null.
  final Future<List<SharedMediaFile>> Function()? initialShared;
  final Stream<List<SharedMediaFile>>? sharedStream;

  bool get _nativeShare => _nativeShareOverride ?? nativeShareSupported;

  /// Cold-start share (app launched as the SEND / Share Extension target).
  Future<IncomingImage?> initialMedia() async {
    final shot = captureShotImage();
    if (shot != null) {
      return IncomingImage(bytes: shot);
    }
    if (kCaptureShotShareDenied) {
      return const IncomingImage(
        errorMessage: CaptureLabels.sharePermissionDenied,
      );
    }
    if (!_nativeShare) return null;
    try {
      final files =
          await (initialShared?.call() ??
              ReceiveSharingIntent.instance.getInitialMedia());
      final image = await _firstImage(files);
      if (image != null && image.errorMessage == null) {
        await ReceiveSharingIntent.instance.reset();
      }
      return image;
    } catch (error, stack) {
      if (isSharePermissionError(error)) {
        return const IncomingImage(
          errorMessage: CaptureLabels.sharePermissionDenied,
        );
      }
      debugPrint('ImageSourceService.initialMedia: $error\n$stack');
      return null;
    }
  }

  /// Warm share while the host app is already running.
  Stream<IncomingImage> get mediaStream {
    if (!_nativeShare) return const Stream.empty();
    final source =
        sharedStream ?? ReceiveSharingIntent.instance.getMediaStream();
    return source.asyncExpand((files) async* {
      try {
        final image = await _firstImage(files);
        if (image != null) {
          yield image;
        }
      } catch (error, stack) {
        if (isSharePermissionError(error)) {
          yield const IncomingImage(
            errorMessage: CaptureLabels.sharePermissionDenied,
          );
        } else {
          debugPrint('ImageSourceService.mediaStream: $error\n$stack');
        }
      }
    });
  }

  /// System gallery. Cancel (or a picker error) returns `null` — a no-op.
  ///
  /// On macOS, `image_picker` delegates to `image_picker_macos` →
  /// `file_selector_macos` (`NSOpenPanel`). The App Sandbox needs
  /// `com.apple.security.files.user-selected.read-only` or the panel never
  /// appears. Android / iOS keep using the Photos picker.
  Future<IncomingImage?> pickFromGallery() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return null;
      return IncomingImage(bytes: await file.readAsBytes());
    } catch (error, stack) {
      debugPrint('ImageSourceService.pickFromGallery: $error\n$stack');
      return null;
    }
  }

  Future<IncomingImage?> _firstImage(List<SharedMediaFile> files) async {
    for (final file in files) {
      final mime = file.mimeType ?? '';
      if (file.type == SharedMediaType.image || mime.startsWith('image/')) {
        return _fromSharedPath(file.path);
      }
    }
    return null;
  }

  Future<IncomingImage> _fromSharedPath(String path) async {
    try {
      final bytes = await _readPath(path);
      return IncomingImage(bytes: bytes);
    } catch (error) {
      if (isSharePermissionError(error)) {
        return const IncomingImage(
          errorMessage: CaptureLabels.sharePermissionDenied,
        );
      }
      rethrow;
    }
  }
}

Future<Uint8List> _defaultReadPath(String path) {
  return XFile(path).readAsBytes();
}
