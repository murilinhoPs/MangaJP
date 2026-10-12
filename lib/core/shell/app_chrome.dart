import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/capture/presentation/gallery_import.dart';
import '../../features/home/presentation/home_controller.dart';
import '../../features/notebook/presentation/notebook_page.dart';
import '../router/routes.dart';
import '../theme/app_theme.dart';
import 'app_rail.dart';
import 'command_bar.dart';
import 'command_palette.dart';
import 'nav_cards.dart';
import 'shell_layout.dart';
import 'shell_registry.dart';

/// Parent chrome: mobile nav cards / desktop rail + command bar + shortcuts.
class AppChrome extends ConsumerStatefulWidget {
  const AppChrome({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppChrome> createState() => _AppChromeState();
}

class _AppChromeState extends ConsumerState<AppChrome> {
  final ShellRegistry _registry = ShellRegistry();
  final FocusNode _focus = FocusNode();
  bool _paletteOpen = false;

  @override
  void initState() {
    super.initState();
    _registry.addListener(_onRegistry);
  }

  void _onRegistry() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _registry.removeListener(_onRegistry);
    _registry.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _path {
    final router = GoRouter.maybeOf(context);
    return router?.state.uri.path ?? GoRouterState.of(context).uri.path;
  }

  Map<ShortcutActivator, Intent> get _shortcuts {
    final map = <ShortcutActivator, Intent>{
      const SingleActivator(LogicalKeyboardKey.keyR): const ShellShortcutIntent(
        'r',
      ),
      ShellShortcuts.activator(LogicalKeyboardKey.keyK):
          const ShellShortcutIntent('k'),
      ShellShortcuts.activator(LogicalKeyboardKey.keyO):
          const ShellShortcutIntent('o'),
      const SingleActivator(LogicalKeyboardKey.slash):
          const ShellShortcutIntent('slash'),
      const SingleActivator(LogicalKeyboardKey.escape):
          const _ShellEscapeIntent(),
    };
    if (_path == '/home') {
      map[const SingleActivator(LogicalKeyboardKey.digit1)] =
          const ShellShortcutIntent('home-1');
      map[const SingleActivator(LogicalKeyboardKey.digit2)] =
          const ShellShortcutIntent('home-2');
      map[const SingleActivator(LogicalKeyboardKey.digit3)] =
          const ShellShortcutIntent('home-3');
    }
    return map;
  }

  Map<Type, Action<Intent>> _actions(BuildContext context) {
    return {
      ShellShortcutIntent: ShellPassthroughAction(
        shouldPassThrough: () => ShellShortcuts.isTyping,
        onInvoke: (intent) => _invokeShortcut(context, intent.id),
      ),
      _ShellEscapeIntent: CallbackAction<_ShellEscapeIntent>(
        onInvoke: (_) {
          _onEscape(context);
          return null;
        },
      ),
    };
  }

  void _invokeShortcut(BuildContext context, String id) {
    switch (id) {
      case 'r':
        const ReviewRoute().go(context);
      case 'k':
        if (!_paletteOpen) {
          _openPalette(context);
        }
      case 'o':
        importFromGallery(context, ref);
      case 'slash':
        _focusNotebookSearch(context);
      case 'home-1':
        _openRecentPage(context, 0);
      case 'home-2':
        _openRecentPage(context, 1);
      case 'home-3':
        _openRecentPage(context, 2);
    }
  }

  String? get _recentPageId {
    final pages = ref.read(homeRecentPagesProvider).asData?.value;
    if (pages == null || pages.isEmpty) {
      return null;
    }
    return pages.first.id;
  }

  void _openRecentPage(BuildContext context, int index) {
    final pages = ref.read(homeRecentPagesProvider).asData?.value;
    if (pages == null || index < 0 || index >= pages.length) {
      return;
    }
    PageDetailRoute(id: pages[index].id).go(context);
  }

  Future<void> _openPalette(BuildContext context) async {
    _paletteOpen = true;
    final recentPageId = _recentPageId;
    final items = <PaletteAction>[
      ...ShellPaletteNav.items(recentPageId: recentPageId),
      for (final action in _barActions(context))
        PaletteAction(
          id: 'bar-${action.id}',
          label: action.label,
          run: (_) => action.onPressed(),
        ),
    ];
    try {
      await showCommandPalette(context, items: items);
    } finally {
      _paletteOpen = false;
    }
  }

  void _focusNotebookSearch(BuildContext context) {
    const NotebookRoute().go(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotebookSearch.requestFocus();
    });
  }

  void _onEscape(BuildContext context) {
    if (_paletteOpen) {
      return;
    }
    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      router.pop();
      return;
    }
    if (ShellLayout.isTask(_path)) {
      const HomeRoute().go(context);
    }
  }

  List<ShellAction> _barActions(BuildContext context) {
    final path = _path;
    if (path == '/home') {
      return [
        ShellAction(
          id: 'revisar',
          label: 'Revisar',
          shortcut: 'R',
          primary: true,
          onPressed: () => const ReviewRoute().go(context),
        ),
        ShellAction(
          id: 'galeria',
          label: 'Abrir galeria',
          shortcut: ShellShortcuts.chord('O'),
          onPressed: () => importFromGallery(context, ref),
        ),
      ];
    }
    // Task screens bind their own bar actions. Other destinations (Caderno,
    // Deck, Ajustes, Páginas) keep R as a shortcut but do not duplicate Home's bar.
    return _registry.task?.actions ?? const <ShellAction>[];
  }

  @override
  Widget build(BuildContext context) {
    final path = _path;
    final wide = ShellLayout.isWide(context);
    final counts = ref.watch(homeReviewCountsProvider);
    final revisoes = counts.asData?.value.revisoes ?? 0;
    ref.watch(homeRecentPagesProvider);
    final task = ShellLayout.isTask(path);

    final barActions = _barActions(context);
    Widget body = widget.child;
    if (wide) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppRail(
            path: path,
            reviewBadge: revisoes,
            recentPageId: _recentPageId,
          ),
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    bottom: barActions.isEmpty
                        ? 0
                        : ShellLayout.commandBarClearance,
                  ),
                  child: body,
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: CommandBar(actions: barActions),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ShellScope(
      registry: _registry,
      child: Shortcuts(
        shortcuts: _shortcuts,
        child: Actions(
          actions: _actions(context),
          child: Focus(
            focusNode: _focus,
            autofocus: true,
            child: Scaffold(
              backgroundColor: context.tokens.bg,
              body: body,
              bottomNavigationBar: wide || task ? null : NavCards(path: path),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellEscapeIntent extends Intent {
  const _ShellEscapeIntent();
}
