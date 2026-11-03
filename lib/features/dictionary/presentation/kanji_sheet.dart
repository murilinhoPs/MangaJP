import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/shell/shell_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/kanji.dart';
import '../../notebook/data/notebook_repository.dart';
import '../../notebook/presentation/notebook_controller.dart';
import '../../notebook/presentation/notebook_labels.dart';
import '../../pages/domain/page_labels.dart';
import '../data/jmdict_provider.dart';
import '../domain/kanji_entry.dart';
import 'lookup_sheet.dart';

/// Keys for the kanji ficha (KANJIDIC2 fields + Salvar kanji).
abstract final class KanjiSheetKeys {
  static const sheet = Key('kanji-sheet');
  static const modal = Key('kanji-modal');
  static const literal = Key('kanji-sheet-literal');
  static const on = Key('kanji-sheet-on');
  static const kun = Key('kanji-sheet-kun');
  static const meanings = Key('kanji-sheet-meanings');
  static const strokes = Key('kanji-sheet-strokes');
  static const save = Key('kanji-sheet-save');
}

Future<void> showKanjiSheet(
  BuildContext context, {
  required String literal,
  String? originPageId,
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
      key: KanjiSheetKeys.modal,
      height: height,
      child: KanjiSheet(
        literal: literal,
        originPageId: originPageId,
        popOnSave: true,
      ),
    ),
  );
}

/// Ficha do kanji: on/kun, significados, traços, **Salvar kanji**.
class KanjiSheet extends ConsumerStatefulWidget {
  const KanjiSheet({
    super.key,
    required this.literal,
    this.originPageId,
    this.popOnSave = false,
  });

  final String literal;
  final String? originPageId;
  final bool popOnSave;

  @override
  ConsumerState<KanjiSheet> createState() => _KanjiSheetState();
}

class _KanjiSheetState extends ConsumerState<KanjiSheet> {
  bool _saving = false;
  final _focus = FocusNode();

  String get _literal =>
      normalizeKanjiLiteral(widget.literal) ?? widget.literal;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(notebookRepositoryProvider)
          .saveKanji(literal: _literal, originPageId: widget.originPageId);
      ref.invalidate(kanjiIsSavedProvider(_literal));
      ref.invalidate(notebookKanjiEntriesProvider);
      if (!mounted) {
        return;
      }
      if (widget.popOnSave) {
        Navigator.of(context).pop();
      } else {
        setState(() => _saving = false);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Falha ao salvar: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final jmdict = ref.watch(jmdictServiceProvider);
    final saved = ref.watch(kanjiIsSavedProvider(_literal));
    final entry = jmdict.asData?.value.kanjiByCharacter(_literal);
    final isSaved = saved.asData?.value ?? false;

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyS): _SaveKanjiIntent(),
      },
      child: Actions(
        actions: {
          _SaveKanjiIntent: CallbackAction<_SaveKanjiIntent>(
            onInvoke: (_) {
              _save();
              return null;
            },
          ),
        },
        child: Focus(
          focusNode: _focus,
          autofocus: true,
          child: Padding(
            key: KanjiSheetKeys.sheet,
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              16 + ShellLayout.commandBarPaddingOf(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: _KanjiFields(
                      literal: _literal,
                      entry: entry,
                      wide: ShellLayout.isWide(context),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                LookupActionButton(
                  key: KanjiSheetKeys.save,
                  label: NotebookLabels.salvarKanji,
                  shortcut: ShellLayout.isWide(context) ? 'S' : null,
                  foreground: tokens.text,
                  active: isSaved,
                  activeFill: tokens.text.withValues(alpha: 0.14),
                  enabled: !_saving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveKanjiIntent extends Intent {
  const _SaveKanjiIntent();
}

class _KanjiFields extends StatelessWidget {
  const _KanjiFields({
    required this.literal,
    required this.entry,
    required this.wide,
  });

  final String literal;
  final KanjiEntry? entry;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final lookup = entry;
    final hasKanjidic = lookup?.hasKanjidic ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          literal,
          key: KanjiSheetKeys.literal,
          style: wide
              ? AppTypeScale.detalheDesktopJp
              : AppTypeScale.detalheMobileJp,
        ),
        if (hasKanjidic) ...[
          if (lookup!.onReadings.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _SectionLabel(NotebookLabels.kanjiOn),
            const SizedBox(height: 4),
            Text(
              lookup.onReadings.join(' · '),
              key: KanjiSheetKeys.on,
              style: AppTypeScale.ui14.copyWith(
                fontFamily: AppFonts.jp,
                color: tokens.text2,
              ),
            ),
          ],
          if (lookup.kunReadings.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _SectionLabel(NotebookLabels.kanjiKun),
            const SizedBox(height: 4),
            Text(
              lookup.kunReadings.join(' · '),
              key: KanjiSheetKeys.kun,
              style: AppTypeScale.ui14.copyWith(
                fontFamily: AppFonts.jp,
                color: tokens.text2,
              ),
            ),
          ],
          if (lookup.meanings.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _SectionLabel(NotebookLabels.kanjiMeanings),
            const SizedBox(height: 4),
            Text(
              lookup.meanings.join('; '),
              key: KanjiSheetKeys.meanings,
              style: AppTypeScale.definicao,
            ),
          ],
          if (lookup.strokeCount != null) ...[
            const SizedBox(height: 12),
            const _SectionLabel(NotebookLabels.kanjiStrokes),
            const SizedBox(height: 4),
            Text(
              '${lookup.strokeCount}',
              key: KanjiSheetKeys.strokes,
              style: AppTypeScale.ui14.copyWith(color: tokens.text2),
            ),
          ],
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Text(
      label,
      style: AppTypeScale.mono10.copyWith(
        color: tokens.text3,
        letterSpacing: 0.8,
      ),
    );
  }
}
