import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/shell/shell_layout.dart';
import '../../../core/shell/shell_nav.dart';
import '../../../core/shell/shell_registry.dart';
import '../../../core/shell/task_dock.dart';
import '../../../core/theme/app_theme.dart';
import '../../dictionary/data/jmdict_provider.dart';
import '../../dictionary/presentation/lookup_sheet.dart';
import '../../words/data/words_repository.dart';
import '../domain/page_crop.dart';
import 'ocr_char_index.dart';
import 'page_detail_controller.dart';

/// Keys for `/pages/:id` OCR text (persisted Drift `crops.ocr_text`).
abstract final class PageDetailKeys {
  static const ocrText = Key('page-detail-ocr-text');
}

/// `/pages/:id` — OCR text from Drift; tap looks up JMdict; Save persists the word.
class PageDetailPage extends ConsumerWidget {
  const PageDetailPage({super.key, required this.pageId});

  final String pageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crops = ref.watch(pageCropsProvider(pageId));
    final wide = ShellLayout.isWide(context);
    final count = crops.asData?.value.length ?? 0;
    final hint = count == 0 ? null : '$count recortes';
    final task = ShellTask(
      meta: pageId,
      metaHint: hint,
      actions: [
        ShellAction(
          id: 'back',
          label: 'Voltar',
          icon: Icons.chevron_left,
          onPressed: () => popTaskOrHome(context),
        ),
      ],
    );

    return ShellBinder(
      task: task,
      child: Column(
        children: [
          Expanded(
            child: crops.when(
              data: (items) => _PageOcrBody(crops: items),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    '$error',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (!wide)
            TaskDock(
              meta: pageId,
              metaHint: hint,
              leading: [
                DockIconButton(
                  key: ShellKeys.dockAction('back'),
                  icon: Icons.chevron_left,
                  tooltip: 'Voltar',
                  onPressed: () => popTaskOrHome(context),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PageOcrBody extends ConsumerWidget {
  const _PageOcrBody({required this.crops});

  final List<PageCrop> crops;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              child: _TappableOcrText(
                text: crop.ocrText,
                onTapCharacter: (index) {
                  _lookup(context, ref, crop, index);
                },
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _lookup(
    BuildContext context,
    WidgetRef ref,
    PageCrop crop,
    int tapIndex,
  ) async {
    try {
      final lookup = await ref.read(dictionaryLookupProvider.future);
      final result = lookup.findAt(crop.ocrText, tapIndex: tapIndex);
      if (!context.mounted) {
        return;
      }
      if (result != null) {
        await showLookupSheet(
          context,
          result,
          onSave: (entry) {
            return ref
                .read(wordsRepositoryProvider)
                .saveFromLookup(
                  cropId: crop.id,
                  seq: entry.seq,
                  lemma: entry.lemma,
                  reading: entry.reading,
                );
          },
        );
        return;
      }
      final surface = lookup.missSurface(crop.ocrText, tapIndex: tapIndex);
      if (surface == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma entrada no dicionário.')),
        );
        return;
      }
      await showCustomLookupSheet(
        context,
        surface: surface,
        onSave: (userNote) {
          return ref
              .read(wordsRepositoryProvider)
              .saveCustomFromLookup(
                cropId: crop.id,
                surface: surface,
                userNote: userNote,
              );
        },
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dicionário indisponível: $error')),
      );
    }
  }
}

/// OCR string; tap position maps to a UTF-16 index for longest-cover lookup.
class _TappableOcrText extends StatefulWidget {
  const _TappableOcrText({required this.text, required this.onTapCharacter});

  final String text;
  final ValueChanged<int> onTapCharacter;

  @override
  State<_TappableOcrText> createState() => _TappableOcrTextState();
}

class _TappableOcrTextState extends State<_TappableOcrText> {
  void _onTapDown(TapDownDetails details) {
    final text = widget.text;
    if (text.isEmpty) {
      return;
    }
    final paragraph = _paragraph();
    if (paragraph == null) {
      return;
    }
    final local = paragraph.globalToLocal(details.globalPosition);
    final index = charIndexAt(paragraph, local);
    if (index == null) {
      return;
    }
    widget.onTapCharacter(index);
  }

  /// The laid-out [Text], including wrap and `textAlign`. A separate
  /// [TextPainter.layout] without `maxWidth` would measure one line.
  RenderParagraph? _paragraph() {
    RenderParagraph? found;
    void walk(RenderObject node) {
      if (found != null) {
        return;
      }
      if (node is RenderParagraph) {
        found = node;
        return;
      }
      node.visitChildren(walk);
    }

    final root = context.findRenderObject();
    if (root != null) {
      walk(root);
    }
    return found;
  }

  @override
  Widget build(BuildContext context) {
    const style = AppTypeScale.balaoPaginaMobileJp;
    return Center(
      child: GestureDetector(
        onTapDown: _onTapDown,
        child: Text(
          widget.text,
          key: PageDetailKeys.ocrText,
          textAlign: TextAlign.center,
          style: style,
        ),
      ),
    );
  }
}
