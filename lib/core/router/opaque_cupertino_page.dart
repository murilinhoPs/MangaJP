import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';

/// Holds the active swipe route's restore callback (injected, not static).
class BlockedPopRestorer {
  VoidCallback? _restore;

  void attach(VoidCallback restore) => _restore = restore;

  void detach(VoidCallback restore) {
    if (identical(_restore, restore)) {
      _restore = null;
    }
  }

  void restoreForward() => _restore?.call();
}

/// Cupertino slide keeps the previous route in view. A transparent child lets
/// Home/Caderno text show through mid-transition; paint [MangaJpTokens.bg]
/// (same as AppChrome at rest) so the incoming page is opaque.
Page<void> opaqueCupertinoPage(
  BuildContext context, {
  required LocalKey key,
  required Widget child,
  bool allowPopGestureWhenBlocked = false,
  BlockedPopRestorer? restorer,
}) {
  final wrapped = ColoredBox(color: context.tokens.bg, child: child);
  if (allowPopGestureWhenBlocked) {
    return _SwipeableCupertinoPage(
      key: key,
      child: wrapped,
      restorer: restorer,
    );
  }
  return CupertinoPage<void>(key: key, child: wrapped);
}

/// After a completed iOS back-swipe whose pop was vetoed (confirm dialog
/// cancel), slide the page back on screen. No-op when the animation is
/// already at 1.0 (system back / Fechar).
void restoreBlockedCupertinoPop(BlockedPopRestorer? restorer) {
  restorer?.restoreForward();
}

class _SwipeableCupertinoPage extends Page<void> {
  const _SwipeableCupertinoPage({
    required super.key,
    required this.child,
    this.restorer,
  });

  final Widget child;
  final BlockedPopRestorer? restorer;

  @override
  Route<void> createRoute(BuildContext context) {
    return _SwipeableCupertinoPageRoute(page: this);
  }
}

/// Same slide as [CupertinoPage], but the edge swipe stays enabled even when
/// a [PopScope] sets `canPop: false`. Completing the swipe still calls
/// [Navigator.pop]; [GoRoute.onExit] / [PopScope] decide whether to leave.
class _SwipeableCupertinoPageRoute extends PageRoute<void>
    with CupertinoRouteTransitionMixin<void> {
  _SwipeableCupertinoPageRoute({required _SwipeableCupertinoPage page})
    : super(settings: page) {
    assert(opaque);
  }

  _SwipeableCupertinoPage get _page => settings as _SwipeableCupertinoPage;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      CupertinoPageTransition.delegatedTransition;

  @override
  Widget buildContent(BuildContext context) => _page.child;

  @override
  String? get title => null;

  @override
  bool get maintainState => true;

  @override
  bool get fullscreenDialog => false;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';

  @override
  bool get popGestureEnabled {
    if (isFirst || willHandlePopInternally || fullscreenDialog) {
      return false;
    }
    if (!animation!.isCompleted && !popGestureInProgress) {
      return false;
    }
    return true;
  }

  @override
  TickerFuture didPush() {
    _page.restorer?.attach(restoreForward);
    return super.didPush();
  }

  @override
  void dispose() {
    _page.restorer?.detach(restoreForward);
    super.dispose();
  }

  void restoreForward() {
    final animationController = controller;
    if (animationController == null || animationController.value >= 1) {
      return;
    }
    animationController.animateTo(
      1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.fastEaseInToSlowEaseOut,
    );
  }
}
