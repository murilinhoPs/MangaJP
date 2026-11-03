import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/routes.dart';
import '../../../core/shell/shell_layout.dart';
import '../../../core/shell/shell_nav.dart';
import '../../../core/theme/app_theme.dart';
import '../../capture/presentation/gallery_import.dart';
import '../domain/page_labels.dart';
import '../domain/page_list_date.dart';
import '../domain/page_list_entry.dart';
import 'pages_list_controller.dart';

/// Keys for `/pages` (history list + empty + gallery).
abstract final class PagesKeys {
  static const list = Key('pages-list');
  static const empty = Key('pages-empty');
  static const gallery = Key('pages-gallery');
  static const title = Key('pages-title');
  static const back = Key('pages-back');

  static Key row(String pageId) => Key('pages-row-$pageId');

  static Key thumb(String pageId) => Key('pages-thumb-$pageId');
}

/// `/pages` — full capture history with thumbnail, title, and date per row.
class PagesListPage extends ConsumerWidget {
  const PagesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pages = ref.watch(pagesListProvider);
    final wide = ShellLayout.isWide(context);
    final padH = wide ? 48.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            wide ? padH + MediaQuery.paddingOf(context).left : 4,
            (wide ? 24.0 : 4.0) + MediaQuery.paddingOf(context).top,
            padH + MediaQuery.paddingOf(context).right,
            0,
          ),
          child: Row(
            children: [
              if (!wide)
                BackButton(
                  key: PagesKeys.back,
                  onPressed: () => popTaskOrHome(context),
                ),
              const Expanded(
                child: Text(
                  PageLabels.pagesTitle,
                  key: PagesKeys.title,
                  style: AppTypeScale.tituloTela,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: pages.when(
            data: (items) => items.isEmpty
                ? _PagesEmpty(wide: wide)
                : _PagesList(entries: items, wide: wide),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  PageLabels.loadError,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PagesList extends StatelessWidget {
  const _PagesList({required this.entries, required this.wide});

  final List<PageListEntry> entries;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final padH = wide ? 48.0 : 16.0;
    final now = DateTime.now();
    return ListView.separated(
      key: PagesKeys.list,
      padding: ShellLayout.withCommandBarPadding(
        context,
        EdgeInsets.fromLTRB(padH, 16, padH, wide ? 32 : 16),
      ),
      itemCount: entries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _PageRow(entry: entries[index], now: now, wide: wide);
      },
    );
  }
}

class _PageRow extends StatelessWidget {
  const _PageRow({
    required this.entry,
    required this.now,
    required this.wide,
  });

  final PageListEntry entry;
  final DateTime now;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final radius = BorderRadius.circular(AppRadius.linha);
    final thumbSize = wide ? const Size(72, 96) : const Size(56, 76);
    return Material(
      color: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: tokens.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: PagesKeys.row(entry.id),
        onTap: () => PageDetailRoute(id: entry.id).push<void>(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          child: Row(
            children: [
              _PageThumb(
                key: PagesKeys.thumb(entry.id),
                size: thumbSize,
                preview: entry.ocrPreview,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypeScale.ui14.copyWith(
                        fontFamily: AppFonts.jp,
                        fontWeight: FontWeight.w600,
                        color: tokens.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      PageListDate.format(entry.createdAt, now),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypeScale.metadados11.copyWith(
                        color: tokens.text3,
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

/// Page-shaped tile. OCR snippet stands in for `pages.thumb_path` (not in v9).
class _PageThumb extends StatelessWidget {
  const _PageThumb({
    super.key,
    required this.size,
    required this.preview,
  });

  final Size size;
  final String? preview;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = preview?.trim();
    final snippet = text == null || text.isEmpty
        ? null
        : text.split('\n').first.trim();
    return SizedBox(
      width: size.width,
      height: size.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadius.segmentado),
          border: Border.all(color: tokens.border),
        ),
        child: snippet == null
            ? Icon(
                Icons.auto_stories_outlined,
                size: AppIcons.sizeMax,
                color: tokens.text4,
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
                child: Text(
                  snippet,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypeScale.metadados11.copyWith(
                    fontFamily: AppFonts.jp,
                    color: tokens.text2,
                    height: 1.3,
                  ),
                ),
              ),
      ),
    );
  }
}

class _PagesEmpty extends ConsumerWidget {
  const _PagesEmpty({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IgnorePointer(
                child: Text(
                  PageLabels.watermark,
                  style:
                      (wide
                              ? AppTypeScale.reviewDesktopJp
                              : AppTypeScale.reviewMobileJp)
                          .copyWith(
                            color: tokens.text4.withValues(alpha: 0.35),
                            height: 1,
                          ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                PageLabels.empty,
                key: PagesKeys.empty,
                textAlign: TextAlign.center,
                style: AppTypeScale.tituloTela.copyWith(color: tokens.text),
              ),
              const SizedBox(height: 8),
              Text(
                PageLabels.emptyHint,
                textAlign: TextAlign.center,
                style: AppTypeScale.ui14.copyWith(color: tokens.text3),
              ),
              const SizedBox(height: 16),
              TextButton(
                key: PagesKeys.gallery,
                onPressed: () => importFromGallery(context, ref),
                child: Text(
                  PageLabels.gallery,
                  style: AppTypeScale.ui13.copyWith(
                    color: tokens.coral,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
