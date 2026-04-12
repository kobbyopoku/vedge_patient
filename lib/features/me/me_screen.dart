import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/patient_auth_state.dart';
import '../../core/models/patient_link.dart';
import 'switch_provider_sheet.dart';

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(patientAuthControllerProvider);
    final account = auth.account;
    final theme = Theme.of(context);
    final verified = auth.links.where((l) => l.isVerified).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Me')),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(patientAuthControllerProvider.notifier).refreshLinks(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                  child: Text(
                    account?.initials ?? '?',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account?.fullName ?? 'Unknown',
                          style: theme.textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        account?.phone ?? account?.email ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionHeader('Your providers'),
            const SizedBox(height: 8),
            if (verified.isEmpty)
              _EmptyProvidersCard(
                onCheck: () => context.go('/claims/potential-matches'),
              )
            else ...[
              Card(
                child: Column(
                  children: [
                    for (int i = 0; i < verified.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      _ProviderRow(link: verified[i]),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => SwitchProviderSheet.show(context),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Switch current provider'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.go('/claims'),
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Manage links'),
              ),
            ],
            const SizedBox(height: 24),
            _SectionHeader('Notifications'),
            const SizedBox(height: 8),
            Card(
              child: SwitchListTile(
                value: true,
                onChanged: (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Notification preferences — coming soon')),
                  );
                },
                title: const Text('Result & visit alerts'),
                subtitle: const Text('Get a ping when something new arrives'),
              ),
            ),
            const SizedBox(height: 24),
            _SectionHeader('Legal'),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Terms of service'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Privacy policy'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(patientAuthControllerProvider.notifier).logout(),
              icon: Icon(Icons.logout, color: theme.colorScheme.error),
              label: Text('Sign out',
                  style: TextStyle(color: theme.colorScheme.error)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.colorScheme.error),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Vedge for Patients v0.1 — W5.5 walking skeleton',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _ProviderRow extends StatelessWidget {
  const _ProviderRow({required this.link});
  final PatientLink link;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        link.isCurrent ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: link.isCurrent
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(link.organizationName),
      subtitle: link.patientNameOnRecord != null
          ? Text('On record as ${link.patientNameOnRecord}')
          : null,
      trailing: link.isCurrent
          ? Text(
              'Current',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
    );
  }
}

class _EmptyProvidersCard extends StatelessWidget {
  const _EmptyProvidersCard({required this.onCheck});
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.travel_explore, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('No linked providers yet',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Run a match scan to discover health records linked to your '
              'name, phone, and date of birth.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
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
