import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import 'vedge_pill.dart';

/// Spec §5.5 — clinical list row. Replaces ad-hoc cards with consistent rows.
class VedgeListTile extends StatelessWidget {
  const VedgeListTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingPill,
    this.trailingChevron = true,
    this.iconTone,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VedgePill? trailingPill;
  final bool trailingChevron;
  final VedgePillTone? iconTone;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final iconBg = _iconBg(cs, iconTone);
    final iconFg = _iconFg(cs, iconTone);

    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VedgeSpacing.space4,
        vertical: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(VedgeSpacing.radiusSm + 2),
            ),
            child: Icon(icon, color: iconFg, size: 22),
          ),
          const SizedBox(width: VedgeSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: t.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailingPill != null) ...[
            const SizedBox(width: VedgeSpacing.space2),
            trailingPill!,
          ],
          if (trailingChevron) ...[
            const SizedBox(width: VedgeSpacing.space2),
            Icon(Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant, size: 20),
          ],
        ],
      ),
    );

    final tile = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 72),
      child: row,
    );

    if (onTap != null) {
      return Semantics(
        button: true,
        label: semanticLabel ?? _composedSemantics(),
        child: ExcludeSemantics(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: cs.onSurface.withValues(alpha: 0.04),
              highlightColor: cs.onSurface.withValues(alpha: 0.02),
              child: tile,
            ),
          ),
        ),
      );
    }
    return Semantics(
      label: semanticLabel ?? _composedSemantics(),
      child: ExcludeSemantics(child: tile),
    );
  }

  String _composedSemantics() {
    final parts = <String>[title];
    if (subtitle != null) parts.add(subtitle!);
    return parts.join(', ');
  }

  Color _iconBg(ColorScheme cs, VedgePillTone? tone) {
    switch (tone) {
      case VedgePillTone.positive:
        return VedgeColors.positiveBg;
      case VedgePillTone.caution:
        return VedgeColors.cautionBg;
      case VedgePillTone.critical:
        return VedgeColors.criticalBg;
      case VedgePillTone.info:
        return VedgeColors.infoBg;
      case VedgePillTone.neutral:
      case null:
        return cs.surface == VedgeColors.cream
            ? VedgeColors.cream100
            : cs.surfaceContainerHighest;
    }
  }

  Color _iconFg(ColorScheme cs, VedgePillTone? tone) {
    switch (tone) {
      case VedgePillTone.positive:
        return VedgeColors.positive;
      case VedgePillTone.caution:
        return VedgeColors.caution;
      case VedgePillTone.critical:
        return VedgeColors.critical;
      case VedgePillTone.info:
        return VedgeColors.info;
      case VedgePillTone.neutral:
      case null:
        return cs.onSurface;
    }
  }
}
