import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/page_crop.dart';
import 'page_detail_controller.dart';

/// Keys for `/pages/:id` OCR text (persisted Drift `crops.ocr_text`).
abstract final class PageDetailKeys {
  static const ocrText = Key('page-detail-ocr-text');
}

/// `/pages/:id` — shows OCR text already saved on the page's crops (M1.2).
class PageDetailPage extends ConsumerWidget {
  const PageDetailPage({super.key, required this.pageId});

  final String pageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crops = ref.watch(pageCropsProvider(pageId));

    return crops.when(
      data: (items) => _PageOcrBody(crops: items),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '$error',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }
}

class _PageOcrBody extends StatelessWidget {
  const _PageOcrBody({required this.crops});

  final List<PageCrop> crops;

  @override
  Widget build(BuildContext context) {
    if (crops.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nenhum texto OCR nesta página.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final crop in crops)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                crop.ocrText,
                key: PageDetailKeys.ocrText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
      ],
    );
  }
}
