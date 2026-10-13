import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/capture/data/image_source_service.dart';
import '../../features/capture/presentation/share_intent_binder.dart';
import 'routes.dart';

part 'app_router.g.dart';

/// Screenshot helper. Default `/home`. Override with
/// `--dart-define=MANGAJP_INITIAL_LOCATION=/pages/demo-page`.
const kMangaJpInitialLocation = String.fromEnvironment(
  'MANGAJP_INITIAL_LOCATION',
  defaultValue: '/home',
);

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final initial = kMangaJpInitialLocation.isEmpty
      ? '/home'
      : kMangaJpInitialLocation;
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
