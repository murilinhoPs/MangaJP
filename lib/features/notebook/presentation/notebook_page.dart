import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/routes.dart';
import '../../../core/shell/kbd_chip.dart';
import '../../../core/shell/shell_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../words/domain/word_state.dart';
import '../domain/notebook_entry.dart';
import 'notebook_controller.dart';
import 'notebook_labels.dart';

/// Caderno search focus, owned by the mounted [NotebookPage].
abstract final class NotebookSearch {
  static FocusNode? _node;

  static void attach(FocusNode node) => _node = node;

  static void detach(FocusNode node) {
    if (identical(_node, node)) {
      _node = null;
    }
  }

  static void requestFocus() => _node?.requestFocus();
}

/// Keys for `/notebook` (list + search + state filter; tap opens word detail).
abstract final class NotebookKeys {
  static const search = Key('notebook-search');
  static const stateAll = Key('notebook-state-all');
  static const list = Key('notebook-list');
  static const empty = Key('notebook-empty');
  static const noResults = Key('notebook-no-results');

  static Key stateFilter(WordState state) =>
      Key('notebook-state-${state.name}');

  static Key row(String wordId) => Key('notebook-row-$wordId');
}

/// `/notebook` — every word with a listed state, newest first.
class NotebookPage extends ConsumerStatefulWidget {
  const NotebookPage({super.key});

  @override
  ConsumerState<NotebookPage> createState() => _NotebookPageState();
}

class _NotebookPageState extends ConsumerState<NotebookPage> {
  final FocusNode _searchFocus = FocusNode();
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    NotebookSearch.attach(_searchFocus);
  }

  @override
  void dispose() {
    NotebookSearch.detach(_searchFocus);
    _searchFocus.dispose();
    _search.dispose();
    super.dispose();
  }

  void _setSearch(String value) {
    ref.read(notebookListQueryProvider.notifier).setSearch(value);
  }

  void _onSearchEscape() {
    if (_search.text.isNotEmpty) {
      _search.clear();
      _setSearch('');
      return;
    }
    _searchFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(notebookListQueryProvider);
    final entries = ref.watch(notebookEntriesProvider);
    final wide = ShellLayout.isWide(context);
    final padH = wide ? 48.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(padH, wide ? 24 : 12, padH, 0),
          child: Shortcuts(
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.escape):
                  _NotebookSearchEscIntent(),
            },
            child: Actions(
              actions: {
                _NotebookSearchEscIntent:
                    CallbackAction<_NotebookSearchEscIntent>(
                      onInvoke: (_) {
                        _onSearchEscape();
                        return null;
                      },
                    ),
              },
              child: TextField(
                key: NotebookKeys.search,
                focusNode: _searchFocus,
                controller: _search,
                textInputAction: TextInputAction.search,
                style: AppTypeScale.ui14,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: NotebookLabels.searchHint,
                  suffixIcon: wide
                      ? const Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: UnconstrainedBox(
                            child: KbdChip(label: '/'),
                          ),
                        )
                      : null,
                ),
                onChanged: _setSearch,
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.fromLTRB(padH, 12, padH, 8),
          child: Row(
            children: [
              _StateChip(
                chipKey: NotebookKeys.stateAll,
                label: NotebookLabels.todos,
                selected: query.state == null,
                onSelected: () {
                  ref.read(notebookListQueryProvider.notifier).setState(null);
                },
              ),
              for (final state in WordState.listed)
                _StateChip(
                  chipKey: NotebookKeys.stateFilter(state),
                  label: NotebookLabels.state(state),
                  selected: query.state == state,
                  onSelected: () {
                    ref
                        .read(notebookListQueryProvider.notifier)
                        .setState(state);
                  },
                ),
            ],
          ),
        ),
        Expanded(
          child: entries.when(
            data: (items) => _NotebookList(
              entries: items,
              query: query,
              wide: wide,
            ),
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
          ),
        ),
      ],
    );
  }
}

class _NotebookSearchEscIntent extends Intent {
  const _NotebookSearchEscIntent();
}

class _StateChip extends StatelessWidget {
  const _StateChip({
    required this.chipKey,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final Key chipKey;
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        key: chipKey,
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: tokens.overlayPrimaria,
        backgroundColor: tokens.surface,
        labelStyle: AppTypeScale.metadados12.copyWith(
          color: selected ? tokens.text : tokens.text2,
        ),
        side: BorderSide(color: selected ? tokens.coral : tokens.border),
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _NotebookList extends StatelessWidget {
  const _NotebookList({
    required this.entries,
    required this.query,
    required this.wide,
  });

  final List<NotebookEntry> entries;
  final NotebookQuery query;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      final filtered = query.search.isNotEmpty || query.state != null;
      return _NotebookEmpty(
        statusKey: filtered ? NotebookKeys.noResults : NotebookKeys.empty,
        title: filtered ? NotebookLabels.noResults : NotebookLabels.empty,
        hint: filtered
            ? NotebookLabels.noResultsHint
            : NotebookLabels.emptyHint,
        wide: wide,
      );
    }

    final padH = wide ? 48.0 : 16.0;
    return ListView.separated(
      key: NotebookKeys.list,
      padding: ShellLayout.withCommandBarPadding(
        context,
        EdgeInsets.fromLTRB(padH, 4, padH, wide ? 32 : 16),
      ),
      itemCount: entries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final tokens = context.tokens;
        final radius = BorderRadius.circular(AppRadius.linha);
        return Material(
          color: tokens.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: tokens.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            key: NotebookKeys.row(entry.wordId),
            shape: RoundedRectangleBorder(borderRadius: radius),
            title: Text(entry.lemma, style: AppTypeScale.linhaCadernoJp),
            subtitle: Text(
              entry.reading,
              style: AppTypeScale.ui14.copyWith(
                fontFamily: AppFonts.jp,
                color: tokens.text2,
              ),
            ),
            trailing: Text(
              NotebookLabels.state(entry.state),
              style: AppTypeScale.metadados11.copyWith(
                color: tokens.wordState(entry.state.name),
              ),
            ),
            onTap: () => NotebookWordRoute(id: entry.wordId).go(context),
          ),
        );
      },
    );
  }
}

class _NotebookEmpty extends StatelessWidget {
  const _NotebookEmpty({
    required this.statusKey,
    required this.title,
    required this.hint,
    required this.wide,
  });

  final Key statusKey;
  final String title;
  final String hint;
  final bool wide;

  @override
  Widget build(BuildContext context) {
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
                  NotebookLabels.watermark,
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
                title,
                key: statusKey,
                textAlign: TextAlign.center,
                style: AppTypeScale.tituloTela.copyWith(color: tokens.text),
              ),
              const SizedBox(height: 8),
              Text(
                hint,
                textAlign: TextAlign.center,
                style: AppTypeScale.ui14.copyWith(color: tokens.text3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
