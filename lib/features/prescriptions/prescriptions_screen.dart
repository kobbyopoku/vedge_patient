import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/patient_auth_state.dart';
import '../../core/models/prescription.dart';

final prescriptionsProvider =
    FutureProvider.autoDispose<List<PatientPrescription>>((ref) async {
  return ref.read(patientDataApiProvider).getPrescriptions();
});

class PrescriptionsScreen extends ConsumerWidget {
  const PrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(prescriptionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Prescriptions')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          if (e is NoCurrentLinkException) return const _NoCurrentCard();
          return Center(
            child: OutlinedButton(
              onPressed: () => ref.invalidate(prescriptionsProvider),
              child: const Text('Try again'),
            ),
          );
        },
        data: (rx) {
          if (rx.isEmpty) {
            return const _Empty();
          }
          final active = rx.where((p) => p.isActive).toList();
          final inactive = rx.where((p) => !p.isActive).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              if (active.isNotEmpty) ...[
                _Section(title: 'Active'),
                for (final p in active) _RxTile(rx: p),
                const SizedBox(height: 16),
              ],
              if (inactive.isNotEmpty) ...[
                _Section(title: 'Filled & past'),
                for (final p in inactive) _RxTile(rx: p),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _RxTile extends StatelessWidget {
  const _RxTile({required this.rx});
  final PatientPrescription rx;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sub = [
      if (rx.dose != null) rx.dose,
      if (rx.frequency != null) rx.frequency,
    ].whereType<String>().join(' • ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          onTap: () => context.go('/prescriptions/${rx.id}'),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.medication,
                      color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rx.medicationName,
                          style: theme.textTheme.titleMedium),
                      if (sub.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(sub,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            )),
                      ],
                      if (rx.prescriberName != null) ...[
                        const SizedBox(height: 2),
                        Text('Prescribed by ${rx.prescriberName}',
                            style: theme.textTheme.bodySmall),
                      ],
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

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medication_outlined,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('No prescriptions', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'New prescriptions from your current provider will show up here.',
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

class _NoCurrentCard extends StatelessWidget {
  const _NoCurrentCard();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline,
                size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('Pick a current provider',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go('/me'),
              child: const Text('Go to Me'),
            ),
          ],
        ),
      ),
    );
  }
}
