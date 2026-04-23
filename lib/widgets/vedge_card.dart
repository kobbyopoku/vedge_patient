import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';

enum VedgeCardVariant { standard, tappable, accent }

/// Standardized container per spec §5.2. Replaces ad-hoc `Container` cards.
class VedgeCard extends StatelessWidget {
  const VedgeCard({
    required this.child,
    this.variant = VedgeCardVariant.standard,
    this.padding = const EdgeInsets.all(VedgeSpacing.space4),
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final VedgeCardVariant variant;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isAccent = variant == VedgeCardVariant.accent;

    final bg = isAccent ? VedgeColors.clay50 : cs.surfaceContainerHighest;
    final border = isAccent ? VedgeColors.clay500 : cs.outlineVariant;

    final radius = BorderRadius.circular(VedgeSpacing.radiusLg);
    final shape = RoundedRectangleBorder(
      borderRadius: radius,
      side: BorderSide(color: border),
    );

    Widget content = Padding(padding: padding, child: child);

    if (variant == VedgeCardVariant.tappable && onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: cs.onSurface.withValues(alpha: 0.04),
        highlightColor: cs.onSurface.withValues(alpha: 0.02),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: VedgeSpacing.tapComfortable),
          child: content,
        ),
      );
    }

    final card = Material(
      color: bg,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: content,
    );

    if (semanticLabel != null) {
      return Semantics(
        button: variant == VedgeCardVariant.tappable && onTap != null,
        container: true,
        label: semanticLabel,
        child: card,
      );
    }
    return card;
  }
}
