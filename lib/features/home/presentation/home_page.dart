import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/routes.dart';
import '../../review/domain/home_review_counts.dart';
import '../../review/domain/new_per_day.dart';
import 'home_controller.dart';

/// Keys for `/home` (Revisar block).
abstract final class HomeKeys {
  static const review = Key('home-review');
  static const due = Key('home-review-due');
  static const newToday = Key('home-review-new-today');
}

/// `/home` — **Revisar** (due + novos hoje) plus stub IA blocks.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hello = ref.watch(helloMetaProvider);
    final counts = ref.watch(homeReviewCountsProvider);

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
        _ReviewBlock(
          counts: counts.asData?.value,
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
          subtitle: 'Import → /capture (crop → OCR)',
          icon: Icons.add_photo_alternate_outlined,
          onTap: () => const CaptureRoute().push<void>(context),
        ),
      ],
    );
  }
}

/// Always-visible **Revisar** block. Tap opens `/review`, including 0 / 0 de 15.
class _ReviewBlock extends StatelessWidget {
  const _ReviewBlock({required this.counts, required this.onTap});

  final HomeReviewCounts? counts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final due = counts?.due ?? 0;
    final newToday = counts?.newToday ?? 0;
    return Card(
      child: ListTile(
        key: HomeKeys.review,
        leading: const Icon(Icons.style_outlined),
        title: const Text('Revisar'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Due: $due', key: HomeKeys.due),
            Text(
              'Novos hoje: $newToday de ${NewPerDay.limit}',
              key: HomeKeys.newToday,
            ),
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
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
