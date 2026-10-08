import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../router/routes.dart';
import '../theme/app_theme.dart';

/// Shell geometry and destination mapping (M1.20).
///
/// Wide breakpoint is [AppBreakpoints.wide] (900). Rail width 76 and the
/// command-bar offset 24 are specified in the brief, not `tokens.json`.
abstract final class ShellLayout {
  static const double railWidth = 76;
  static const double commandBarBottom = 24;
  static const double jpSealSize = 34;

  static bool isWide(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= AppBreakpoints.wide;
  }

  /// Página (`/pages/:id`), Captura, Review: hide mobile nav cards.
  static bool isTask(String path) {
    if (path == '/capture' || path == '/review') {
      return true;
    }
    return path.startsWith('/pages/') && path != '/pages';
  }

  static bool showMobileNavCards(String path) => !isTask(path);
}

/// Widget keys for shell tests and screenshots.
abstract final class ShellKeys {
  static const navCards = Key('shell-nav-cards');
  static const rail = Key('shell-rail');
  static const railAjustes = Key('shell-rail-ajustes');
  static const reviewBadge = Key('shell-review-badge');
  static const commandBar = Key('shell-command-bar');
  static const palette = Key('shell-command-palette');
  static const taskDock = Key('shell-task-dock');
  static const dockMeta = Key('shell-task-dock-meta');
  static const jpSeal = Key('shell-jp-seal');

  static Key navCard(String id) => Key('shell-nav-card-$id');
  static Key railItem(String id) => Key('shell-rail-item-$id');
  static Key command(String id) => Key('shell-command-$id');
  static Key paletteItem(String id) => Key('shell-palette-$id');
  static Key dockAction(String id) => Key('shell-dock-$id');
}

/// Modifier for Brief §6 chords: ⌘ on Apple, Ctrl elsewhere.
abstract final class ShellShortcuts {
  static bool get usesMeta {
    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
      case TargetPlatform.iOS:
        return true;
      default:
        return false;
    }
  }

  static String chord(String key) => usesMeta ? '⌘$key' : 'Ctrl+$key';

  static SingleActivator activator(LogicalKeyboardKey key) {
    return SingleActivator(key, control: !usesMeta, meta: usesMeta);
  }
}

class ShellDestination {
  const ShellDestination({
    required this.id,
    required this.label,
    required this.icon,
    required this.go,
    required this.isActive,
  });

  final String id;
  final String label;
  final IconData icon;
  final void Function(BuildContext context) go;
  final bool Function(String path) isActive;
}

/// Mobile nav cards: Início · Caderno · Deck · Ajustes.
abstract final class MobileNav {
  static const destinations = <ShellDestination>[
    ShellDestination(
      id: 'inicio',
      label: 'Início',
      icon: Icons.home_outlined,
      go: _goHome,
      isActive: _homeActive,
    ),
    ShellDestination(
      id: 'caderno',
      label: 'Caderno',
      icon: Icons.menu_book_outlined,
      go: _goNotebook,
      isActive: _notebookActive,
    ),
    ShellDestination(
      id: 'deck',
      label: 'Deck',
      icon: Icons.layers_outlined,
      go: _goDeck,
      isActive: _deckActive,
    ),
    ShellDestination(
      id: 'ajustes',
      label: 'Ajustes',
      icon: Icons.wb_sunny_outlined,
      go: _goMore,
      isActive: _ajustesActive,
    ),
  ];
}

/// Desktop rail: Biblioteca, Leitor, Revisar, Caderno, Deck; Ajustes pinned.
abstract final class DesktopRail {
  static const items = <ShellDestination>[
    ShellDestination(
      id: 'biblioteca',
      label: 'Biblioteca',
      icon: Icons.auto_stories_outlined,
      go: _goHome,
      isActive: _homeActive,
    ),
    ShellDestination(
      id: 'leitor',
      label: 'Leitor',
      icon: Icons.chrome_reader_mode_outlined,
      go: _goPages,
      isActive: _pagesActive,
    ),
    ShellDestination(
      id: 'revisar',
      label: 'Revisar',
      icon: Icons.style_outlined,
      go: _goReview,
      isActive: _reviewActive,
    ),
    ShellDestination(
      id: 'caderno',
      label: 'Caderno',
      icon: Icons.menu_book_outlined,
      go: _goNotebook,
      isActive: _notebookActive,
    ),
    ShellDestination(
      id: 'deck',
      label: 'Deck',
      icon: Icons.layers_outlined,
      go: _goDeck,
      isActive: _deckActive,
    ),
  ];

  static const ajustes = ShellDestination(
    id: 'ajustes',
    label: 'Ajustes',
    icon: Icons.wb_sunny_outlined,
    go: _goSettings,
    isActive: _settingsActive,
  );
}

class PaletteAction {
  const PaletteAction({
    required this.id,
    required this.label,
    required this.run,
  });

  final String id;
  final String label;
  final void Function(BuildContext context) run;
}

/// Palette entries that always navigate (existing routes only).
abstract final class ShellPaletteNav {
  static const items = <PaletteAction>[
    PaletteAction(id: 'inicio', label: 'Início', run: _goHome),
    PaletteAction(id: 'paginas', label: 'Páginas', run: _goPages),
    PaletteAction(id: 'revisar', label: 'Revisar', run: _goReview),
    PaletteAction(id: 'caderno', label: 'Caderno', run: _goNotebook),
    PaletteAction(id: 'deck', label: 'Deck', run: _goDeck),
    PaletteAction(id: 'more', label: 'Mais', run: _goMore),
    PaletteAction(id: 'ajustes', label: 'Ajustes', run: _goSettings),
  ];
}

void _goHome(BuildContext context) => const HomeRoute().go(context);
void _goPages(BuildContext context) => const PagesRoute().go(context);
void _goReview(BuildContext context) => const ReviewRoute().go(context);
void _goNotebook(BuildContext context) => const NotebookRoute().go(context);
void _goDeck(BuildContext context) => const DeckRoute().go(context);
void _goMore(BuildContext context) => const MoreRoute().go(context);
void _goSettings(BuildContext context) => const SettingsRoute().go(context);

bool _homeActive(String path) => path == '/home';
bool _pagesActive(String path) =>
    path == '/pages' || path.startsWith('/pages/');
bool _reviewActive(String path) => path == '/review';
bool _notebookActive(String path) => path.startsWith('/notebook');
bool _deckActive(String path) => path == '/deck';
bool _ajustesActive(String path) => path == '/more' || path == '/settings';
bool _settingsActive(String path) => path == '/settings';
