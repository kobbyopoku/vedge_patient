import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';

/// Spec §5.12 — five-tab bottom nav with our locked styling.
///
/// Long-press a destination resets that tab's nav stack to its root (handled
/// by the parent shell via [onLongPress]).
class VedgeBottomNav extends StatelessWidget {
  const VedgeBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.destinations,
    this.onLongPress,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<VedgeNavDestination> destinations;
  final ValueChanged<int>? onLongPress;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final isDark = cs.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: VedgeSpacing.bottomNavHeight - 12,
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _NavCell(
                    destination: destinations[i],
                    isActive: currentIndex == i,
                    activeIndicatorColor: isDark
                        ? VedgeColors.inkSurfaceElevated
                        : VedgeColors.cream200,
                    activeColor: cs.onSurface,
                    inactiveColor: cs.outline,
                    labelStyle: t.labelSmall,
                    onTap: () => onTap(i),
                    onLongPress: onLongPress == null ? null : () => onLongPress!(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class VedgeNavDestination {
  const VedgeNavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _NavCell extends StatelessWidget {
  const _NavCell({
    required this.destination,
    required this.isActive,
    required this.activeIndicatorColor,
    required this.activeColor,
    required this.inactiveColor,
    required this.labelStyle,
    required this.onTap,
    this.onLongPress,
  });

  final VedgeNavDestination destination;
  final bool isActive;
  final Color activeIndicatorColor;
  final Color activeColor;
  final Color inactiveColor;
  final TextStyle? labelStyle;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isActive,
      label: '${destination.label} tab${isActive ? ', currently active' : ''}',
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive ? activeIndicatorColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(VedgeSpacing.radiusFull),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isActive ? destination.activeIcon : destination.icon,
                  color: isActive ? activeColor : inactiveColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                destination.label,
                style: labelStyle?.copyWith(
                  color: isActive ? activeColor : inactiveColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
