import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/routes.dart';
import '../../../core/shell/kbd_chip.dart';
import '../../../core/shell/shell_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../capture/presentation/gallery_import.dart';
import '../../review/domain/home_review_counts.dart';
import '../domain/home_dates.dart';
import '../domain/home_recent_entry.dart';
import '../domain/home_week_rhythm.dart';
import 'home_controller.dart';

/// Keys for `/home` (Fila de hoje + Capturas recentes + Páginas recentes).
abstract final class HomeKeys {
  static const review = Key('home-review');
  static const due = Key('home-review-due');
  static const newToday = Key('home-review-new-today');
  static const novos = Key('home-queue-novos');
  static const revisoes = Key('home-queue-revisoes');
  static const drill = Key('home-queue-drill');
  static const recentCaptures = Key('home-recent-captures');
  static const recentPages = Key('home-recent-pages');
  static const recentEmpty = Key('home-recent-empty');
  static const gallery = Key('home-gallery');
  static const continueReading = Key('home-continue-reading');
  static const weekRhythm = Key('home-week-rhythm');
  static const typingProbe = Key('home-typing-probe');

  static Key recentThumb(String pageId) => Key('home-recent-thumb-$pageId');
  static Key recentPage(String pageId) => Key('home-recent-page-$pageId');
}

/// `/home` — mobile **Fila de hoje**; desktop Biblioteca counts + **Páginas recentes**.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(homeReviewCountsProvider).asData?.value;
    final recent = ref.watch(homeRecentPagesProvider).asData?.value;
    final totalPages = ref.watch(homePageCountProvider).asData?.value;
    final week = ref.watch(homeWeekRhythmProvider).asData?.value;
    final now = DateTime.now();
    if (ShellLayout.isWide(context)) {
      return _DesktopHome(counts: counts, recent: recent, now: now);
    }
    return _MobileHome(
      counts: counts,
      recent: recent,
      totalPages: totalPages,
      week: week,
      now: now,
      onGallery: () => importFromGallery(context, ref),
    );
  }
}

class _MobileHome extends StatelessWidget {
  const _MobileHome({
    required this.counts,
    required this.recent,
    required this.totalPages,
    required this.week,
    required this.now,
    required this.onGallery,
  });

  final HomeReviewCounts? counts;
  final List<HomeRecentEntry>? recent;
  final int? totalPages;
  final HomeWeekRhythm? week;
  final DateTime now;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final continuePage = recent == null || recent!.isEmpty
        ? null
        : recent!.first;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        const Text('MangaJP', style: AppTypeScale.tituloTela),
        const SizedBox(height: 4),
        Text(
          HomeDates.headerSubline(now),
          style: AppTypeScale.metadados12.copyWith(color: tokens.text3),
        ),
        const SizedBox(height: 20),
        _QueueCard(
          counts: counts,
          onTap: () => const ReviewRoute().go(context),
        ),
        if (continuePage != null) ...[
          const SizedBox(height: 12),
          _ContinueReadingCard(
            page: continuePage,
            onTap: () => PageDetailRoute(id: continuePage.id).go(context),
          ),
        ],
        if (week != null) ...[
          const SizedBox(height: 12),
          _WeekRhythmCard(week: week!),
        ],
        const SizedBox(height: 20),
        _RecentCapturesBlock(
          pages: recent,
          total: totalPages,
          now: now,
        ),
        const SizedBox(height: 12),
        _GalleryBlock(onTap: onGallery),
      ],
    );
  }
}

class _DesktopHome extends StatelessWidget {
  const _DesktopHome({
    required this.counts,
    required this.recent,
    required this.now,
  });

  final HomeReviewCounts? counts;
  final List<HomeRecentEntry>? recent;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(48, 36, 48, 24),
      children: [
        const ExcludeSemantics(
          child: SizedBox(
            height: 1,
            child: TextField(
              key: HomeKeys.typingProbe,
              decoration: InputDecoration.collapsed(hintText: ''),
            ),
          ),
        ),
        _DesktopCounts(counts: counts),
        const SizedBox(height: 40),
        _RecentPagesList(pages: recent, now: now),
      ],
    );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.counts, required this.onTap});

  final HomeReviewCounts? counts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final waiting = counts?.waiting ?? 0;
    final novos = counts?.novos ?? 0;
    final revisoes = counts?.revisoes ?? 0;
    final drill = counts?.drill ?? 0;
    final radius = BorderRadius.circular(AppRadius.cardFila);
    return Material(
      color: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: tokens.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: HomeKeys.review,
        onTap: onTap,
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned(
              right: 8,
              top: 8,
              child: IgnorePointer(
                child: Text(
                  '復習',
                  style: AppTypeScale.reviewMobileJp.copyWith(
                    color: tokens.coral.withValues(alpha: 0.08),
                    height: 1,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: tokens.coral,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'FILA DE HOJE',
                        style: AppTypeScale.mono10.copyWith(
                          color: tokens.coral,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Revisar →',
                        style: AppTypeScale.ui13.copyWith(
                          color: tokens.coralText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$waiting',
                        key: HomeKeys.due,
                        style: AppTypeScale.contagemHome.copyWith(height: 0.95),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'cards esperando',
                        style: AppTypeScale.ui14.copyWith(color: tokens.text3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _QueueBar(novos: novos, revisoes: revisoes, drill: drill),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      _QueueCount(
                        key: HomeKeys.novos,
                        count: novos,
                        label: 'novos',
                        color: tokens.violetText,
                      ),
                      _QueueCount(
                        key: HomeKeys.revisoes,
                        count: revisoes,
                        label: 'revisões',
                        color: tokens.mint,
                      ),
                      _QueueCount(
                        key: HomeKeys.drill,
                        count: drill,
                        label: 'drill',
                        color: tokens.coral,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueBar extends StatelessWidget {
  const _QueueBar({
    required this.novos,
    required this.revisoes,
    required this.drill,
  });

  final int novos;
  final int revisoes;
  final int drill;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final total = novos + revisoes + drill;
    const height = 8.0;
    final radius = BorderRadius.circular(AppRadius.segmentado);
    if (total == 0) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: tokens.surfaceLow,
          borderRadius: radius,
        ),
      );
    }
    return SizedBox(
      height: height,
      child: Row(
        children: [
          if (novos > 0)
            Expanded(
              flex: novos,
              child: _seg(tokens.queueNovos, radius),
            ),
          if (novos > 0 && (revisoes > 0 || drill > 0))
            const SizedBox(width: 3),
          if (revisoes > 0)
            Expanded(
              flex: revisoes,
              child: _seg(tokens.queueRevisoes, radius),
            ),
          if (revisoes > 0 && drill > 0) const SizedBox(width: 3),
          if (drill > 0)
            Expanded(
              flex: drill,
              child: _seg(tokens.queueDrill, radius),
            ),
        ],
      ),
    );
  }

  Widget _seg(Color color, BorderRadius radius) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, borderRadius: radius),
    );
  }
}

class _QueueCount extends StatelessWidget {
  const _QueueCount({
    super.key,
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$count',
            style: AppTypeScale.ui14.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: ' $label',
            style: AppTypeScale.ui14.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({required this.page, required this.onTap});

  final HomeRecentEntry page;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final radius = BorderRadius.circular(AppRadius.card);
    final sentence = page.ocrPreview?.trim();
    final hasSentence = sentence != null && sentence.isNotEmpty;
    return Material(
      color: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: tokens.border),
      ),
      child: InkWell(
        key: HomeKeys.continueReading,
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const _Thumb(size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONTINUAR LENDO',
                      style: AppTypeScale.mono10.copyWith(
                        color: tokens.text3,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasSentence ? sentence : page.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: hasSentence
                          ? AppTypeScale.ui13.copyWith(
                              fontFamily: AppFonts.jp,
                              color: tokens.text,
                            )
                          : AppTypeScale.ui14.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: tokens.text3),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekRhythmCard extends StatelessWidget {
  const _WeekRhythmCard({required this.week});

  final HomeWeekRhythm week;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final max = week.maxCount < 1 ? 1 : week.maxCount;
    return Container(
      key: HomeKeys.weekRhythm,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ritmo da semana',
            style: AppTypeScale.ui14.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < week.days.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _WeekColumn(
                    day: week.days[i],
                    letter: HomeDates.weekdayLetters[i],
                    maxCount: max,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekColumn extends StatelessWidget {
  const _WeekColumn({
    required this.day,
    required this.letter,
    required this.maxCount,
  });

  final HomeWeekDay day;
  final String letter;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final fill = day.isToday
        ? tokens.coral
        : day.count > 0
        ? tokens.violet
        : tokens.surfaceLow;
    final height = day.count == 0
        ? 10.0
        : 10.0 + (28.0 * day.count / maxCount);
    return Column(
      children: [
        Container(
          height: height,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppRadius.segmentado),
            border: day.count == 0 && !day.isToday
                ? Border.all(color: tokens.border)
                : null,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          letter,
          style: AppTypeScale.metadados11.copyWith(
            color: day.isToday ? tokens.coral : tokens.text3,
            fontWeight: day.isToday ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _RecentCapturesBlock extends StatelessWidget {
  const _RecentCapturesBlock({
    required this.pages,
    required this.total,
    required this.now,
  });

  final List<HomeRecentEntry>? pages;
  final int? total;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final shown = pages?.length ?? 0;
    final all = total ?? shown;
    final countLabel = pages == null
        ? ''
        : all > shown
        ? '$shown de $all'
        : shown == 0
        ? ''
        : '$shown de $all';
    return Column(
      key: HomeKeys.recentCaptures,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Capturas recentes',
              style: AppTypeScale.ui14.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            if (countLabel.isNotEmpty)
              Text(
                countLabel,
                style: AppTypeScale.metadados12.copyWith(color: tokens.text3),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _body(context),
      ],
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
    return SizedBox(
      height: 132,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              SizedBox(
                width: 96,
                height: 132,
                child: _RecentThumb(
                  page: items[i],
                  number: i + 1,
                  now: now,
                  onTap: () => PageDetailRoute(id: items[i].id).go(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecentThumb extends StatelessWidget {
  const _RecentThumb({
    required this.page,
    required this.number,
    required this.now,
    required this.onTap,
  });

  final HomeRecentEntry page;
  final int number;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final radius = BorderRadius.circular(AppRadius.linha);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Material(
            color: tokens.surfaceRaised,
            borderRadius: radius,
            child: InkWell(
              key: HomeKeys.recentThumb(page.id),
              onTap: onTap,
              borderRadius: radius,
              child: Stack(
                children: [
                  const SizedBox.expand(child: _Thumb(size: 36)),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: _CropNumber(number: number),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          page.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypeScale.metadados12.copyWith(color: tokens.text),
        ),
        Text(
          HomeDates.relativeDay(page.createdAt, now),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypeScale.metadados11.copyWith(color: tokens.text3),
        ),
      ],
    );
  }
}

class _CropNumber extends StatelessWidget {
  const _CropNumber({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.coral,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        '$number',
        style: AppTypeScale.mono10.copyWith(
          color: tokens.onCoral,
          fontWeight: FontWeight.w700,
          fontSize: 9,
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.person_outline,
        size: size,
        color: context.tokens.text4,
      ),
    );
  }
}

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

class _DesktopCounts extends StatelessWidget {
  const _DesktopCounts({required this.counts});

  final HomeReviewCounts? counts;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final revisoes = counts?.revisoes ?? 0;
    final novos = counts?.novos ?? 0;
    final drill = counts?.drill ?? 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _DesktopCount(
            value: revisoes,
            label: 'para revisar',
            color: tokens.mint,
          ),
        ),
        Expanded(
          child: _DesktopCount(
            value: novos,
            label: 'novos',
            color: tokens.violet,
          ),
        ),
        Expanded(
          child: _DesktopCount(
            value: drill,
            label: 'drill',
            color: tokens.coral,
          ),
        ),
      ],
    );
  }
}

class _DesktopCount extends StatelessWidget {
  const _DesktopCount({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '$value',
            style: AppTypeScale.contagemBiblioteca.copyWith(
              color: color,
              height: 1,
              letterSpacing: -1.5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypeScale.ui14.copyWith(color: context.tokens.text3),
        ),
      ],
    );
  }
}

class _RecentPagesList extends StatelessWidget {
  const _RecentPagesList({required this.pages, required this.now});

  final List<HomeRecentEntry>? pages;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final items = pages;
    return Column(
      key: HomeKeys.recentPages,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PÁGINAS RECENTES',
          style: AppTypeScale.mono10.copyWith(
            color: tokens.text3,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        if (items == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (items.isEmpty)
          const Text('Nenhuma captura ainda.', key: HomeKeys.recentEmpty)
        else
          for (var i = 0; i < items.length && i < 3; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _RecentPageRow(
              page: items[i],
              index: i + 1,
              now: now,
              onTap: () => PageDetailRoute(id: items[i].id).go(context),
            ),
          ],
      ],
    );
  }
}

class _RecentPageRow extends StatelessWidget {
  const _RecentPageRow({
    required this.page,
    required this.index,
    required this.now,
    required this.onTap,
  });

  final HomeRecentEntry page;
  final int index;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final radius = BorderRadius.circular(AppRadius.linha);
    final recortes = page.cropCount == 1
        ? '1 recorte'
        : '${page.cropCount} recortes';
    final when = HomeDates.relativeDay(page.createdAt, now);
    return Material(
      color: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: tokens.border),
      ),
      child: InkWell(
        key: HomeKeys.recentPage(page.id),
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.menu_book_outlined, color: tokens.text3, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  page.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypeScale.ui14.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$recortes · $when',
                style: AppTypeScale.metadados12.copyWith(color: tokens.text3),
              ),
              const SizedBox(width: 10),
              KbdChip(label: '$index'),
            ],
          ),
        ),
      ),
    );
  }
}
