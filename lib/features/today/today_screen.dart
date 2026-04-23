import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/patient_auth_state.dart';
import '../../core/models/appointment.dart';
import '../../core/models/lab_result.dart';
import '../../core/models/prescription.dart';
import '../../core/telemetry/telemetry_service.dart';
import '../../theme/spacing.dart';
import '../../widgets/provider_context_banner.dart';
import '../../widgets/skeleton_list.dart';
import '../../widgets/vedge_app_bar.dart';
import '../../widgets/vedge_button.dart';
import '../../widgets/vedge_card.dart';
import '../../widgets/vedge_empty_state.dart';
import '../../widgets/vedge_pill.dart';
import '../../widgets/vedge_refresh_indicator.dart';

/// Spec §6.8 — Today (renamed from Home).
///
/// 20-second answer to "what should I know?" Active care first, latest
/// results second, get-care actions last. No "coming soon" cards.
final _todaySummaryProvider = FutureProvider.autoDispose((ref) async {
  final data = ref.read(patientDataApiProvider);
  final results = await data.getLabResults();
  final appts = await data.getAppointments();
  final rx = await data.getPrescriptions();
  return _TodaySummary(
    results: results,
    appointments: appts,
    prescriptions: rx,
  );
});

class _TodaySummary {
  final List<PatientLabResult> results;
  final List<PatientAppointment> appointments;
  final List<PatientPrescription> prescriptions;
  const _TodaySummary({
    required this.results,
    required this.appointments,
    required this.prescriptions,
  });
}

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(patientAuthControllerProvider);
    final summary = ref.watch(_todaySummaryProvider);
    final firstName = auth.account?.firstName ?? 'there';
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(telemetryProvider).track('today_seen');
    });

    return Scaffold(
      appBar: const VedgeAppBar(title: 'Today'),
      body: VedgeRefreshIndicator(
        onRefresh: () async {
          await ref
              .read(patientAuthControllerProvider.notifier)
              .refreshLinks();
          ref.invalidate(_todaySummaryProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            VedgeSpacing.space4,
            VedgeSpacing.space2,
            VedgeSpacing.space4,
            VedgeSpacing.space8,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VedgeSpacing.space2,
                VedgeSpacing.space2,
                VedgeSpacing.space2,
                VedgeSpacing.space2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_greeting()}, $firstName',
                    style: t.headlineSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('EEEE, d MMMM').format(DateTime.now()),
                    style:
                        t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (auth.links.length > 1 && auth.currentLink != null)
              ProviderContextBanner(
                providerName: auth.currentLink!.organizationName,
              ),
            summary.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: VedgeSpacing.space4),
                child: SkeletonList(itemCount: 3),
              ),
              error: (err, _) => err is NoCurrentLinkException
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: VedgeSpacing.space8),
                      child: VedgeEmptyState(
                        icon: Icons.local_hospital_outlined,
                        title: 'Pick a provider',
                        body:
                            'Choose which provider you want to view today. '
                            'You can switch between them anytime.',
                        action: VedgeButton(
                          label: 'Pick provider',
                          isFullWidth: false,
                          onPressed: () => context.go('/you'),
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: VedgeSpacing.space4),
                      child: VedgeCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Couldn't load your data",
                                style: t.titleMedium),
                            const SizedBox(height: VedgeSpacing.space2),
                            Text(
                              'Pull down to try again.',
                              style: t.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
              data: (s) => _TodayBody(summary: s),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _TodayBody extends StatelessWidget {
  const _TodayBody({required this.summary});
  final _TodaySummary summary;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final upcoming = summary.appointments.where((a) => !a.isPast).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final activeRx = summary.prescriptions.where((p) => p.isActive).toList();
    final newResults = summary.results.take(3).toList();

    final hasCareSoon = upcoming.isNotEmpty || activeRx.isNotEmpty;
    final hasNewResults = newResults.isNotEmpty;

    if (!hasCareSoon && !hasNewResults) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: VedgeSpacing.space8),
        child: VedgeEmptyState(
          icon: Icons.spa_rounded,
          title: 'Nothing new today',
          body:
              "Your records will appear here as your provider releases them. "
              "We'll notify you when something arrives.",
          action: VedgeButton(
            label: 'Add another provider',
            variant: VedgeButtonVariant.secondary,
            isFullWidth: false,
            onPressed: () => context.push('/onboarding/find-records'),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasCareSoon) ...[
          const SizedBox(height: VedgeSpacing.space4),
          _SectionHeader('Care soon', count: upcoming.length + activeRx.length),
          for (final a in upcoming.take(2)) ...[
            const SizedBox(height: VedgeSpacing.space2),
            _AppointmentCard(appt: a),
          ],
          for (final r in activeRx.take(2)) ...[
            const SizedBox(height: VedgeSpacing.space2),
            _PrescriptionCard(rx: r),
          ],
        ],
        if (hasNewResults) ...[
          const SizedBox(height: VedgeSpacing.space6),
          _SectionHeader('New for you', count: newResults.length),
          for (final r in newResults) ...[
            const SizedBox(height: VedgeSpacing.space2),
            _ResultCard(result: r),
          ],
        ],
        const SizedBox(height: VedgeSpacing.space6),
        _SectionHeader('Get care'),
        const SizedBox(height: VedgeSpacing.space2),
        VedgeButton(
          label: 'Book a video consult',
          icon: Icons.videocam_outlined,
          variant: VedgeButtonVariant.secondary,
          onPressed: () => context.push('/teleconsult/browse'),
        ),
        const SizedBox(height: VedgeSpacing.space2),
        VedgeButton(
          label: 'Add another provider',
          icon: Icons.add_rounded,
          variant: VedgeButtonVariant.secondary,
          onPressed: () => context.push('/onboarding/find-records'),
        ),
        const SizedBox(height: VedgeSpacing.space6),
        Text(
          'Vedge is a records tool, not diagnosis. Always talk to your '
          'clinician.',
          style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label, {this.count});
  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(VedgeSpacing.space2, 0, 0, 0),
      child: Semantics(
        header: true,
        label: count == null ? label : '$label, $count items',
        child: ExcludeSemantics(
          child: Row(
            children: [
              Text(
                label.toUpperCase(),
                style: t.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appt});
  final PatientAppointment appt;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final dt = appt.scheduledDateTime;
    final whenLabel = dt == null
        ? 'Scheduled'
        : DateFormat('EEEE, d MMM · h:mm a').format(dt);

    return VedgeCard(
      variant: VedgeCardVariant.tappable,
      onTap: () => context.push('/care/visit/${appt.id}'),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded, size: 24),
          const SizedBox(width: VedgeSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(whenLabel, style: t.titleMedium),
                const SizedBox(height: 2),
                Text(
                  appt.reason ?? 'Visit',
                  style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({required this.rx});
  final PatientPrescription rx;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return VedgeCard(
      variant: VedgeCardVariant.tappable,
      onTap: () => context.push('/care/rx/${rx.id}'),
      child: Row(
        children: [
          const Icon(Icons.medication_rounded, size: 24),
          const SizedBox(width: VedgeSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rx.medicationName, style: t.titleMedium),
                if (rx.dose != null || rx.frequency != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    [rx.dose, rx.frequency].whereType<String>().join(' · '),
                    style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});
  final PatientLabResult result;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final flagged = result.isAbnormal;
    final tone = flagged ? VedgePillTone.caution : VedgePillTone.positive;
    final pillLabel = flagged ? 'Flagged' : 'Within range';

    final dt = result.performedAt != null
        ? DateTime.tryParse(result.performedAt!)
        : null;
    final dateLabel = dt != null ? DateFormat('d MMM').format(dt) : '';
    final value =
        result.unit == null ? result.value : '${result.value} ${result.unit}';

    return VedgeCard(
      variant: VedgeCardVariant.tappable,
      onTap: () => context.push('/records/result/${result.id}'),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(VedgeSpacing.radiusSm + 2),
            ),
            child: const Icon(Icons.science_outlined, size: 22),
          ),
          const SizedBox(width: VedgeSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.testName, style: t.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '${value.isEmpty ? '' : '$value · '}$dateLabel',
                  style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          VedgePill(label: pillLabel, tone: tone),
        ],
      ),
    );
  }
}
