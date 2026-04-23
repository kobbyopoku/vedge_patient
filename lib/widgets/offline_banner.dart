import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';

/// Spec §5.14 — sticky banner under the app bar when offline.
///
/// The actual connectivity stream lives in `lib/core/connectivity/`. This is
/// the presentational widget. Wrap a screen body in `Column` with this banner
/// at the top when [isOffline] is true.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    required this.isOffline,
    this.message = "You're offline — showing your saved records",
    super.key,
  });

  final bool isOffline;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        axisAlignment: -1,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: !isOffline
          ? const SizedBox.shrink()
          : Semantics(
              liveRegion: true,
              label: message,
              child: Container(
                width: double.infinity,
                height: 36,
                color: VedgeColors.cautionBg,
                padding: const EdgeInsets.symmetric(
                  horizontal: VedgeSpacing.space4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: 16, color: VedgeColors.caution),
                    const SizedBox(width: VedgeSpacing.space2),
                    Flexible(
                      child: Text(
                        message,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: VedgeColors.caution,
                              fontWeight: FontWeight.w600,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
