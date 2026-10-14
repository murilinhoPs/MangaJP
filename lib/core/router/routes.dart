import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../features/capture/domain/incoming_image.dart';
import '../../features/capture/presentation/capture_page.dart';
import '../../features/flashcards/presentation/deck_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/notebook/presentation/notebook_page.dart';
import '../../features/notebook/presentation/notebook_word_page.dart';
import '../../features/pages/presentation/page_detail_page.dart';
import '../../features/review/presentation/review_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../shell/app_chrome.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';

part 'routes.g.dart';

@TypedShellRoute<AppChromeRoute>(
  routes: <TypedRoute<RouteData>>[
    TypedStatefulShellRoute<AppShellRoute>(
      branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
        TypedStatefulShellBranch<HomeBranch>(
          routes: <TypedRoute<RouteData>>[
            TypedGoRoute<HomeRoute>(path: '/home'),
          ],
        ),
        TypedStatefulShellBranch<ReviewBranch>(
          routes: <TypedRoute<RouteData>>[
            TypedGoRoute<ReviewRoute>(path: '/review'),
          ],
        ),
        TypedStatefulShellBranch<NotebookBranch>(
          routes: <TypedRoute<RouteData>>[
            TypedGoRoute<NotebookRoute>(
              path: '/notebook',
              routes: <TypedRoute<RouteData>>[
                TypedGoRoute<NotebookWordRoute>(path: 'word/:id'),
              ],
            ),
          ],
        ),
      ],
    ),
    TypedGoRoute<PageDetailRoute>(path: '/pages/:id'),
    TypedGoRoute<PagesRoute>(path: '/pages'),
    TypedGoRoute<CaptureRoute>(path: '/capture'),
    TypedGoRoute<SettingsRoute>(path: '/settings'),
    TypedGoRoute<DeckRoute>(path: '/deck'),
    TypedGoRoute<MoreRoute>(path: '/more'),
  ],
)
class AppChromeRoute extends ShellRouteData {
  const AppChromeRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) {
    return AppChrome(child: navigator);
  }
}

class AppShellRoute extends StatefulShellRouteData {
  const AppShellRoute();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    return AppScaffold(navigationShell: navigationShell);
  }
}

class HomeBranch extends StatefulShellBranchData {
  const HomeBranch();
}

class ReviewBranch extends StatefulShellBranchData {
  const ReviewBranch();
}

class NotebookBranch extends StatefulShellBranchData {
  const NotebookBranch();
}

class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const HomePage();
}

/// `/pages` list moved to Home (**Páginas recentes** / **Capturas recentes**).
class PagesRoute extends GoRouteData with $PagesRoute {
  const PagesRoute();

  @override
  String? redirect(BuildContext context, GoRouterState state) => '/home';
}

class PageDetailRoute extends GoRouteData with $PageDetailRoute {
  const PageDetailRoute({required this.id});

  final String id;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _opaqueCupertinoPage(
      context,
      key: state.pageKey,
      child: PageDetailPage(pageId: id),
    );
  }
}

class ReviewRoute extends GoRouteData with $ReviewRoute {
  const ReviewRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const ReviewPage();
}

class NotebookRoute extends GoRouteData with $NotebookRoute {
  const NotebookRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const NotebookPage();
  }
}

class NotebookWordRoute extends GoRouteData with $NotebookWordRoute {
  const NotebookWordRoute({required this.id});

  final String id;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _opaqueCupertinoPage(
      context,
      key: state.pageKey,
      child: NotebookWordPage(wordId: id),
    );
  }
}

/// Deep-link shim: `/more` (Mais) now opens Ajustes.
class MoreRoute extends GoRouteData with $MoreRoute {
  const MoreRoute();

  @override
  String? redirect(BuildContext context, GoRouterState state) => '/settings';
}

class CaptureRoute extends GoRouteData with $CaptureRoute {
  const CaptureRoute({this.$extra});

  /// Share / gallery / test fixture. Not a URL param (bytes are not serializable).
  final IncomingImage? $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CapturePage(image: $extra);
  }
}

class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SettingsPage();
  }
}

class DeckRoute extends GoRouteData with $DeckRoute {
  const DeckRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const DeckPage();
}

/// Cupertino slide keeps the previous route in view. A transparent child lets
/// Home/Caderno text show through mid-transition; paint [MangaJpTokens.bg]
/// (same as AppChrome at rest) so the incoming page is opaque.
Page<void> _opaqueCupertinoPage(
  BuildContext context, {
  required LocalKey key,
  required Widget child,
}) {
  return CupertinoPage<void>(
    key: key,
    child: ColoredBox(color: context.tokens.bg, child: child),
  );
}
