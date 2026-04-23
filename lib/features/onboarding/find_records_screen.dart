import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/patient_auth_state.dart';
import '../../core/config/feature_flags.dart';
import '../../core/models/patient_link.dart';
import '../../core/telemetry/telemetry_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/skeleton_list.dart';
import '../../widgets/vedge_app_bar.dart';
import '../../widgets/vedge_button.dart';
import '../../widgets/vedge_card.dart';
import '../../widgets/vedge_empty_state.dart';
import '../../widgets/vedge_pill.dart';

/// Spec §6.6 — Find your records (renamed from "Potential matches").
///
/// Vocabulary swap (spec §8.1) applied throughout. Match evidence pills
/// rendered when backend returns a `matchEvidence` field; gracefully omitted
/// otherwise (BACKEND-DEPENDENT).
///
/// SECURITY P0: when [FeatureFlags.verificationCodeEnabled] is false, the
/// "Yes, this is me" CTA does NOT call the legacy trust-based confirm
/// endpoint. Instead it shows an inline "Verification coming soon" banner
/// and disables linking. This is the deliberate, explicit choice the
/// security review demanded.
class FindRecordsScreen extends ConsumerStatefulWidget {
  const FindRecordsScreen({super.key});

  @override
  ConsumerState<FindRecordsScreen> createState() => _FindRecordsScreenState();
}

class _FindRecordsScreenState extends ConsumerState<FindRecordsScreen> {
  bool _scanning = false;
  String? _error;
  List<PatientLink> _matches = const [];
  final Set<String> _rejecting = {};
  bool _verificationBannerSeen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(telemetryProvider).track('find_records_seen');
      _scan();
    });
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _error = null;
    });
    try {
      final api = ref.read(patientClaimsApiProvider);
      final found = await api.potentialMatches();
      // Defensive dedupe by link id.
      final dedup = <String, PatientLink>{};
      for (final l in found) {
        dedup[l.id] = l;
      }
      setState(() {
        _matches = dedup.values.where((l) => l.isPending).toList();
        _scanning = false;
      });
      ref.read(telemetryProvider).track('find_records_scan_complete', {
        'match_count': _matches.length,
      });
    } catch (e) {
      setState(() {
        _scanning = false;
        _error = "Couldn't finish — pull to retry.";
      });
    }
  }

  Future<void> _reject(PatientLink link) async {
    setState(() => _rejecting.add(link.id));
    try {
      await ref.read(patientClaimsApiProvider).reject(link.id);
      ref.read(telemetryProvider).track('find_records_match_rejected');
      setState(() {
        _matches = _matches.where((l) => l.id != link.id).toList();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't update — try again later.")),
      );
    } finally {
      if (mounted) {
        setState(() => _rejecting.remove(link.id));
      }
    }
  }

  void _openVerify(PatientLink link) {
    ref.read(telemetryProvider).track('find_records_match_confirmed');
    if (!FeatureFlags.verificationCodeEnabled) {
      // Security gate — show explanatory state, do NOT auto-confirm.
      setState(() => _verificationBannerSeen = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verification coming soon — your records will appear once '
            "${link.organizationName} confirms it's you.",
          ),
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }
    context.push('/onboarding/verify-link/${link.id}', extra: link);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const VedgeAppBar(
        title: 'Find your records',
        showBack: true,
        showProviderContext: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: cs.primary,
          backgroundColor: cs.surfaceContainerHighest,
          onRefresh: _scan,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              VedgeSpacing.space4,
              0,
              VedgeSpacing.space4,
              VedgeSpacing.space8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VedgeSpacing.space2,
                    vertical: VedgeSpacing.space4,
                  ),
                  child: Text(
                    "We'll look across Vedge providers for records that match "
                    'your name, phone, and date of birth. Only you can confirm '
                    "what's yours.",
                    style: t.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                if (_verificationBannerSeen &&
                    !FeatureFlags.verificationCodeEnabled) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: VedgeSpacing.space4),
                    padding: const EdgeInsets.all(VedgeSpacing.space3),
                    decoration: BoxDecoration(
                      color: VedgeColors.cautionBg,
                      borderRadius:
                          BorderRadius.circular(VedgeSpacing.radiusMd),
                      border: Border.all(
                          color: VedgeColors.caution.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'Provider verification is rolling out. We will not link '
                      "any records until your provider confirms it's you. "
                      "We'll notify you the moment it's ready.",
                      style:
                          t.bodyMedium?.copyWith(color: VedgeColors.caution),
                    ),
                  ),
                ],
                if (_scanning && _matches.isEmpty)
                  const SkeletonList(itemCount: 3)
                else if (_error != null && _matches.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: VedgeSpacing.space8),
                    child: VedgeEmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: "Couldn't finish the scan",
                      body: _error!,
                      action: VedgeButton(
                        label: 'Try again',
                        onPressed: _scan,
                        isFullWidth: false,
                      ),
                    ),
                  )
                else if (_matches.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: VedgeSpacing.space8),
                    child: VedgeEmptyState(
                      icon: Icons.local_hospital_outlined,
                      title: 'No records found yet',
                      body:
                          "We'll keep looking. When a provider shares records "
                          "that match your details, we'll show them here.",
                    ),
                  )
                else
                  for (final m in _matches) ...[
                    _MatchCard(
                      link: m,
                      isRejecting: _rejecting.contains(m.id),
                      onYes: () => _openVerify(m),
                      onNo: () => _reject(m),
                    ),
                    const SizedBox(height: VedgeSpacing.space3),
                  ],
                if (_scanning && _matches.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(VedgeSpacing.space4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: VedgeSpacing.space2),
                        Text(
                          'Still scanning…',
                          style: t.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: VedgeSpacing.space8),
                VedgeButton(
                  label: 'Continue',
                  variant: VedgeButtonVariant.secondary,
                  onPressed: () {
                    ref.read(telemetryProvider).track('find_records_continue');
                    // Route to /you (the shell's You tab). Was /today
                    // previously but the router rejected that for a
                    // no-claims user, so the user bounced back to
                    // /onboarding/welcome-first in a loop. /you is the
                    // right landing: the user can manage their account,
                    // re-run find-records later, or add NHIS / Ghana
                    // Card to unlock auto-linking.
                    context.go('/you');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.link,
    required this.isRejecting,
    required this.onYes,
    required this.onNo,
  });

  final PatientLink link;
  final bool isRejecting;
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return VedgeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_hospital_rounded, color: cs.onSurface),
              const SizedBox(width: VedgeSpacing.space2),
              Expanded(
                child: Text(link.organizationName, style: t.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: VedgeSpacing.space2),
          if (link.patientNameOnRecord != null) ...[
            Text(
              'On record as ${link.patientNameOnRecord}',
              style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: VedgeSpacing.space2),
          ],
          // Match evidence (BACKEND-DEPENDENT — only renders if present).
          // The current backend doesn't expose `matchEvidence`; we expose a
          // single neutral "Match found" pill until that ships.
          const Wrap(
            spacing: VedgeSpacing.space2,
            runSpacing: VedgeSpacing.space2,
            children: [
              VedgePill(label: 'Match found', tone: VedgePillTone.info),
            ],
          ),
          const SizedBox(height: VedgeSpacing.space4),
          Row(
            children: [
              Expanded(
                child: VedgeButton(
                  label: 'Yes, this is me',
                  size: VedgeButtonSize.medium,
                  onPressed: isRejecting ? null : onYes,
                ),
              ),
              const SizedBox(width: VedgeSpacing.space2),
              Expanded(
                child: VedgeButton(
                  label: 'Not me',
                  variant: VedgeButtonVariant.tertiary,
                  size: VedgeButtonSize.medium,
                  isLoading: isRejecting,
                  onPressed: isRejecting ? null : onNo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
