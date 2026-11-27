import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/features/capture/data/image_source_service.dart';
import 'package:manga_jp/features/capture/domain/capture_labels.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() {
  const contentUri = 'content://media/external/images/media/42';

  test('content:// without URI permission returns PT-BR error, does not throw',
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
        message:
            'Permission Denial: opening provider com.android.providers.media.MediaProvider',
      ),
    );

    final image = await service.initialMedia();
    expect(image, isNotNull);
    expect(image!.errorMessage, CaptureLabels.sharePermissionDenied);
    expect(image.bytes, isNull);
  });

  test('warm share without URI permission yields PT-BR error on the stream',
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
  });
}
