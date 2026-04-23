import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/patient_auth_state.dart';
import '../core/models/patient_link.dart';
import '../theme/spacing.dart';
import 'vedge_button.dart';
import 'vedge_empty_state.dart';
import 'vedge_pill.dart';
import 'vedge_sheet.dart';

/// Spec §5.6 — single switching surface, opened from chips OR You tab.
class ProviderSwitcherSheet extends ConsumerStatefulWidget {
  const ProviderSwitcherSheet({super.key});

  @override
  ConsumerState<ProviderSwitcherSheet> createState() =>
      _ProviderSwitcherSheetState();
}

class _ProviderSwitcherSheetState
    extends ConsumerState<ProviderSwitcherSheet> {
  bool _switching = false;
  String? _switchingId;

  Future<void> _select(PatientLink link) async {
    if (link.isCurrent || !link.isVerified) return;
    final controller = ref.read(patientAuthControllerProvider.notifier);
    setState(() {
      _switching = true;
      _switchingId = link.id;
    });
    try {
      await controller.setCurrentLink(link.id);
      if (!mounted) return;
      // Pop is fire-and-forget; we just want it dismissed.
      // ignore: unawaited_futures
      Navigator.of(context).maybePop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Now showing ${link.organizationName}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _switching = false;
          _switchingId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(patientAuthControllerProvider);
    final cs = Theme.of(context).colorScheme;

    final verified = auth.links.where((l) => l.isVerified).toList();
    final pending = auth.links.where((l) => l.isPending).toList();

    if (auth.links.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: VedgeSpacing.space8),
        child: VedgeEmptyState(
          icon: Icons.local_hospital_rounded,
          title: 'No linked providers yet',
          body:
              "When a provider releases records to you, they'll appear here. Add your first one to get started.",
          action: VedgeButton(
            label: 'Add a provider',
            onPressed: () {
              Navigator.of(context).maybePop();
              context.push('/onboarding/find-records');
            },
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Now showing records from',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: VedgeSpacing.space3),
        for (final link in verified)
          _ProviderRow(
            link: link,
            isSelected: link.isCurrent,
            isLoading: _switching && _switchingId == link.id,
            onTap: _switching ? null : () => _select(link),
          ),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: VedgeSpacing.space4),
          Text(
            'Waiting for verification',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: VedgeSpacing.space2),
          for (final link in pending)
            _ProviderRow(
              link: link,
              isSelected: false,
              isLoading: false,
              onTap: null,
            ),
        ],
        const SizedBox(height: VedgeSpacing.space4),
        VedgeButton(
          label: 'Add another provider',
          variant: VedgeButtonVariant.secondary,
          onPressed: () {
            Navigator.of(context).maybePop();
            context.push('/onboarding/find-records');
          },
        ),
      ],
    );
  }
}

class _ProviderRow extends StatelessWidget {
  const _ProviderRow({
    required this.link,
    required this.isSelected,
    required this.isLoading,
    required this.onTap,
  });

  final PatientLink link;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final radio = isLoading
        ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: cs.primary),
          )
        : Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? cs.primary : cs.outline,
                width: 2,
              ),
              color: isSelected ? cs.primary : Colors.transparent,
            ),
            child: isSelected
                ? Icon(Icons.check_rounded, size: 16, color: cs.onPrimary)
                : null,
          );

    return Semantics(
      button: onTap != null,
      selected: isSelected,
      label:
          '${link.organizationName}${isSelected ? ', currently selected' : ''}',
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(VedgeSpacing.radiusMd),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VedgeSpacing.space2,
                  vertical: VedgeSpacing.space3,
                ),
                child: Row(
                  children: [
                    radio,
                    const SizedBox(width: VedgeSpacing.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(link.organizationName, style: t.titleMedium),
                          if (link.patientNameOnRecord != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'On record as ${link.patientNameOnRecord}',
                              style: t.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (link.isPending)
                      const VedgePill(
                        label: 'Waiting',
                        tone: VedgePillTone.caution,
                      ),
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

/// Open the canonical switcher sheet from any clinical surface.
Future<void> showProviderSwitcherSheet(BuildContext context) {
  return showVedgeSheet<void>(
    context: context,
    title: 'Switch provider',
    builder: (_) => const ProviderSwitcherSheet(),
  );
}
