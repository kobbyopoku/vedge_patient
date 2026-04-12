import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/prescription.dart';
import 'prescriptions_screen.dart';

class PrescriptionDetailScreen extends ConsumerWidget {
  const PrescriptionDetailScreen({super.key, required this.prescriptionId});
  final String prescriptionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(prescriptionsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Prescription')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load: $e')),
        data: (rxList) {
          PatientPrescription? rx;
          for (final r in rxList) {
            if (r.id == prescriptionId) {
              rx = r;
              break;
            }
          }
          if (rx == null) {
            return const Center(child: Text('Prescription not found.'));
          }
          final r = rx;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(r.medicationName, style: theme.textTheme.headlineSmall),
              if (r.organizationName != null) ...[
                const SizedBox(height: 4),
                Text(r.organizationName!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
              ],
              const SizedBox(height: 20),
              Card(
                child: Column(
                  children: [
                    if (r.dose != null)
                      _Row(
                          icon: Icons.straighten,
                          label: 'Dose',
                          value: r.dose!),
                    if (r.frequency != null) ...[
                      const Divider(height: 1),
                      _Row(
                          icon: Icons.schedule,
                          label: 'Frequency',
                          value: r.frequency!),
                    ],
                    if (r.route != null) ...[
                      const Divider(height: 1),
                      _Row(
                          icon: Icons.swap_horiz,
                          label: 'Route',
                          value: r.route!),
                    ],
                    const Divider(height: 1),
                    _Row(
                        icon: Icons.flag_outlined,
                        label: 'Status',
                        value: r.status),
                    if (r.refillsRemaining != null) ...[
                      const Divider(height: 1),
                      _Row(
                          icon: Icons.replay,
                          label: 'Refills',
                          value: r.refillsRemaining.toString()),
                    ],
                    if (r.prescriberName != null) ...[
                      const Divider(height: 1),
                      _Row(
                          icon: Icons.person_outline,
                          label: 'Prescribed by',
                          value: r.prescriberName!),
                    ],
                  ],
                ),
              ),
              if (r.instructions != null) ...[
                const SizedBox(height: 16),
                Text('Instructions', style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(r.instructions!, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Refill flow — coming soon')),
                  );
                },
                icon: const Icon(Icons.autorenew),
                label: const Text('Request refill'),
              ),
              const SizedBox(height: 16),
              Text(
                'Always take medications as prescribed. If something doesn\'t '
                'look right, call your clinician.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
