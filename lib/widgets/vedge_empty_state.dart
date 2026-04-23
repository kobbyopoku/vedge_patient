import 'package:flutter/material.dart';

import '../theme/spacing.dart';

/// Spec §5.4 — friendly, centered empty state with a path forward.
class VedgeEmptyState extends StatelessWidget {
  const VedgeEmptyState({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.secondaryAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      label: '$title. $body',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: VedgeSpacing.space8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 80,
              child: ExcludeSemantics(
                child: Icon(icon, size: 56, color: cs.outline),
              ),
            ),
            const SizedBox(height: VedgeSpacing.space3),
            Text(
              title,
              style: t.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: VedgeSpacing.space6),
              action!,
            ],
            if (secondaryAction != null) ...[
              const SizedBox(height: VedgeSpacing.space2),
              secondaryAction!,
            ],
          ],
        ),
      ),
    );
  }
}
