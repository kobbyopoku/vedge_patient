import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';

enum VedgePillTone { info, positive, caution, critical, neutral }

/// Status indicator. Per spec §5.3, NEVER tappable — it's an attribute.
/// 6px radius (intentionally NOT pill-shaped — labels, not decoration).
class VedgePill extends StatelessWidget {
  const VedgePill({
    required this.label,
    this.tone = VedgePillTone.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final VedgePillTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colors = _resolveColors(cs, tone);
    final t = Theme.of(context).textTheme;

    return Semantics(
      label: '${_toneSpoken(tone)}: $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: colors.bg,
          borderRadius: BorderRadius.circular(VedgeSpacing.radiusXs),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: colors.fg),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: t.labelMedium?.copyWith(
                color: colors.fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _toneSpoken(VedgePillTone t) {
    switch (t) {
      case VedgePillTone.info:
        return 'Info';
      case VedgePillTone.positive:
        return 'Good news';
      case VedgePillTone.caution:
        return 'Caution';
      case VedgePillTone.critical:
        return 'Critical';
      case VedgePillTone.neutral:
        return 'Status';
    }
  }

  _PillColors _resolveColors(ColorScheme cs, VedgePillTone tone) {
    switch (tone) {
      case VedgePillTone.info:
        return const _PillColors(bg: VedgeColors.infoBg, fg: VedgeColors.info);
      case VedgePillTone.positive:
        return const _PillColors(bg: VedgeColors.positiveBg, fg: VedgeColors.positive);
      case VedgePillTone.caution:
        return const _PillColors(bg: VedgeColors.cautionBg, fg: VedgeColors.caution);
      case VedgePillTone.critical:
        return const _PillColors(bg: VedgeColors.criticalBg, fg: VedgeColors.critical);
      case VedgePillTone.neutral:
        return _PillColors(bg: cs.surfaceContainerHighest, fg: cs.onSurfaceVariant);
    }
  }
}

class _PillColors {
  const _PillColors({required this.bg, required this.fg});
  final Color bg;
  final Color fg;
}
