import 'package:flutter/services.dart';

import 'capture_labels.dart';

/// Native `receive_sharing_intent` JSON field when a `content://` share has
/// no `FLAG_GRANT_READ_URI_PERMISSION`.
const kShareUriPermissionDenied = 'uri_permission_denied';

/// True when the plugin marked a share item as URI-permission denied.
bool isShareUriPermissionDeniedCode(String? error) {
  return error == kShareUriPermissionDenied;
}

/// True when a share / file read failed because the URI has no grant.
bool isSharePermissionError(Object error) {
  if (error is PlatformException) {
    final blob = '${error.code} ${error.message ?? ''} ${error.details ?? ''}'
        .toLowerCase();
    return blob.contains('securityexception') ||
        blob.contains('permission denial') ||
        blob.contains('permission denied') ||
        blob.contains(kShareUriPermissionDenied) ||
        (blob.contains('eacces') && blob.contains('content:'));
  }
  final text = error.toString().toLowerCase();
  return text.contains('securityexception') ||
      text.contains('permission denial') ||
      text.contains(kShareUriPermissionDenied) ||
      (text.contains('permission denied') && text.contains('content:')) ||
      (text.contains('content:') &&
          (text.contains('pathnotfound') || text.contains('no such file')));
}

/// User-facing PT-BR for a failed `/capture` load.
String captureLoadErrorMessage(Object error) {
  if (isSharePermissionError(error)) {
    return CaptureLabels.sharePermissionDenied;
  }
  return CaptureLabels.loadFailed;
}
