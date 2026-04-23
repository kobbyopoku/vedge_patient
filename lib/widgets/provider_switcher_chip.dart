import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/patient_auth_state.dart';
import '../theme/spacing.dart';
import 'provider_switcher_sheet.dart';

/// Spec §5.6 — compact chip in the app bar showing the active provider.
///
/// Tap → opens [ProviderSwitcherSheet] (the canonical switching surface).
/// Hidden when the user has no current provider yet (the You tab guides them
/// to pick one in that case).
class ProviderSwitcherChip extends ConsumerWidget {
  const ProviderSwitcherChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(patientAuthControllerProvider);
    final current = auth.currentLink;
    if (current == null) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: 'Now showing ${current.organizationName}. Tap to switch provider.',
      child: ExcludeSemantics(
        child: Material(
          color: cs.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VedgeSpacing.radiusFull),
            side: BorderSide(color: cs.outlineVariant),
          ),
          child: InkWell(
            onTap: () => showProviderSwitcherSheet(context),
            borderRadius: BorderRadius.circular(VedgeSpacing.radiusFull),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 36, maxWidth: 180),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VedgeSpacing.space3,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_hospital_rounded,
                        size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        current.organizationName,
                        style: t.labelMedium?.copyWith(color: cs.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.unfold_more_rounded,
                        size: 14, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
