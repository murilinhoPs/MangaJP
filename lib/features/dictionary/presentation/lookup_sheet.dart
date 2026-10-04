import 'package:flutter/material.dart';

import '../domain/dict_entry.dart';
import '../domain/lookup_result.dart';

/// Keys for the M1.3 lookup sheet (gloss from JMdict, no Caderno / card).
abstract final class LookupSheetKeys {
  static const sheet = Key('lookup-sheet');
  static const gloss = Key('lookup-gloss');

  static Key option(int seq) => Key('lookup-option-$seq');
}

Future<void> showLookupSheet(BuildContext context, LookupResult result) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => LookupSheet(result: result),
  );
}

/// Homograph list + selected entry gloss (default = highest `forms.priority`).
class LookupSheet extends StatefulWidget {
  const LookupSheet({super.key, required this.result});

  final LookupResult result;

  @override
  State<LookupSheet> createState() => _LookupSheetState();
}

class _LookupSheetState extends State<LookupSheet> {
  late int _selectedSeq;

  @override
  void initState() {
    super.initState();
    _selectedSeq = widget.result.selectedSeq;
  }

  DictEntry get _selected =>
      widget.result.entries.firstWhere((entry) => entry.seq == _selectedSeq);

  @override
  Widget build(BuildContext context) {
    final entries = widget.result.entries;
    final selected = _selected;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          key: LookupSheetKeys.sheet,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (entries.length == 1)
              _LemmaHeader(entry: selected)
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final entry in entries)
                      ListTile(
                        key: LookupSheetKeys.option(entry.seq),
                        selected: entry.seq == _selectedSeq,
                        title: Text(entry.lemma),
                        subtitle: Text(
                          [
                            if (entry.reading != entry.lemma) entry.reading,
                            if (entry.glosses.isNotEmpty) entry.glosses.first,
                          ].join(' · '),
                        ),
                        onTap: () => setState(() => _selectedSeq = entry.seq),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Text(
              selected.glossText,
              key: LookupSheetKeys.gloss,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _LemmaHeader extends StatelessWidget {
  const _LemmaHeader({required this.entry});

  final DictEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(entry.lemma, style: theme.textTheme.headlineSmall),
        if (entry.reading != entry.lemma)
          Text(entry.reading, style: theme.textTheme.titleMedium),
      ],
    );
  }
}
