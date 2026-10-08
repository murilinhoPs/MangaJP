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
    return {
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
    }
  }

  Future<void> _openPalette(BuildContext context) async {
    _paletteOpen = true;
    final items = <PaletteAction>[
      ...ShellPaletteNav.items,
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
    // Deck, Mais, Páginas) keep R as a shortcut but do not duplicate Home's bar.
    return _registry.task?.actions ?? const <ShellAction>[];
  }

  @override
  Widget build(BuildContext context) {
    final path = _path;
    final wide = ShellLayout.isWide(context);
    final counts = ref.watch(homeReviewCountsProvider);
    final due = counts.asData?.value.due ?? 0;
    final task = ShellLayout.isTask(path);

    final barActions = _barActions(context);
    Widget body = widget.child;
    if (wide) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppRail(path: path, dueCount: due),
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
