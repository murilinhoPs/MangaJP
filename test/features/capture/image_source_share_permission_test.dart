import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/features/capture/data/image_source_service.dart';
import 'package:manga_jp/features/capture/domain/capture_labels.dart';
import 'package:manga_jp/features/capture/domain/share_access.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() {
  const contentUri = 'content://media/external/images/media/42';

  test('SharedMediaFile.fromMap keeps uri_permission_denied', () {
    final file = SharedMediaFile.fromMap({
      'path': contentUri,
      'type': 'image',
      'mimeType': 'image/jpeg',
      'error': kShareUriPermissionDenied,
    });
    expect(file.error, kShareUriPermissionDenied);
    expect(isShareUriPermissionDeniedCode(file.error), isTrue);
  });

  test(
    'content:// without URI permission returns PT-BR error, does not throw',
    () async {
      final service = ImageSourceService(
        nativeShare: true,
        initialShared: () async => [
          SharedMediaFile(
            path: contentUri,
            type: SharedMediaType.image,
            mimeType: 'image/jpeg',
          ),
        ],
        readPath: (_) async => throw PlatformException(
          code: 'SecurityException',
          message: 'Permission Denial: opening provider com.android.providers.media.MediaProvider',
        ),
      );

      final image = await service.initialMedia();
      expect(image, isNotNull);
      expect(image!.errorMessage, CaptureLabels.sharePermissionDenied);
      expect(image.bytes, isNull);
    },
  );

  test(
    'warm share without URI permission yields PT-BR error on the stream',
    () async {
      final controller = StreamController<List<SharedMediaFile>>();
      addTearDown(controller.close);
      final service = ImageSourceService(
        nativeShare: true,
        sharedStream: controller.stream,
        readPath: (_) async => throw PlatformException(
          code: 'SecurityException',
          message: 'java.lang.SecurityException: Permission Denial',
        ),
      );

      final received = service.mediaStream.first;
      controller.add([
        SharedMediaFile(
          path: contentUri,
          type: SharedMediaType.image,
          mimeType: 'image/jpeg',
        ),
      ]);
      final image = await received;
      expect(image.errorMessage, CaptureLabels.sharePermissionDenied);
    },
  );

  test(
    'native uri_permission_denied payload shows PT-BR with default readPath',
    () async {
      final readable = File(
        '${Directory.systemTemp.path}/mj-share-readable.png',
      )..writeAsBytesSync(Uint8List.fromList(const [0x89, 0x50, 0x4E, 0x47]));
      addTearDown(() {
        if (readable.existsSync()) {
          readable.deleteSync();
        }
      });

      final service = ImageSourceService(
        nativeShare: true,
        initialShared: () async => [
          SharedMediaFile(
            path: readable.path,
            type: SharedMediaType.image,
            mimeType: 'image/png',
            error: kShareUriPermissionDenied,
          ),
        ],
      );

      // Default readPath would succeed on [readable.path]. The payload error
      // must win without a SecurityException mock.
      final image = await service.initialMedia();
      expect(image, isNotNull);
      expect(image!.errorMessage, CaptureLabels.sharePermissionDenied);
      expect(image.bytes, isNull);
    },
  );

  test(
    'content:// without error field still shows PT-BR via default readPath',
    () async {
      final service = ImageSourceService(
        nativeShare: true,
        initialShared: () async => [
          SharedMediaFile(
            path: contentUri,
            type: SharedMediaType.image,
            mimeType: 'image/jpeg',
          ),
        ],
      );

      final image = await service.initialMedia();
      expect(image, isNotNull);
      expect(image!.errorMessage, CaptureLabels.sharePermissionDenied);
      expect(image.bytes, isNull);
    },
  );
}
