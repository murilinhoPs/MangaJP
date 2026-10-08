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

  bool get _typing {
    final focus = FocusManager.instance.primaryFocus;
    final ctx = focus?.context;
    if (ctx == null) {
      return false;
    }
    return ctx.widget is EditableText ||
        ctx.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  Map<ShortcutActivator, VoidCallback> _bindings(BuildContext context) {
    return {
      const SingleActivator(LogicalKeyboardKey.keyR): () {
        if (_typing) {
          return;
        }
        const ReviewRoute().go(context);
      },
      ShellShortcuts.activator(LogicalKeyboardKey.keyK): () {
        if (_typing || _paletteOpen) {
          return;
        }
        _openPalette(context);
      },
      ShellShortcuts.activator(LogicalKeyboardKey.keyO): () {
        if (_typing) {
          return;
        }
        importFromGallery(context, ref);
      },
      const SingleActivator(LogicalKeyboardKey.slash): () {
        if (_typing) {
          return;
        }
        _focusNotebookSearch(context);
      },
      const SingleActivator(LogicalKeyboardKey.escape): () {
        _onEscape(context);
      },
    };
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
      notebookSearchFocusNode.requestFocus();
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

    Widget body = widget.child;
    if (wide) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppRail(path: path, dueCount: due),
          Expanded(
            child: Stack(
              children: [
                body,
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: CommandBar(actions: _barActions(context)),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ShellScope(
      registry: _registry,
      child: CallbackShortcuts(
        bindings: _bindings(context),
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
    );
  }
}
