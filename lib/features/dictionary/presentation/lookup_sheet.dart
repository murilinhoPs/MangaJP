import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/shell/kbd_chip.dart';
import '../../../core/shell/shell_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../pages/domain/page_labels.dart';
import '../../words/domain/word_state.dart';
import '../domain/dict_entry.dart';
import '../domain/lookup_result.dart';

/// Keys for the lookup sheet (gloss + state actions; custom note when JMdict misses).
abstract final class LookupSheetKeys {
  static const sheet = Key('lookup-sheet');
  static const modal = Key('lookup-modal');
  static const drawer = Key('lookup-drawer');
  static const phrase = Key('lookup-phrase');
  static const gloss = Key('lookup-gloss');
  static const miss = Key('lookup-miss');
  static const note = Key('lookup-note');
  static const save = Key('lookup-save');
  static const learn = Key('lookup-learn');
  static const known = Key('lookup-known');
  static const ignore = Key('lookup-ignore');
  static const empty = Key('lookup-empty');
  static const loading = Key('lookup-loading');
  static const error = Key('lookup-error');

  static Key option(int seq) => Key('lookup-option-$seq');
}

enum LookupAction { learn, known, ignore, save }

Future<void> showLookupSheet(
  BuildContext context, {
  required LookupResult result,
  required String sentence,
  required WordState wordState,
  required Future<void> Function(LookupAction action, DictEntry selected)
  onAction,
}) {
  final height =
      MediaQuery.sizeOf(context).height * PageLayout.lookupSheetFraction;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheetReview),
      ),
    ),
    builder: (context) => SizedBox(
      key: LookupSheetKeys.modal,
      height: height,
      child: LookupSheet(
        result: result,
        sentence: sentence,
        highlightStart: result.start,
        highlightEnd: result.end,
        wordState: wordState,
        popOnAction: true,
        onAction: onAction,
      ),
    ),
  );
}

Future<void> showCustomLookupSheet(
  BuildContext context, {
  required String surface,
  required String sentence,
  required int highlightStart,
  required int highlightEnd,
  required WordState wordState,
  required Future<void> Function(LookupAction action, String userNote) onAction,
}) {
  final height =
      MediaQuery.sizeOf(context).height * PageLayout.lookupSheetFraction;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheetReview),
      ),
    ),
    builder: (context) => SizedBox(
      key: LookupSheetKeys.modal,
      height: height,
      child: LookupSheet.custom(
        surface: surface,
        sentence: sentence,
        highlightStart: highlightStart,
        highlightEnd: highlightEnd,
        wordState: wordState,
        popOnAction: true,
        onCustomAction: onAction,
      ),
    ),
  );
}

/// Homograph list + selected entry gloss (default = highest `forms.priority`).
///
/// [LookupSheet.custom] is the no-JMdict path: required [userNote], no gloss.
class LookupSheet extends StatefulWidget {
  LookupSheet({
    super.key,
    required LookupResult result,
    required this.sentence,
    required this.highlightStart,
    required this.highlightEnd,
    required this.wordState,
    required this.onAction,
    this.popOnAction = false,
  }) : result = result,
       surface = result.surface,
       onCustomAction = null;

  const LookupSheet.custom({
    super.key,
    required this.surface,
    required this.sentence,
    required this.highlightStart,
    required this.highlightEnd,
    required this.wordState,
    required this.onCustomAction,
    this.popOnAction = false,
  }) : result = null,
       onAction = null;

  final LookupResult? result;
  final String surface;
  final String sentence;
  final int highlightStart;
  final int highlightEnd;
  final WordState wordState;
  final bool popOnAction;
  final Future<void> Function(LookupAction action, DictEntry selected)?
  onAction;
  final Future<void> Function(LookupAction action, String userNote)?
  onCustomAction;

  @override
  State<LookupSheet> createState() => _LookupSheetState();
}

class _LookupSheetState extends State<LookupSheet> {
  late int? _selectedSeq;
  bool _saving = false;
  final _note = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedSeq = widget.result?.selectedSeq;
    _note.addListener(_onNoteChanged);
  }

  @override
  void dispose() {
    _note.removeListener(_onNoteChanged);
    _note.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onNoteChanged() => setState(() {});

  bool get _isCustom => widget.result == null;

  DictEntry get _selected =>
      widget.result!.entries.firstWhere((entry) => entry.seq == _selectedSeq);

  bool get _canAct {
    if (_saving) {
      return false;
    }
    if (_isCustom) {
      return _note.text.trim().isNotEmpty;
    }
    return true;
  }

  WordState get _activeState => widget.wordState;

  Future<void> _run(LookupAction action) async {
    if (!_canAct) {
      return;
    }
    setState(() => _saving = true);
    try {
      if (_isCustom) {
        await widget.onCustomAction!(action, _note.text.trim());
      } else {
        await widget.onAction!(action, _selected);
      }
      if (!mounted) {
        return;
      }
      if (widget.popOnAction) {
        Navigator.of(context).pop();
      } else {
        setState(() => _saving = false);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Falha ao salvar: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final wide = ShellLayout.isWide(context);
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyA): _LookupIntent(
          LookupAction.learn,
        ),
        SingleActivator(LogicalKeyboardKey.keyK): _LookupIntent(
          LookupAction.known,
        ),
        SingleActivator(LogicalKeyboardKey.keyI): _LookupIntent(
          LookupAction.ignore,
        ),
        SingleActivator(LogicalKeyboardKey.keyS): _LookupIntent(
          LookupAction.save,
        ),
      },
      child: Actions(
        actions: {
          _LookupIntent: _LookupPassthroughAction(
            onInvoke: (intent) {
              _run(intent.action);
              return null;
            },
          ),
        },
        child: Focus(
          focusNode: _focus,
          autofocus: true,
          child: Column(
            key: LookupSheetKeys.sheet,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _PhraseHeader(
                  sentence: widget.sentence,
                  start: widget.highlightStart,
                  end: widget.highlightEnd,
                  wide: wide,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    16 + ShellLayout.commandBarPaddingOf(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (result == null)
                        _LemmaHeader(lemma: widget.surface)
                      else if (result.entries.length == 1)
                        _LemmaHeader(
                          lemma: _selected.lemma,
                          reading: _selected.reading,
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 180),
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              for (final entry in result.entries)
                                ListTile(
                                  key: LookupSheetKeys.option(entry.seq),
                                  selected: entry.seq == _selectedSeq,
                                  title: Text(
                                    entry.lemma,
                                    style: AppTypeScale.linhaCadernoJp,
                                  ),
                                  subtitle: Text(
                                    [
                                      if (entry.reading != entry.lemma)
                                        entry.reading,
                                      if (entry.glosses.isNotEmpty)
                                        entry.glosses.first,
                                    ].join(' · '),
                                  ),
                                  onTap: () =>
                                      setState(() => _selectedSeq = entry.seq),
                                ),
                            ],
                          ),
                        ),
                      if (result != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _selected.glossText,
                          key: LookupSheetKeys.gloss,
                          style: AppTypeScale.definicao,
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Nenhuma entrada no dicionário.',
                          key: LookupSheetKeys.miss,
                          style: AppTypeScale.definicao,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          key: LookupSheetKeys.note,
                          controller: _note,
                          minLines: 2,
                          maxLines: 4,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                            labelText: 'Nota',
                            hintText: 'Obrigatória',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _ActionRow(
                        canAct: _canAct,
                        active: _activeState,
                        onPressed: _run,
                      ),
                    ],
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

class _LookupIntent extends Intent {
  const _LookupIntent(this.action);
  final LookupAction action;
}

class _LookupPassthroughAction extends CallbackAction<_LookupIntent> {
  _LookupPassthroughAction({required super.onInvoke});

  @override
  bool isEnabled(_LookupIntent intent) => !ShellShortcuts.isTyping;

  @override
  bool consumesKey(_LookupIntent intent) => !ShellShortcuts.isTyping;
}

class _PhraseHeader extends StatelessWidget {
  const _PhraseHeader({
    required this.sentence,
    required this.start,
    required this.end,
    required this.wide,
  });

  final String sentence;
  final int start;
  final int end;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final style = wide
        ? AppTypeScale.fraseLeitorDesktopJp
        : AppTypeScale.balaoPaginaMobileJp;
    final lo = start.clamp(0, sentence.length);
    final hi = end.clamp(lo, sentence.length);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          if (lo > 0) TextSpan(text: sentence.substring(0, lo)),
          if (hi > lo)
            TextSpan(
              text: sentence.substring(lo, hi),
              style: style.copyWith(
                backgroundColor: tokens.overlayPalavraNaFrase,
              ),
            ),
          if (hi < sentence.length) TextSpan(text: sentence.substring(hi)),
        ],
      ),
      key: LookupSheetKeys.phrase,
    );
  }
}

class _LemmaHeader extends StatelessWidget {
  const _LemmaHeader({required this.lemma, this.reading});

  final String lemma;
  final String? reading;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lemma, style: AppTypeScale.lookupJp),
        if (reading != null && reading != lemma)
          Text(
            reading!,
            style: AppTypeScale.ui14.copyWith(
              fontFamily: AppFonts.jp,
              color: tokens.text2,
            ),
          ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.canAct,
    required this.active,
    required this.onPressed,
  });

  final bool canAct;
  final WordState active;
  final ValueChanged<LookupAction> onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final specs = _actionSpecs(tokens);
    return Row(
      children: [
        for (var i = 0; i < specs.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: LookupActionButton(
              key: specs[i].key,
              label: specs[i].label,
              shortcut: specs[i].shortcut,
              foreground: specs[i].foreground,
              active: specs[i].state == active,
              activeFill: specs[i].fill,
              enabled: canAct,
              onPressed: () => onPressed(specs[i].action),
            ),
          ),
        ],
      ],
    );
  }

  List<_ActionSpec> _actionSpecs(MangaJpTokens tokens) {
    return [
      _ActionSpec(
        action: LookupAction.learn,
        key: LookupSheetKeys.learn,
        label: PageLabels.aprendendo,
        shortcut: 'A',
        state: WordState.learning,
        foreground: tokens.violetText,
        fill: tokens.overlayEstadoAtivo,
      ),
      _ActionSpec(
        action: LookupAction.known,
        key: LookupSheetKeys.known,
        label: PageLabels.conhecido,
        shortcut: 'K',
        state: WordState.known,
        foreground: tokens.mint,
        fill: tokens.srsBomFill,
      ),
      _ActionSpec(
        action: LookupAction.ignore,
        key: LookupSheetKeys.ignore,
        label: PageLabels.ignorar,
        shortcut: 'I',
        state: WordState.ignored,
        foreground: tokens.text3,
        fill: tokens.text3.withValues(alpha: 0.14),
      ),
      _ActionSpec(
        action: LookupAction.save,
        key: LookupSheetKeys.save,
        label: PageLabels.salvar,
        shortcut: 'S',
        state: WordState.saved,
        foreground: tokens.text,
        fill: tokens.text.withValues(alpha: 0.14),
      ),
    ];
  }
}

class _ActionSpec {
  const _ActionSpec({
    required this.action,
    required this.key,
    required this.label,
    required this.shortcut,
    required this.state,
    required this.foreground,
    required this.fill,
  });

  final LookupAction action;
  final Key key;
  final String label;
  final String shortcut;
  final WordState state;
  final Color foreground;
  final Color fill;
}

/// 52px state action (`target.acao-estado`), radius 14 (`dock-acao-busca`).
class LookupActionButton extends StatelessWidget {
  const LookupActionButton({
    super.key,
    required this.label,
    required this.shortcut,
    required this.foreground,
    required this.active,
    required this.activeFill,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final String shortcut;
  final Color foreground;
  final bool active;
  final Color activeFill;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    // Overlay fills are translucent (14%). Blend onto `surface` so the ink
    // and coral ring stay visible on the desktop drawer (`bg`), not only on
    // the mobile sheet (`surface`).
    final fill = active
        ? Color.alphaBlend(activeFill, tokens.surface)
        : tokens.surfaceRaised;
    final border = active ? tokens.coral : tokens.border;
    return Material(
      color: fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dockAcaoBusca),
        side: BorderSide(color: border, width: active ? 1.5 : 1),
      ),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(AppRadius.dockAcaoBusca),
        child: SizedBox(
          height: AppTargets.acaoEstado,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypeScale.metadados11.copyWith(
                    color: enabled ? foreground : tokens.text4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                KbdChip(label: shortcut, emphasis: active),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
