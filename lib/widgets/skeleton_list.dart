import 'package:flutter/material.dart';

import '../theme/spacing.dart';

/// Spec §5.16 — skeleton-row list, mirrors `VedgeListTile` shape.
///
/// First-paint loading state for any list. Honors `MediaQuery.disableAnimations`
/// for reduced-motion users (renders static blocks).
class SkeletonList extends StatefulWidget {
  const SkeletonList({this.itemCount = 5, super.key});

  final int itemCount;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Semantics(
      label: 'Loading',
      liveRegion: true,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: VedgeSpacing.space4,
          vertical: VedgeSpacing.space3,
        ),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: widget.itemCount,
        separatorBuilder: (_, __) =>
            const SizedBox(height: VedgeSpacing.space2),
        itemBuilder: (context, _) {
          final row = ExcludeSemantics(
            child: Container(
              padding: const EdgeInsets.all(VedgeSpacing.space4),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(VedgeSpacing.radiusLg),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(VedgeSpacing.radiusSm + 2),
                    ),
                  ),
                  const SizedBox(width: VedgeSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: double.infinity,
                          color: cs.outlineVariant,
                        ),
                        const SizedBox(height: VedgeSpacing.space2),
                        Container(
                          height: 12,
                          width: 160,
                          color: cs.outlineVariant.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );

          if (reduceMotion) return row;
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Opacity(
              opacity: 0.6 + (_controller.value * 0.4),
              child: child,
            ),
            child: row,
          );
        },
      ),
    );
  }
}
