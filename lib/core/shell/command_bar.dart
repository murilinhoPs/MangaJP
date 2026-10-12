import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'kbd_chip.dart';
import 'shell_layout.dart';
import 'shell_registry.dart';
import 'task_dock.dart';

/// Floating desktop command bar: `surface-low`, 1px border, kbd chips.
///
/// Mirrors the mobile [TaskDock] order when [meta] is set: first action
/// (voltar / close), then the meta pill, then the remaining actions.
class CommandBar extends StatelessWidget {
  const CommandBar({
    super.key,
    required this.actions,
    this.meta,
    this.metaHint,
  });

  final List<ShellAction> actions;
  final String? meta;
  final String? metaHint;

  bool get _hasMeta {
    final title = meta?.trim();
    final hint = metaHint?.trim();
    return (title != null && title.isNotEmpty) ||
        (hint != null && hint.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty && !_hasMeta) {
      return const SizedBox.shrink();
    }
    final tokens = context.tokens;
    return Material(
      key: ShellKeys.commandBar,
      type: MaterialType.transparency,
      child: Padding(
        padding: const EdgeInsets.only(bottom: ShellLayout.commandBarBottom),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tokens.surfaceLow,
              borderRadius: BorderRadius.circular(AppRadius.dockAcaoBusca),
              border: Border.all(color: tokens.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _children(),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _children() {
    final items = <Widget>[];
    void add(Widget child) {
      if (items.isNotEmpty) {
        items.add(const SizedBox(width: 8));
      }
      items.add(child);
    }

    final metaPill = _hasMeta
        ? ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: TaskMeta(title: meta, hint: metaHint),
          )
        : null;
    if (actions.isEmpty) {
      add(metaPill!);
      return items;
    }
    add(_BarButton(action: actions.first));
    if (metaPill != null) {
      add(metaPill);
    }
    for (final action in actions.skip(1)) {
      add(_BarButton(action: action));
    }
    return items;
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({required this.action});

  final ShellAction action;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = action.primary;
    return Material(
      type: primary ? MaterialType.canvas : MaterialType.transparency,
      color: primary ? tokens.overlayPrimaria : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.railBarra),
        side: BorderSide(color: primary ? tokens.coral : tokens.border),
      ),
      child: InkWell(
        key: ShellKeys.command(action.id),
        onTap: action.enabled ? action.onPressed : null,
        borderRadius: BorderRadius.circular(AppRadius.railBarra),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppTargets.min),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  action.label,
                  style: AppTypeScale.ui13.copyWith(
                    color: action.enabled ? tokens.text : tokens.text4,
                  ),
                ),
                if (action.shortcut != null) ...[
                  const SizedBox(width: 8),
                  KbdChip(label: action.shortcut!, emphasis: primary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
