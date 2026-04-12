import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/patient_teleconsult_api.dart';
import '../../core/auth/patient_auth_state.dart';
import '../../core/models/patient_link.dart';
import '../../core/models/provider_summary.dart';
import 'teleconsult_book_sheet.dart';

/// Pulls the verified links for the signed-in patient and exposes them as
/// the set of organizations we can browse providers for.
final _verifiedLinksProvider = Provider<List<PatientLink>>((ref) {
  final auth = ref.watch(patientAuthControllerProvider);
  return auth.links.where((l) => l.isVerified).toList(growable: false);
});

final _selectedOrgIdProvider = StateProvider<String?>((ref) {
  // Default to the current link's orgId if we have one.
  final auth = ref.watch(patientAuthControllerProvider);
  return auth.currentLink?.organizationId ??
      auth.links.where((l) => l.isVerified).firstOrNull?.organizationId;
});

final _providersForOrgProvider = FutureProvider.autoDispose
    .family<List<ProviderSummary>, String>((ref, orgId) async {
  return ref.read(patientTeleconsultApiProvider).listProviders(orgId);
});

class TeleconsultBrowseScreen extends ConsumerWidget {
  const TeleconsultBrowseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = ref.watch(_verifiedLinksProvider);
    final selectedOrgId = ref.watch(_selectedOrgIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Find a doctor')),
      body: SafeArea(
        child: Column(
          children: [
            if (links.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: _OrgPicker(
                  links: links,
                  selectedOrgId: selectedOrgId,
                  onChanged: (orgId) =>
                      ref.read(_selectedOrgIdProvider.notifier).state = orgId,
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: selectedOrgId == null
                  ? _EmptyHint(
                      icon: Icons.info_outline,
                      title: 'No verified providers',
                      body:
                          'Link and verify a provider from the Me tab before '
                          'booking a video consult.',
                    )
                  : _ProviderListBody(
                      organizationId: selectedOrgId,
                      onPickProvider: (p) => _openBookSheet(context, p),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openBookSheet(
      BuildContext context, ProviderSummary provider) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => TeleconsultBookSheet(provider: provider),
    );
  }
}

class _OrgPicker extends StatelessWidget {
  const _OrgPicker({
    required this.links,
    required this.selectedOrgId,
    required this.onChanged,
  });
  final List<PatientLink> links;
  final String? selectedOrgId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(
          children: [
            Icon(Icons.local_hospital_outlined,
                color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedOrgId,
                  items: [
                    for (final l in links)
                      DropdownMenuItem(
                        value: l.organizationId,
                        child: Text(l.organizationName),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) onChanged(v);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderListBody extends ConsumerWidget {
  const _ProviderListBody({
    required this.organizationId,
    required this.onPickProvider,
  });
  final String organizationId;
  final ValueChanged<ProviderSummary> onPickProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_providersForOrgProvider(organizationId));
    return RefreshIndicator(
      onRefresh: () async =>
          ref.invalidate(_providersForOrgProvider(organizationId)),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _EmptyHint(
          icon: Icons.error_outline,
          title: 'Couldn\'t load providers',
          body: 'Pull down to try again.',
        ),
        data: (providers) {
          if (providers.isEmpty) {
            return _EmptyHint(
              icon: Icons.person_off_outlined,
              title: 'No doctors available',
              body:
                  'No providers at this organization have open video slots. '
                  'Try again later.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: providers.length,
            itemBuilder: (_, i) =>
                _ProviderCard(provider: providers[i], onTap: onPickProvider),
          );
        },
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider, required this.onTap});
  final ProviderSummary provider;
  final ValueChanged<ProviderSummary> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = provider.roleLabel;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onTap(provider),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    provider.initials,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(provider.displayName,
                          style: theme.textTheme.titleMedium),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        provider.openSlotCount == 0
                            ? 'No open slots'
                            : '${provider.openSlotCount} open slot'
                                '${provider.openSlotCount == 1 ? '' : 's'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: provider.openSlotCount == 0
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.primary,
                        ),
                      ),
                      if (provider.feeGhs != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'GHS ${provider.feeGhs!.toStringAsFixed(2)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
