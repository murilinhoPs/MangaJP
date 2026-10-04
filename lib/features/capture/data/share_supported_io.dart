import 'dart:io';

/// Android / iOS only. Uses `dart:io` because `defaultTargetPlatform` is
/// Android inside `flutter test` on the CI host.
bool get nativeShareSupported => Platform.isAndroid || Platform.isIOS;
