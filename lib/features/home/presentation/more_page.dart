import 'package:flutter/material.dart';

import '../../../core/router/routes.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: const Text('Páginas'),
          subtitle: const Text('/pages'),
          onTap: () => const PagesRoute().go(context),
        ),
        ListTile(
          leading: const Icon(Icons.style_outlined),
          title: const Text('Deck'),
          subtitle: const Text('/deck — stub'),
          onTap: () => const DeckRoute().go(context),
        ),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text('Settings'),
          subtitle: const Text('/settings'),
          onTap: () => const SettingsRoute().go(context),
        ),
      ],
    );
  }
}
