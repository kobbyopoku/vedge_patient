import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/patient_auth_state.dart';
import '../../core/models/appointment.dart';

final appointmentsProvider =
    FutureProvider.autoDispose<List<PatientAppointment>>((ref) async {
  return ref.read(patientDataApiProvider).getAppointments();
});

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({this.embedded = false, super.key});
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appointmentsProvider);

    final body = RefreshIndicator(
      onRefresh: () async => ref.invalidate(appointmentsProvider),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          if (e is NoCurrentLinkException) {
            return const _NoCurrentCard();
          }
          return _RetryView(onRetry: () => ref.invalidate(appointmentsProvider));
        },
        data: (appts) {
          if (appts.isEmpty) return const _Empty();
          final upcoming = appts.where((a) => !a.isPast).toList()
            ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
          final past = appts.where((a) => a.isPast).toList()
            ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              if (upcoming.isNotEmpty) ...[
                _Section(title: 'Upcoming'),
                for (final a in upcoming) _AppointmentTile(appt: a),
                const SizedBox(height: 16),
              ],
              if (past.isNotEmpty) ...[
                _Section(title: 'Past'),
                for (final a in past) _AppointmentTile(appt: a),
              ],
            ],
          );
        },
      ),
    );
    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Visits')),
      body: body,
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

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({required this.appt});
  final PatientAppointment appt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dt = appt.scheduledDateTime;
    final dateLabel =
        dt != null ? DateFormat('EEE, d MMM • h:mm a').format(dt) : '—';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          onTap: () => context.push('/care/visit/${appt.id}'),
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
                  child: Icon(Icons.event, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appt.providerName ?? 'Provider',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (appt.reason != null) ...[
                        const SizedBox(height: 2),
                        Text(appt.reason!, style: theme.textTheme.bodySmall),
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
            Icon(Icons.event_busy_outlined,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('No visits yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'When you have appointments with your current provider, '
              'they\'ll show up here.',
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
            const SizedBox(height: 6),
            Text(
              'Choose which provider to view from the Me tab.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/you'),
              child: const Text('Go to You'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RetryView extends StatelessWidget {
  const _RetryView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                color: theme.colorScheme.error, size: 48),
            const SizedBox(height: 12),
            Text('Couldn\'t load visits', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
