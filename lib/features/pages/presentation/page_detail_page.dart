import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/copy/recortes_label.dart';
import '../../../core/router/routes.dart';
import '../../../core/shell/shell_layout.dart';
import '../../../core/shell/shell_nav.dart';
import '../../../core/shell/shell_registry.dart';
import '../../../core/shell/task_dock.dart';
import '../../../core/theme/app_theme.dart';
import '../../dictionary/data/jmdict_provider.dart';
import '../../dictionary/domain/dict_entry.dart';
import '../../dictionary/domain/lookup_result.dart';
import '../../dictionary/presentation/lookup_sheet.dart';
import '../../flashcards/data/flashcards_repository.dart';
import '../../words/data/words_repository.dart';
import '../../words/domain/word_state.dart';
import '../../words/domain/word_state_index.dart';
import '../data/pages_repository.dart';
import '../domain/page_crop.dart';
import '../domain/page_labels.dart';
import 'ocr_char_index.dart';
import 'ocr_token_spans.dart';
import 'page_detail_controller.dart';

/// Keys for `/pages/:id` OCR text (persisted Drift `crops.ocr_text`).
abstract final class PageDetailKeys {
  static const ocrText = Key('page-detail-ocr-text');
  static const edit = Key('page-detail-edit');
  static const add = Key('page-detail-add');
  static const ocrEditor = Key('page-detail-ocr-editor');
  static const ocrEditorSave = Key('page-detail-ocr-editor-save');
}

class _TouchRange {
  const _TouchRange({
    required this.cropId,
    required this.start,
    required this.end,
  });

  final String cropId;
  final int start;
  final int end;
}

class _LookupSession {
  const _LookupSession({
    required this.crop,
    required this.surface,
    required this.start,
    required this.end,
    required this.wordState,
    this.result,
  });

  final PageCrop crop;
  final String surface;
  final int start;
  final int end;
  final WordState wordState;
  final LookupResult? result;

  bool get isCustom => result == null;
}

/// `/pages/:id` — OCR text; tap looks up JMdict; state actions persist the word.
class PageDetailPage extends ConsumerStatefulWidget {
  const PageDetailPage({super.key, required this.pageId});

  final String pageId;

  @override
  ConsumerState<PageDetailPage> createState() => _PageDetailPageState();
}

class _PageDetailPageState extends ConsumerState<PageDetailPage> {
  _TouchRange? _touch;
  _LookupSession? _session;
  bool _lookupLoading = false;
  String? _lookupError;
  bool _didAutoLookup = false;

  @override
  Widget build(BuildContext context) {
    final crops = ref.watch(pageCropsProvider(widget.pageId));
    final wide = ShellLayout.isWide(context);
    final items = crops.asData?.value ?? const <PageCrop>[];
    final count = items.length;
    final hint = count == 0 ? null : RecortesLabel.count(count);
    final task = ShellTask(
      meta: widget.pageId,
      metaHint: hint,
      actions: [
        ShellAction(
          id: 'back',
          label: PageLabels.voltar,
          icon: Icons.chevron_left,
          onPressed: () => popTaskOrHome(context),
        ),
        ShellAction(
          id: 'edit',
          label: PageLabels.editar,
          icon: Icons.edit_outlined,
          enabled: items.isNotEmpty,
          onPressed: () => _editOcr(items),
        ),
        ShellAction(
          id: 'add',
          label: '+',
          icon: Icons.add,
          onPressed: () => const CaptureRoute().push<void>(context),
        ),
      ],
    );

    final body = crops.when(
      data: (list) {
        _maybeAutoLookup(list);
        return _PageOcrBody(
          crops: list,
          touch: _touch,
          onTapCharacter: (crop, index) => _lookup(crop, index),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '$error',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.tokens.coral),
          ),
        ),
      ),
    );

    return ShellBinder(
      task: task,
      child: Column(
        children: [
          Expanded(
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: body),
                      _LookupDrawer(
                        loading: _lookupLoading,
                        error: _lookupError,
                        session: _session,
                        onAction: _applyLookup,
                        onCustomAction: _applyCustomLookup,
                      ),
                    ],
                  )
                : body,
          ),
          if (!wide)
            TaskDock(
              meta: widget.pageId,
              metaHint: hint,
              leading: [
                DockIconButton(
                  key: ShellKeys.dockAction('back'),
                  icon: Icons.chevron_left,
                  tooltip: PageLabels.voltar,
                  onPressed: () => popTaskOrHome(context),
                ),
              ],
              trailing: [
                DockIconButton(
                  key: PageDetailKeys.edit,
                  icon: Icons.edit_outlined,
                  tooltip: PageLabels.editar,
                  enabled: items.isNotEmpty,
                  onPressed: () => _editOcr(items),
                ),
                DockIconButton(
                  key: PageDetailKeys.add,
                  icon: Icons.add,
                  tooltip: PageLabels.adicionar,
                  onPressed: () => const CaptureRoute().push<void>(context),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _maybeAutoLookup(List<PageCrop> crops) {
    if (!kPageShotLookup || _didAutoLookup || crops.isEmpty) {
      return;
    }
    _didAutoLookup = true;
    final crop = crops.first;
    final index = crop.ocrText.indexOf('食べ');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _lookup(crop, index < 0 ? 0 : index);
    });
  }

  Future<void> _lookup(PageCrop crop, int tapIndex) async {
    final startGuess = tapIndex < 0
        ? 0
        : (tapIndex >= crop.ocrText.length
              ? crop.ocrText.length - 1
              : tapIndex);
    setState(() {
      _lookupLoading = true;
      _lookupError = null;
      _touch = _TouchRange(
        cropId: crop.id,
        start: startGuess,
        end: startGuess + 1,
      );
    });
    try {
      final lookup = await ref.read(dictionaryLookupProvider.future);
      final states = await ref.read(listedWordStatesProvider.future);
      if (!mounted) {
        return;
      }
      final result = lookup.findAt(crop.ocrText, tapIndex: tapIndex);
      if (result != null) {
        final session = _LookupSession(
          crop: crop,
          surface: result.surface,
          start: result.start,
          end: result.end,
          wordState: states.ofSeq(result.selected.seq),
          result: result,
        );
        setState(() {
          _lookupLoading = false;
          _session = session;
          _touch = _TouchRange(
            cropId: crop.id,
            start: result.start,
            end: result.end,
          );
        });
        if (!ShellLayout.isWide(context)) {
          await showLookupSheet(
            context,
            result: result,
            sentence: crop.ocrText,
            wordState: session.wordState,
            onAction: (action, entry) => _applyLookup(session, action, entry),
          );
          if (mounted) {
            setState(() {
              _session = null;
              _touch = null;
            });
          }
        }
        return;
      }
      final miss = lookup.missAt(crop.ocrText, tapIndex: tapIndex);
      if (miss == null) {
        setState(() {
          _lookupLoading = false;
          _session = null;
        });
        if (!ShellLayout.isWide(context)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhuma entrada no dicionário.')),
          );
        } else {
          setState(() => _lookupError = 'Nenhuma entrada no dicionário.');
        }
        return;
      }
      final session = _LookupSession(
        crop: crop,
        surface: miss.surface,
        start: miss.start,
        end: miss.end,
        wordState: states.ofLemma(miss.surface),
      );
      setState(() {
        _lookupLoading = false;
        _session = session;
        _touch = _TouchRange(cropId: crop.id, start: miss.start, end: miss.end);
      });
      if (!ShellLayout.isWide(context)) {
        await showCustomLookupSheet(
          context,
          surface: miss.surface,
          sentence: crop.ocrText,
          highlightStart: miss.start,
          highlightEnd: miss.end,
          wordState: session.wordState,
          onAction: (action, note) => _applyCustomLookup(session, action, note),
        );
        if (mounted) {
          setState(() {
            _session = null;
            _touch = null;
          });
        }
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _lookupLoading = false;
        _lookupError = '$error';
      });
      if (!ShellLayout.isWide(context)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${PageLabels.dicionarioIndisponivel}: $error'),
          ),
        );
      }
    }
  }

  Future<void> _applyLookup(
    _LookupSession session,
    LookupAction action,
    DictEntry entry,
  ) {
    return _commit(
      session: session,
      action: action,
      save: () {
        return ref
            .read(wordsRepositoryProvider)
            .saveFromLookup(
              cropId: session.crop.id,
              seq: entry.seq,
              lemma: entry.lemma,
              reading: entry.reading,
            );
      },
    );
  }

  Future<void> _applyCustomLookup(
    _LookupSession session,
    LookupAction action,
    String userNote,
  ) {
    return _commit(
      session: session,
      action: action,
      save: () {
        return ref
            .read(wordsRepositoryProvider)
            .saveCustomFromLookup(
              cropId: session.crop.id,
              surface: session.surface,
              userNote: userNote,
            );
      },
    );
  }

  Future<void> _commit({
    required _LookupSession session,
    required LookupAction action,
    required Future<String> Function() save,
  }) async {
    final wordId = await save();
    final cards = ref.read(flashcardsRepositoryProvider);
    switch (action) {
      case LookupAction.save:
        break;
      case LookupAction.learn:
        await cards.learn(wordId);
      case LookupAction.known:
        await cards.markKnown(wordId);
      case LookupAction.ignore:
        await cards.markIgnored(wordId);
    }
    ref.invalidate(listedWordStatesProvider);
    if (!mounted) {
      return;
    }
    final next = switch (action) {
      LookupAction.save => WordState.saved,
      LookupAction.learn => WordState.learning,
      LookupAction.known => WordState.known,
      LookupAction.ignore => WordState.ignored,
    };
    // Save on a protected word leaves learning/known/ignored as-is.
    final shown = session.wordState.isProtected && action == LookupAction.save
        ? session.wordState
        : next;
    setState(() {
      _session = _LookupSession(
        crop: session.crop,
        surface: session.surface,
        start: session.start,
        end: session.end,
        wordState: shown,
        result: session.result,
      );
    });
  }

  Future<void> _editOcr(List<PageCrop> crops) async {
    if (crops.isEmpty) {
      return;
    }
    final controllers = [
      for (final crop in crops) TextEditingController(text: crop.ocrText),
    ];
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          key: PageDetailKeys.ocrEditor,
          title: const Text(PageLabels.editarOcrTitulo),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < crops.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    TextField(
                      controller: controllers[i],
                      minLines: 2,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText: '${PageLabels.recorteN} ${i + 1}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              key: PageDetailKeys.ocrEditorSave,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(PageLabels.salvarOcr),
            ),
          ],
        );
      },
    );
    final texts = [for (final controller in controllers) controller.text];
    for (final controller in controllers) {
      controller.dispose();
    }
    if (saved != true || !mounted) {
      return;
    }
    final repo = ref.read(pagesRepositoryProvider);
    for (var i = 0; i < crops.length; i++) {
      await repo.updateCropOcr(cropId: crops[i].id, ocrText: texts[i]);
    }
    ref.invalidate(pageCropsProvider(widget.pageId));
  }
}

class _PageOcrBody extends ConsumerWidget {
  const _PageOcrBody({
    required this.crops,
    required this.onTapCharacter,
    this.touch,
  });

  final List<PageCrop> crops;
  final _TouchRange? touch;
  final void Function(PageCrop crop, int index) onTapCharacter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (crops.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            PageLabels.nenhumOcr,
            textAlign: TextAlign.center,
            style: AppTypeScale.ui14.copyWith(color: context.tokens.text2),
          ),
        ),
      );
    }

    final lookup = ref.watch(dictionaryLookupProvider).asData?.value;
    final states =
        ref.watch(listedWordStatesProvider).asData?.value ??
        WordStateIndex.empty;
    final tokens = context.tokens;
    final wide = ShellLayout.isWide(context);
    final style = wide
        ? AppTypeScale.fraseLeitorDesktopJp
        : AppTypeScale.balaoPaginaMobileJp;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        for (final crop in crops)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: tokens.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
                side: BorderSide(color: tokens.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _TappableOcrText(
                  text: crop.ocrText,
                  style: style,
                  tokens: tokens,
                  spans: lookup == null
                      ? const []
                      : tokenizeOcr(crop.ocrText, lookup, states),
                  touchStart: touch?.cropId == crop.id ? touch!.start : null,
                  touchEnd: touch?.cropId == crop.id ? touch!.end : null,
                  onTapCharacter: (index) => onTapCharacter(crop, index),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// OCR string; tap position maps to a UTF-16 index for longest-cover lookup.
class _TappableOcrText extends StatefulWidget {
  const _TappableOcrText({
    required this.text,
    required this.style,
    required this.tokens,
    required this.spans,
    required this.onTapCharacter,
    this.touchStart,
    this.touchEnd,
  });

  final String text;
  final TextStyle style;
  final MangaJpTokens tokens;
  final List<OcrTokenSpan> spans;
  final int? touchStart;
  final int? touchEnd;
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
    return Center(
      child: GestureDetector(
        onTapDown: _onTapDown,
        child: Text.rich(
          _span(),
          key: PageDetailKeys.ocrText,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  TextSpan _span() {
    final base = widget.style;
    final spans = widget.spans;
    if (spans.isEmpty) {
      return TextSpan(text: widget.text, style: base);
    }
    return TextSpan(
      style: base,
      children: [
        for (final token in spans)
          TextSpan(
            text: widget.text.substring(token.start, token.end),
            style: base.copyWith(
              color: widget.tokens.wordState(token.state.name),
              backgroundColor: _touched(token)
                  ? widget.tokens.overlaySelecaoToque
                  : null,
            ),
          ),
      ],
    );
  }

  bool _touched(OcrTokenSpan token) {
    final start = widget.touchStart;
    final end = widget.touchEnd;
    if (start == null || end == null) {
      return false;
    }
    return token.start < end && token.end > start;
  }
}

class _LookupDrawer extends StatelessWidget {
  const _LookupDrawer({
    required this.loading,
    required this.error,
    required this.session,
    required this.onAction,
    required this.onCustomAction,
  });

  final bool loading;
  final String? error;
  final _LookupSession? session;
  final Future<void> Function(
    _LookupSession session,
    LookupAction action,
    DictEntry entry,
  )
  onAction;
  final Future<void> Function(
    _LookupSession session,
    LookupAction action,
    String userNote,
  )
  onCustomAction;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final body = _body(context, tokens);
    return Material(
      color: tokens.bg,
      child: Container(
        key: LookupSheetKeys.drawer,
        width: PageLayout.lookupDrawerWidth,
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: tokens.border)),
        ),
        child: body,
      ),
    );
  }

  Widget _body(BuildContext context, MangaJpTokens tokens) {
    final session = this.session;
    if (loading) {
      return const Center(
        key: LookupSheetKeys.loading,
        child: CircularProgressIndicator(),
      );
    }
    if (error != null && session == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            error!,
            key: LookupSheetKeys.error,
            textAlign: TextAlign.center,
            style: AppTypeScale.ui14.copyWith(color: tokens.coral),
          ),
        ),
      );
    }
    if (session == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            PageLabels.toquePalavra,
            key: LookupSheetKeys.empty,
            textAlign: TextAlign.center,
            style: AppTypeScale.ui14.copyWith(color: tokens.text3),
          ),
        ),
      );
    }
    final result = session.result;
    if (result == null) {
      return LookupSheet.custom(
        surface: session.surface,
        sentence: session.crop.ocrText,
        highlightStart: session.start,
        highlightEnd: session.end,
        wordState: session.wordState,
        onCustomAction: (action, note) => onCustomAction(session, action, note),
      );
    }
    return LookupSheet(
      result: result,
      sentence: session.crop.ocrText,
      highlightStart: session.start,
      highlightEnd: session.end,
      wordState: session.wordState,
      onAction: (action, entry) => onAction(session, action, entry),
    );
  }
}
