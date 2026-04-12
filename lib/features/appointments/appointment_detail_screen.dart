import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/appointment.dart';
import 'appointments_screen.dart';

class AppointmentDetailScreen extends ConsumerWidget {
  const AppointmentDetailScreen({super.key, required this.appointmentId});
  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appointmentsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Visit')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load: $e')),
        data: (appts) {
          PatientAppointment? appt;
          for (final a in appts) {
            if (a.id == appointmentId) {
              appt = a;
              break;
            }
          }
          if (appt == null) {
            return const Center(child: Text('Visit not found.'));
          }
          final dt = appt.scheduledDateTime;
          final dateLabel = dt != null
              ? DateFormat('EEEE, d MMMM yyyy').format(dt)
              : '—';
          final timeLabel = dt != null ? DateFormat('h:mm a').format(dt) : '';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(appt.providerName ?? 'Provider',
                  style: theme.textTheme.headlineSmall),
              if (appt.departmentName != null) ...[
                const SizedBox(height: 4),
                Text(appt.departmentName!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
              ],
              const SizedBox(height: 20),
              Card(
                child: Column(
                  children: [
                    _Row(
                        icon: Icons.calendar_today,
                        label: 'Date',
                        value: dateLabel),
                    const Divider(height: 1),
                    _Row(
                        icon: Icons.access_time,
                        label: 'Time',
                        value: timeLabel),
                    const Divider(height: 1),
                    _Row(
                      icon: Icons.flag_outlined,
                      label: 'Status',
                      value: appt.status,
                    ),
                    if (appt.reason != null) ...[
                      const Divider(height: 1),
                      _Row(
                          icon: Icons.description_outlined,
                          label: 'Reason',
                          value: appt.reason!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (!appt.isPast)
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cancelling appointments — coming soon'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel visit'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(
      {required this.icon, required this.label, required this.value});
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
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
