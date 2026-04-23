import 'package:flutter/material.dart';

/// Brand-styled `RefreshIndicator`. Color follows ColorScheme primary (ink in
/// light, cream in dark). Used on every list screen.
class VedgeRefreshIndicator extends StatelessWidget {
  const VedgeRefreshIndicator({
    required this.onRefresh,
    required this.child,
    super.key,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: cs.primary,
      backgroundColor: cs.surfaceContainerHighest,
      strokeWidth: 2.4,
      displacement: 24,
      child: child,
    );
  }
}
