import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'shell_layout.dart';

/// Mobile task-screen dock: 48px buttons + central meta, radius 14, `surface`.
class TaskDock extends StatelessWidget {
  const TaskDock({
    super.key,
    this.meta,
    this.metaHint,
    this.leading = const [],
    this.trailing = const [],
  });

  final String? meta;
  final String? metaHint;
  final List<Widget> leading;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Material(
      color: tokens.bg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            key: ShellKeys.taskDock,
            children: [
              ..._spaced(leading),
              if (leading.isNotEmpty) const SizedBox(width: 8),
              Expanded(
                child: _Meta(title: meta, hint: metaHint),
              ),
              if (trailing.isNotEmpty) const SizedBox(width: 8),
              ..._spaced(trailing),
            ],
          ),
        ),
      ),
    );
  }

  static List<Widget> _spaced(List<Widget> children) {
    return [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        children[i],
      ],
    ];
  }
}

class DockIconButton extends StatelessWidget {
  const DockIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final button = Material(
      color: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dockAcaoBusca),
        side: BorderSide(color: tokens.border),
      ),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(AppRadius.dockAcaoBusca),
        child: SizedBox(
          width: AppTargets.dockTela,
          height: AppTargets.dockTela,
          child: Icon(
            icon,
            size: AppIcons.sizeMin,
            color: enabled ? tokens.text2 : tokens.text4,
          ),
        ),
      ),
    );
    if (tooltip == null) {
      return button;
    }
    return Tooltip(message: tooltip!, child: button);
  }
}

class DockTextButton extends StatelessWidget {
  const DockTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Material(
      color: primary ? tokens.overlayPrimaria : tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dockAcaoBusca),
        side: BorderSide(color: primary ? tokens.coral : tokens.border),
      ),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(AppRadius.dockAcaoBusca),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppTargets.dockTela,
            minHeight: AppTargets.dockTela,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(
              child: Text(
                label,
                style: AppTypeScale.ui14.copyWith(
                  fontWeight: FontWeight.w500,
                  color: enabled ? tokens.text : tokens.text4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({this.title, this.hint});

  final String? title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      height: AppTargets.dockTela,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(AppRadius.dockAcaoBusca),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypeScale.ui13.copyWith(
                color: tokens.text,
                fontWeight: FontWeight.w500,
              ),
            ),
          if (hint != null)
            Text(
              hint!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypeScale.metadados11.copyWith(color: tokens.text3),
            ),
        ],
      ),
    );
  }
}
