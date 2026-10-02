import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/routes.dart';
import 'home_controller.dart';

/// Home stub (`/home`) — 3 IA blocks as placeholders + Drift/Riverpod hello.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hello = ref.watch(helloMetaProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('MangaJP Study', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        hello.when(
          data: (value) => Card(
            child: ListTile(
              leading: const Icon(Icons.storage_outlined),
              title: const Text('Drift + Riverpod'),
              subtitle: Text('app_meta.hello = $value'),
            ),
          ),
          loading: () => const Card(
            child: ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Abrindo banco…'),
            ),
          ),
          error: (error, _) => Card(
            child: ListTile(
              leading: const Icon(Icons.error_outline),
              title: const Text('Falha no Drift hello'),
              subtitle: Text('$error'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _StubBlock(
          title: 'Revisar',
          subtitle: 'Due + novos hoje — stub',
          icon: Icons.style_outlined,
          onTap: () => const ReviewRoute().go(context),
        ),
        _StubBlock(
          title: 'Capturas recentes',
          subtitle: 'Thumbs → /pages/:id — stub',
          icon: Icons.photo_library_outlined,
          onTap: () => const PagesRoute().go(context),
        ),
        _StubBlock(
          title: 'Galeria',
          subtitle: 'Import → /capture (crop)',
          icon: Icons.add_photo_alternate_outlined,
          onTap: () => const CaptureRoute().push<void>(context),
        ),
      ],
    );
  }
}

class _StubBlock extends StatelessWidget {
  const _StubBlock({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
