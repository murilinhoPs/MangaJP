import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../capture/presentation/gallery_import.dart';
import '../../pages/domain/page.dart';
import '../../review/domain/home_review_counts.dart';
import '../../review/domain/new_per_day.dart';
import 'home_controller.dart';

/// Keys for `/home` (Revisar + Capturas recentes + Galeria).
abstract final class HomeKeys {
  static const review = Key('home-review');
  static const due = Key('home-review-due');
  static const newToday = Key('home-review-new-today');
  static const recentCaptures = Key('home-recent-captures');
  static const recentEmpty = Key('home-recent-empty');
  static const gallery = Key('home-gallery');

  static Key recentThumb(String pageId) => Key('home-recent-thumb-$pageId');
}

/// `/home` — **Revisar**, **Capturas recentes**, **Galeria** (gallery pick → crop).
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hello = ref.watch(helloMetaProvider);
    final counts = ref.watch(homeReviewCountsProvider);
    final recent = ref.watch(homeRecentPagesProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('MangaJP Study', style: AppTypeScale.tituloTela),
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
        _RecentCapturesBlock(pages: recent.asData?.value),
        _GalleryBlock(onTap: () => importFromGallery(context, ref)),
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
              style: AppTypeScale.ui13.copyWith(
                color: context.tokens.violetText,
              ),
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

/// Always-visible **Capturas recentes**. Page image bytes are not persisted
/// (only `pages.sha256`); thumbs are tappable placeholders to `/pages/:id`.
class _RecentCapturesBlock extends StatelessWidget {
  const _RecentCapturesBlock({required this.pages});

  final List<MangaPage>? pages;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: HomeKeys.recentCaptures,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ListTile(
              leading: Icon(Icons.photo_library_outlined),
              title: Text('Capturas recentes'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: _body(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final items = pages;
    if (items == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (items.isEmpty) {
      return const Text('Nenhuma captura ainda.', key: HomeKeys.recentEmpty);
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final page in items)
          SizedBox(
            width: 80,
            height: 104,
            child: _RecentThumb(
              pageId: page.id,
              onTap: () => PageDetailRoute(id: page.id).go(context),
            ),
          ),
      ],
    );
  }
}

class _RecentThumb extends StatelessWidget {
  const _RecentThumb({required this.pageId, required this.onTap});

  final String pageId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final radius = BorderRadius.circular(AppRadius.segmentado);
    return Material(
      color: tokens.surfaceRaised,
      borderRadius: radius,
      child: InkWell(
        key: HomeKeys.recentThumb(pageId),
        onTap: onTap,
        borderRadius: radius,
        child: SizedBox.expand(
          child: Center(child: Icon(Icons.photo_outlined, color: tokens.text3)),
        ),
      ),
    );
  }
}

/// Always-visible **Galeria** import CTA. Tap opens the system gallery picker.
class _GalleryBlock extends StatelessWidget {
  const _GalleryBlock({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        key: HomeKeys.gallery,
        leading: const Icon(Icons.add_photo_alternate_outlined),
        title: const Text('Galeria'),
        subtitle: const Text('Escolher da galeria'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
