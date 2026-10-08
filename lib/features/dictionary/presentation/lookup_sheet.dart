import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/dict_entry.dart';
import '../domain/lookup_result.dart';

/// Keys for the lookup sheet (gloss + Save; custom note when JMdict misses).
abstract final class LookupSheetKeys {
  static const sheet = Key('lookup-sheet');
  static const gloss = Key('lookup-gloss');
  static const miss = Key('lookup-miss');
  static const note = Key('lookup-note');
  static const save = Key('lookup-save');

  static Key option(int seq) => Key('lookup-option-$seq');
}

Future<void> showLookupSheet(
  BuildContext context,
  LookupResult result, {
  required Future<void> Function(DictEntry selected) onSave,
}) {
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
    builder: (context) => LookupSheet(result: result, onSave: onSave),
  );
}

Future<void> showCustomLookupSheet(
  BuildContext context, {
  required String surface,
  required Future<void> Function(String userNote) onSave,
}) {
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
    builder: (context) =>
        LookupSheet.custom(surface: surface, onSaveCustom: onSave),
  );
}

/// Homograph list + selected entry gloss (default = highest `forms.priority`).
///
/// [LookupSheet.custom] is the no-JMdict path: required [userNote], no gloss.
class LookupSheet extends StatefulWidget {
  LookupSheet({super.key, required LookupResult result, required this.onSave})
    : result = result,
      surface = result.surface,
      onSaveCustom = null;

  const LookupSheet.custom({
    super.key,
    required this.surface,
    required this.onSaveCustom,
  }) : result = null,
       onSave = null;

  final LookupResult? result;
  final String surface;
  final Future<void> Function(DictEntry selected)? onSave;
  final Future<void> Function(String userNote)? onSaveCustom;

  @override
  State<LookupSheet> createState() => _LookupSheetState();
}

class _LookupSheetState extends State<LookupSheet> {
  late int? _selectedSeq;
  bool _saving = false;
  final _note = TextEditingController();

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
    super.dispose();
  }

  void _onNoteChanged() => setState(() {});

  bool get _isCustom => widget.result == null;

  DictEntry get _selected =>
      widget.result!.entries.firstWhere((entry) => entry.seq == _selectedSeq);

  bool get _canSave {
    if (_saving) {
      return false;
    }
    if (_isCustom) {
      return _note.text.trim().isNotEmpty;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_canSave) {
      return;
    }
    setState(() => _saving = true);
    try {
      if (_isCustom) {
        await widget.onSaveCustom!(_note.text.trim());
      } else {
        await widget.onSave!(_selected);
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
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
    final maxHeight = MediaQuery.sizeOf(context).height * 0.6;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                key: LookupSheetKeys.sheet,
                mainAxisSize: MainAxisSize.min,
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
                      constraints: const BoxConstraints(maxHeight: 220),
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
                  FilledButton(
                    key: LookupSheetKeys.save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(AppTargets.acaoEstado),
                    ),
                    onPressed: _canSave ? _save : null,
                    child: const Text('Salvar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
