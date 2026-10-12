import 'package:flutter/material.dart';

import '../router/routes.dart';
import '../theme/app_theme.dart';
import 'shell_layout.dart';

/// Desktop left rail: 76px, `rail` fill, JP seal, destinations, Ajustes pinned.
class AppRail extends StatelessWidget {
  const AppRail({
    super.key,
    required this.path,
    required this.reviewBadge,
    this.recentPageId,
  });

  final String path;
  final int reviewBadge;
  final String? recentPageId;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Material(
      key: ShellKeys.rail,
      color: tokens.rail,
      child: SizedBox(
        width: ShellLayout.railWidth,
        child: SafeArea(
          right: false,
          child: Column(
            children: [
              const SizedBox(height: 14),
              const _JpSeal(),
              const SizedBox(height: 16),
              for (final dest in DesktopRail.items)
                _RailItem(
                  destination: dest,
                  selected: dest.isActive(path),
                  badge: dest.id == 'revisar' ? reviewBadge : 0,
                  enabled: dest.id != 'leitor' || recentPageId != null,
                  onTap: dest.id == 'leitor'
                      ? _leitorTap(context)
                      : () => dest.go(context),
                ),
              const Spacer(),
              _RailItem(
                key: ShellKeys.railAjustes,
                destination: DesktopRail.ajustes,
                selected: DesktopRail.ajustes.isActive(path),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  VoidCallback? _leitorTap(BuildContext context) {
    final id = recentPageId;
    if (id == null) {
      return null;
    }
    return () => PageDetailRoute(id: id).go(context);
  }
}

class _JpSeal extends StatelessWidget {
  const _JpSeal();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      key: ShellKeys.jpSeal,
      width: ShellLayout.jpSealSize,
      height: ShellLayout.jpSealSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.coral,
        borderRadius: BorderRadius.circular(AppRadius.railBarra),
      ),
      child: Text(
        'JP',
        style: AppTypeScale.ui13.copyWith(
          color: tokens.onCoral,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    super.key,
    required this.destination,
    required this.selected,
    this.badge = 0,
    this.enabled = true,
    this.onTap,
  });

  final ShellDestination destination;
  final bool selected;
  final int badge;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final ink = !enabled
        ? tokens.text4
        : selected
        ? tokens.coral
        : tokens.text3;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        key: ShellKeys.railItem(destination.id),
        onTap: enabled ? (onTap ?? () => destination.go(context)) : null,
        borderRadius: BorderRadius.circular(AppRadius.railBarra),
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? tokens.overlayRailAtivo : null,
                      borderRadius: BorderRadius.circular(AppRadius.railBarra),
                    ),
                    child: Icon(destination.icon, size: 20, color: ink),
                  ),
                  if (badge > 0)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: _MintBadge(count: badge),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                destination.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypeScale.metadados11.copyWith(
                  fontSize: 10,
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

class _MintBadge extends StatelessWidget {
  const _MintBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final label = count > 99 ? '99+' : '$count';
    return Container(
      key: ShellKeys.reviewBadge,
      constraints: const BoxConstraints(minWidth: 18, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.mint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTypeScale.mono10.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: tokens.onMint,
        ),
      ),
    );
  }
}
