import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/routes.dart';
import '../../../core/shell/kbd_chip.dart';
import '../../../core/shell/shell_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/crop_number_badge.dart';
import '../../capture/presentation/gallery_import.dart';
import '../../review/domain/home_review_counts.dart';
import '../../review/domain/new_per_day.dart';
import '../domain/home_dates.dart';
import '../domain/home_recent_entry.dart';
import '../domain/home_week_rhythm.dart';
import 'home_controller.dart';

/// Keys for `/home` (Fila de hoje + Capturas recentes).
abstract final class HomeKeys {
  static const review = Key('home-review');
  static const due = Key('home-review-due');
  static const newToday = Key('home-review-new-today');
  static const novos = Key('home-queue-novos');
  static const revisoes = Key('home-queue-revisoes');
  static const drill = Key('home-queue-drill');
  static const recentCaptures = Key('home-recent-captures');
  static const recentEmpty = Key('home-recent-empty');
  static const title = Key('home-title');
  static const gallery = Key('home-gallery');
  static const galleryLink = Key('home-gallery-link');
  static const continueReading = Key('home-continue-reading');
  static const weekRhythm = Key('home-week-rhythm');
  static const queueBar = Key('home-queue-bar');

  static Key recentThumb(String pageId) => Key('home-recent-thumb-$pageId');
  static Key recentPage(String pageId) => Key('home-recent-page-$pageId');
}

/// `/home` — **Fila de hoje** / Biblioteca counts, then Continuar lendo,
/// Capturas recentes (gallery tile first), Ritmo da semana.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(homeReviewCountsProvider).value;
    final recent = ref.watch(homeRecentPagesProvider).asData?.value;
    final week = ref.watch(homeWeekRhythmProvider).asData?.value;
    final now = DateTime.now();
    void onGallery() => importFromGallery(context, ref);
    if (ShellLayout.isWide(context)) {
      return _DesktopHome(
        counts: counts,
        recent: recent,
        week: week,
        now: now,
        onGallery: onGallery,
      );
    }
    return _MobileHome(
      counts: counts,
      recent: recent,
      week: week,
      now: now,
      onGallery: onGallery,
    );
  }
}

class _MobileHome extends StatelessWidget {
  const _MobileHome({
    required this.counts,
    required this.recent,
    required this.week,
    required this.now,
    required this.onGallery,
  });

  final HomeReviewCounts? counts;
  final List<HomeRecentEntry>? recent;
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
      padding: ShellLayout.withSafePadding(
        context,
        const EdgeInsets.fromLTRB(16, 20, 16, 24),
      ),
      children: [
        const Text(
          'MangaJP',
          key: HomeKeys.title,
          style: AppTypeScale.tituloTela,
        ),
        const SizedBox(height: 4),
        Text(
          HomeDates.headerSubline(now),
          style: AppTypeScale.metadados12.copyWith(color: tokens.text3),
        ),
        const SizedBox(height: 20),
        _QueueCard(
          counts: counts,
          onTap: () => const ReviewRoute().push<void>(context),
        ),
        if (continuePage != null) ...[
          const SizedBox(height: 12),
          _ContinueReadingCard(
            page: continuePage,
            onTap: () =>
                PageDetailRoute(id: continuePage.id).push<void>(context),
          ),
        ],
        const SizedBox(height: 20),
        _RecentCapturesBlock(
          pages: recent,
          now: now,
          onGallery: onGallery,
          wide: false,
        ),
        if (week != null) ...[
          const SizedBox(height: 12),
          _WeekRhythmCard(week: week!),
        ],
      ],
    );
  }
}

class _DesktopHome extends StatelessWidget {
  const _DesktopHome({
    required this.counts,
    required this.recent,
    required this.week,
    required this.now,
    required this.onGallery,
  });

  final HomeReviewCounts? counts;
  final List<HomeRecentEntry>? recent;
  final HomeWeekRhythm? week;
  final DateTime now;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final continuePage = recent == null || recent!.isEmpty
        ? null
        : recent!.first;
    return ListView(
      padding: ShellLayout.withSafePadding(
        context,
        const EdgeInsets.fromLTRB(48, 36, 48, 24),
      ),
      children: [
        _DesktopCounts(counts: counts),
        if (continuePage != null) ...[
          const SizedBox(height: 28),
          _ContinueReadingCard(
            page: continuePage,
            onTap: () =>
                PageDetailRoute(id: continuePage.id).push<void>(context),
          ),
        ],
        const SizedBox(height: 28),
        _RecentCapturesBlock(
          pages: recent,
          now: now,
          onGallery: onGallery,
          wide: true,
        ),
        if (week != null) ...[
          const SizedBox(height: 28),
          _WeekRhythmCard(week: week!),
        ],
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
                        label: 'novos · limite ${NewPerDay.limit}/dia',
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
        key: HomeKeys.queueBar,
        height: height,
        decoration: BoxDecoration(
          color: tokens.surfaceLow,
          borderRadius: radius,
        ),
      );
    }
    return SizedBox(
      key: HomeKeys.queueBar,
      height: height,
      child: Row(
        children: [
          if (novos > 0)
            Expanded(flex: novos, child: _seg(tokens.queueNovos, radius)),
          if (novos > 0 && (revisoes > 0 || drill > 0))
            const SizedBox(width: 3),
          if (revisoes > 0)
            Expanded(flex: revisoes, child: _seg(tokens.queueRevisoes, radius)),
          if (revisoes > 0 && drill > 0) const SizedBox(width: 3),
          if (drill > 0)
            Expanded(flex: drill, child: _seg(tokens.queueDrill, radius)),
        ],
      ),
    );
  }

  Widget _seg(Color color, BorderRadius radius) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, borderRadius: radius),
      child: const SizedBox.expand(),
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
    final height = day.count == 0 ? 10.0 : 10.0 + (28.0 * day.count / maxCount);
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
    required this.now,
    required this.onGallery,
    required this.wide,
  });

  final List<HomeRecentEntry>? pages;
  final DateTime now;
  final VoidCallback onGallery;
  final bool wide;

  static const _tileSize = Size(96, 132);
  static const _gridGap = 12.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: HomeKeys.recentCaptures,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Capturas recentes',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypeScale.ui14.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            _GalleryHeaderLink(onTap: onGallery, showShortcut: wide),
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
    final tiles = <Widget>[
      SizedBox(
        key: items.isEmpty ? HomeKeys.recentEmpty : null,
        width: _tileSize.width,
        height: _tileSize.height,
        child: _GalleryTile(onTap: onGallery),
      ),
      for (var i = 0; i < items.length; i++)
        SizedBox(
          width: _tileSize.width,
          height: _tileSize.height,
          child: _RecentThumb(
            page: items[i],
            number: i + 1,
            now: now,
            onTap: () => PageDetailRoute(id: items[i].id).push<void>(context),
          ),
        ),
    ];
    if (wide) {
      return Wrap(spacing: _gridGap, runSpacing: _gridGap, children: tiles);
    }
    return SizedBox(
      height: _tileSize.height,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              tiles[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _GalleryHeaderLink extends StatelessWidget {
  const _GalleryHeaderLink({required this.onTap, required this.showShortcut});

  final VoidCallback onTap;
  final bool showShortcut;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return InkWell(
      key: HomeKeys.galleryLink,
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.tecla),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Galeria +',
              style: AppTypeScale.ui13.copyWith(
                color: tokens.coral,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showShortcut) ...[
              const SizedBox(width: 8),
              const KbdChip(label: 'G'),
            ],
          ],
        ),
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final radius = BorderRadius.circular(AppRadius.linha);
    return Material(
      color: tokens.coral.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: HomeKeys.gallery,
        onTap: onTap,
        borderRadius: radius,
        child: CustomPaint(
          painter: DashedRRectPainter(
            color: tokens.coral,
            radius: AppRadius.linha,
            strokeWidth: 1.5,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  color: tokens.coral,
                  size: AppIcons.sizeMax,
                ),
                const SizedBox(height: 6),
                Text(
                  '+ Nova da galeria',
                  textAlign: TextAlign.center,
                  style: AppTypeScale.metadados12.copyWith(color: tokens.coral),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashed 1.5px coral stroke for the Home gallery tile.
class DashedRRectPainter extends CustomPainter {
  const DashedRRectPainter({
    required this.color,
    required this.radius,
    this.strokeWidth = 1.5,
    this.dashOn = 5,
    this.dashOff = 4,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashOn;
  final double dashOff;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      var draw = true;
      while (dist < metric.length) {
        final span = draw ? dashOn : dashOff;
        final next = dist + span > metric.length ? metric.length : dist + span;
        if (draw) {
          canvas.drawPath(metric.extractPath(dist, next), paint);
        }
        dist = next;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashOn != dashOn ||
        oldDelegate.dashOff != dashOff;
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
                    child: CropNumberBadge(number: number, neutral: true),
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

class _DesktopCounts extends StatelessWidget {
  const _DesktopCounts({required this.counts});

  final HomeReviewCounts? counts;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final waiting = counts?.waiting ?? 0;
    final novos = counts?.novos ?? 0;
    final revisoes = counts?.revisoes ?? 0;
    final drill = counts?.drill ?? 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _DesktopCount(
            key: HomeKeys.due,
            value: waiting,
            label: 'para revisar',
            color: tokens.text,
          ),
        ),
        Expanded(
          child: _DesktopCount(
            key: HomeKeys.novos,
            value: novos,
            label: 'novos',
            color: tokens.violet,
          ),
        ),
        Expanded(
          child: _DesktopCount(
            key: HomeKeys.revisoes,
            value: revisoes,
            label: 'revisões',
            color: tokens.mint,
          ),
        ),
        Expanded(
          child: _DesktopCount(
            key: HomeKeys.drill,
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
    super.key,
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
