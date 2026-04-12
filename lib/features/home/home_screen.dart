import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/patient_auth_state.dart';
import '../../core/models/appointment.dart';
import '../../core/models/lab_result.dart';
import '../../core/models/patient_link.dart';
import '../../core/models/prescription.dart';

/// Lightweight home summary — one-shot fetch, no local cache.
/// [NoCurrentLinkException] bubbles out and is caught in the UI layer.
final _homeSummaryProvider = FutureProvider.autoDispose((ref) async {
  final data = ref.read(patientDataApiProvider);
  final results = await data.getLabResults();
  final appts = await data.getAppointments();
  final rx = await data.getPrescriptions();
  return _HomeSummary(
    results: results,
    appointments: appts,
    prescriptions: rx,
  );
});

class _HomeSummary {
  final List<PatientLabResult> results;
  final List<PatientAppointment> appointments;
  final List<PatientPrescription> prescriptions;
  const _HomeSummary({
    required this.results,
    required this.appointments,
    required this.prescriptions,
  });
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(patientAuthControllerProvider);
    final summary = ref.watch(_homeSummaryProvider);
    final firstName = auth.account?.firstName ?? 'there';

    return Scaffold(
      appBar: AppBar(
        title: Text('${_greeting()}, $firstName'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(patientAuthControllerProvider.notifier).refreshLinks();
          ref.invalidate(_homeSummaryProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _CurrentProviderCard(
              current: auth.currentLink,
              onSwitch: () => context.go('/claims'),
            ),
            const SizedBox(height: 16),
            Text('Your health', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            summary.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) {
                if (err is NoCurrentLinkException) {
                  return _InfoCard(
                    icon: Icons.info_outline,
                    title: 'Pick a current provider',
                    body:
                        'To see your records, choose which provider to view. '
                        'You can switch between them anytime.',
                    action: FilledButton(
                      onPressed: () => context.go('/me'),
                      child: const Text('Choose provider'),
                    ),
                  );
                }
                return _InfoCard(
                  icon: Icons.error_outline,
                  title: 'Couldn\'t load your data',
                  body: 'Pull down to try again.',
                );
              },
              data: (s) => Column(
                children: [
                  _FeatureCard(
                    icon: Icons.science_outlined,
                    title: 'Latest results',
                    subtitle: s.results.isEmpty
                        ? 'No results yet'
                        : '${s.results.length} total'
                            '${s.results.where((r) => r.isAbnormal).isEmpty ? '' : ' — ${s.results.where((r) => r.isAbnormal).length} flagged'}',
                    badgeColor: s.results.any((r) => r.isAbnormal)
                        ? const Color(0xFFF59E0B)
                        : null,
                    onTap: () => context.go('/results'),
                  ),
                  const SizedBox(height: 12),
                  _FeatureCard(
                    icon: Icons.event_outlined,
                    title: 'Upcoming visits',
                    subtitle: _nextApptLabel(s.appointments),
                    onTap: () => context.go('/appointments'),
                  ),
                  const SizedBox(height: 12),
                  _FeatureCard(
                    icon: Icons.medication_outlined,
                    title: 'Prescriptions',
                    subtitle: s.prescriptions.where((p) => p.isActive).isEmpty
                        ? 'No active prescriptions'
                        : '${s.prescriptions.where((p) => p.isActive).length} active',
                    onTap: () => context.go('/prescriptions'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Quick actions', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _QuickAction(
              label: 'Book an appointment',
              icon: Icons.add_circle_outline,
              comingSoon: true,
            ),
            const SizedBox(height: 8),
            _QuickAction(
              label: 'Find a pharmacy',
              icon: Icons.local_pharmacy_outlined,
              comingSoon: true,
            ),
          ],
        ),
      ),
    );
  }

  String _nextApptLabel(List<PatientAppointment> appts) {
    final upcoming = appts.where((a) => !a.isPast).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    if (upcoming.isEmpty) return 'No upcoming visits';
    final next = upcoming.first.scheduledDateTime;
    if (next == null) return '${upcoming.length} scheduled';
    return 'Next ${_dayLabel(next)}';
  }

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final diff = d.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'tomorrow';
    if (diff < 7) return 'in $diff days';
    return 'on ${d.day}/${d.month}';
  }
}

class _CurrentProviderCard extends StatelessWidget {
  const _CurrentProviderCard({required this.current, required this.onSwitch});
  final PatientLink? current;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final name = current?.organizationName ?? 'No provider selected';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: cs.primary.withValues(alpha: 0.12),
              child: Icon(Icons.local_hospital_outlined, color: cs.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current provider', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 2),
                  Text(name, style: theme.textTheme.titleMedium),
                ],
              ),
            ),
            TextButton(onPressed: onSwitch, child: const Text('Switch')),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeColor,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (badgeColor ?? cs.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: badgeColor ?? cs.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            if (action != null) ...[
              const SizedBox(height: 14),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    this.comingSoon = false,
  });
  final String label;
  final IconData icon;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: comingSoon
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$label — coming soon')),
                );
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: cs.primary),
              const SizedBox(width: 14),
              Expanded(child: Text(label, style: theme.textTheme.titleMedium)),
              if (comingSoon)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('soon',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      )),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
