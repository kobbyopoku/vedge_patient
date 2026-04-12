import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/patient_auth_state.dart';
import '../../core/models/patient_link.dart';

class ClaimsScreen extends ConsumerWidget {
  const ClaimsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(patientAuthControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your providers'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(
            auth.status == PatientAuthStatus.authenticatedReady
                ? '/home'
                : '/me',
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(patientAuthControllerProvider.notifier).refreshLinks(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              'These are the Vedge providers that have records linked '
              'to your account. You can switch between them anytime.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            if (auth.links.isEmpty)
              _EmptyState(
                onCheck: () => context.go('/claims/potential-matches'),
              )
            else
              ...auth.links.map((link) => _LinkCard(
                    link: link,
                    onTap: () async {
                      if (link.isVerified && !link.isCurrent) {
                        await ref
                            .read(patientAuthControllerProvider.notifier)
                            .setCurrentLink(link.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Now viewing ${link.organizationName}')),
                          );
                        }
                      }
                    },
                  )),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => context.go('/claims/potential-matches'),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add another provider'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.link, required this.onTap});
  final PatientLink link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          onTap: link.isVerified ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: cs.primary.withValues(alpha: 0.12),
                  child: Icon(Icons.local_hospital_outlined,
                      color: cs.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(link.organizationName,
                          style: theme.textTheme.titleMedium),
                      if (link.patientNameOnRecord != null)
                        Text(
                          'On record as ${link.patientNameOnRecord}',
                          style: theme.textTheme.bodySmall,
                        ),
                      const SizedBox(height: 4),
                      _StatusChip(link: link),
                    ],
                  ),
                ),
                if (link.isCurrent)
                  Icon(Icons.check_circle, color: cs.primary, size: 24)
                else if (link.isVerified)
                  Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.link});
  final PatientLink link;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (label, color) = switch (link.claimStatus) {
      PatientClaimStatus.verified when link.isCurrent => ('Current', cs.primary),
      PatientClaimStatus.verified => ('Verified', cs.primary),
      PatientClaimStatus.pending => ('Pending', const Color(0xFFB45309)),
      PatientClaimStatus.rejected => ('Rejected', cs.error),
      PatientClaimStatus.unknown => ('Unknown', cs.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCheck});
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.travel_explore, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('No providers linked yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'We can look across Vedge-connected providers for records '
              'matching your name, phone, and date of birth.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onCheck,
              child: const Text('Check for matches'),
            ),
          ],
        ),
      ),
    );
  }
}
