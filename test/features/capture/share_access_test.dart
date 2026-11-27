import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/features/capture/domain/capture_labels.dart';
import 'package:manga_jp/features/capture/domain/share_access.dart';

void main() {
  test('SecurityException PlatformException is a share permission error', () {
    final error = PlatformException(
      code: 'SecurityException',
      message: 'Permission Denial: opening provider com.android.providers.media.MediaProvider',
    );
    expect(isSharePermissionError(error), isTrue);
    expect(captureLoadErrorMessage(error), CaptureLabels.sharePermissionDenied);
  });

  test('permission denial string from native is a share permission error', () {
    final error = PlatformException(
      code: 'error',
      message: 'java.lang.SecurityException: Permission Denial',
    );
    expect(isSharePermissionError(error), isTrue);
  });

  test('other IO errors are not permission denials', () {
    final error = Exception('FileSystemException: No such file');
    expect(isSharePermissionError(error), isFalse);
    expect(captureLoadErrorMessage(error), CaptureLabels.loadFailed);
  });

  test(
    'PathNotFoundException on a content:// path is a share permission error',
    () {
      final error = Exception(
        "PathNotFoundException: Cannot open file, path = "
        "'content://media/external/images/media/42' "
        "(OS Error: No such file or directory, errno = 2)",
      );
      expect(isSharePermissionError(error), isTrue);
      expect(
        captureLoadErrorMessage(error),
        CaptureLabels.sharePermissionDenied,
      );
    },
  );

  test('uri_permission_denied payload code maps to the PT-BR copy', () {
    expect(isShareUriPermissionDeniedCode(kShareUriPermissionDenied), isTrue);
    expect(isShareUriPermissionDeniedCode(null), isFalse);
    expect(isShareUriPermissionDeniedCode('other'), isFalse);
  });
}
