import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../shell/shell_layout.dart';
import '../theme/app_theme.dart';

/// Inner shell: title AppBar (no actions) + the tab body.
///
/// Mobile nav cards, desktop rail, and the command bar live in [AppChrome].
class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _titles = <String>[
    'Início',
    'Páginas',
    'Review',
    'Caderno',
    'Ajustes',
  ];

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final hideBar = path == '/home' || ShellLayout.isTask(path);
    return Scaffold(
      backgroundColor: context.tokens.bg,
      appBar: hideBar
          ? null
          : AppBar(title: Text(_titles[navigationShell.currentIndex])),
      body: navigationShell,
    );
  }
}
