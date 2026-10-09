import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'shell_layout.dart';

/// Mobile bottom nav: four cards (not Material [NavigationBar]).
class NavCards extends StatelessWidget {
  const NavCards({super.key, required this.path});

  final String path;

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
            key: ShellKeys.navCards,
            children: [
              for (var i = 0; i < MobileNav.destinations.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _NavCard(
                    destination: MobileNav.destinations[i],
                    selected: MobileNav.destinations[i].isActive(path),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({required this.destination, required this.selected});

  final ShellDestination destination;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final ink = selected ? tokens.coral : tokens.text2;
    return Material(
      color: selected ? tokens.overlayPrimaria : tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dockAcaoBusca),
        side: BorderSide(color: selected ? tokens.coral : tokens.border),
      ),
      child: InkWell(
        key: ShellKeys.navCard(destination.id),
        onTap: () => destination.go(context),
        borderRadius: BorderRadius.circular(AppRadius.dockAcaoBusca),
        child: SizedBox(
          height: AppTargets.navCards,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(destination.icon, size: AppIcons.sizeMax, color: ink),
              const SizedBox(height: 4),
              Text(
                destination.label,
                style: AppTypeScale.metadados11.copyWith(
                  color: ink,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
