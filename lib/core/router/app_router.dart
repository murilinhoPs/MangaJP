import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/capture/data/image_source_service.dart';
import '../../features/capture/presentation/share_intent_binder.dart';
import 'routes.dart';

part 'app_router.g.dart';

/// Screenshot helper. Default `/home`. Override with
/// `--dart-define=MANGAJP_INITIAL_LOCATION=/pages/demo-page`.
/// Ignored in release; unknown paths fall back to `/home`.
const kMangaJpInitialLocation = String.fromEnvironment(
  'MANGAJP_INITIAL_LOCATION',
  defaultValue: '/home',
);

@visibleForTesting
String resolveMangaJpInitialLocation({
  required String defined,
  required bool release,
}) {
  if (release || defined.isEmpty) {
    return '/home';
  }
  return isAllowedMangaJpInitialLocation(defined) ? defined : '/home';
}

@visibleForTesting
bool isAllowedMangaJpInitialLocation(String path) {
  const exact = {
    '/home',
    '/capture',
    '/review',
    '/notebook',
    '/deck',
    '/settings',
    '/more',
    '/pages',
  };
  if (exact.contains(path)) {
    return true;
  }
  if (path.contains('..') || path.contains('//')) {
    return false;
  }
  if (path.startsWith('/pages/') && path.length > '/pages/'.length) {
    return true;
  }
  if (path.startsWith('/notebook/word/') &&
      path.length > '/notebook/word/'.length) {
    return true;
  }
  return false;
}

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final initial = resolveMangaJpInitialLocation(
    defined: kMangaJpInitialLocation,
    release: kReleaseMode,
  );
  final router = GoRouter(initialLocation: initial, routes: $appRoutes);
  final binder = ShareIntentBinder(
    router: router,
    source: ref.read(imageSourceServiceProvider),
  )..start();
  ref.onDispose(() {
    binder.dispose();
    router.dispose();
  });
  return router;
}
