import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/patient_auth_state.dart';
import '../../core/config/feature_flags.dart';
import '../../core/models/patient_link.dart';
import '../../core/telemetry/telemetry_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/otp_field.dart';
import '../../widgets/vedge_app_bar.dart';
import '../../widgets/vedge_button.dart';
import '../../widgets/vedge_sheet.dart';

/// Spec §6.7 — verify a pending link with a provider-issued OTP.
///
/// SECURITY GATE: gated on [FeatureFlags.verificationCodeEnabled]. With the
/// flag false (v1 default), this screen renders a "Verification coming soon"
/// state that does NOT call any backend endpoint. With the flag true, the
/// 6-cell OTP submits to `/links/:id/verify-with-code`.
///
/// The "Skip and link without verification" path from the spec is
/// DELIBERATELY OMITTED — that would silently call the legacy trust-based
/// `confirm` endpoint, which is the precise security regression the review
/// flagged. The only way to confirm a link in v1 is when the backend
/// confirms via verification code.
class VerifyLinkScreen extends ConsumerStatefulWidget {
  const VerifyLinkScreen({
    required this.linkId,
    this.link,
    super.key,
  });

  final String linkId;
  final PatientLink? link;

  @override
  ConsumerState<VerifyLinkScreen> createState() => _VerifyLinkScreenState();
}

class _VerifyLinkScreenState extends ConsumerState<VerifyLinkScreen> {
  bool _submitting = false;
  String? _error;
  bool _requestingFreshCode = false;

  String get _orgName =>
      widget.link?.organizationName ?? 'your provider';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(telemetryProvider).track('verify_link_seen', {
        'verification_enabled': FeatureFlags.verificationCodeEnabled,
      });
    });
  }

  Future<void> _verify(String code) async {
    if (!FeatureFlags.verificationCodeEnabled) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final telemetry = ref.read(telemetryProvider);
    telemetry.track('verify_link_code_attempt');
    try {
      await ref
          .read(patientClaimsApiProvider)
          .verifyWithCode(widget.linkId, code);
      // Refresh the auth state so the new VERIFIED link surfaces.
      await ref
          .read(patientAuthControllerProvider.notifier)
          .refreshLinks();
      if (!mounted) return;
      telemetry.track('verify_link_success');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Linked to $_orgName')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      final humanized = _humanize(e);
      telemetry.track('verify_link_error', {'error': humanized});
      setState(() {
        _submitting = false;
        _error = humanized;
      });
    }
  }

  Future<void> _requestFreshCode() async {
    if (!FeatureFlags.verificationCodeEnabled) return;
    setState(() => _requestingFreshCode = true);
    try {
      await ref
          .read(patientClaimsApiProvider)
          .requestVerificationCode(widget.linkId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Code sent. $_orgName will text you shortly.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Couldn't request a fresh code. Try again in a few minutes."),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _requestingFreshCode = false);
      }
    }
  }

  String _humanize(Object e) {
    final msg = e.toString();
    if (msg.contains('400') || msg.contains('401')) {
      return "That code didn't match. Try again or request a fresh one.";
    }
    if (msg.contains('410') || msg.contains('EXPIRED')) {
      return 'That code expired. Tap "Send me a fresh code" below.';
    }
    if (msg.contains('429')) {
      return 'For your security, wait 1 minute before trying again.';
    }
    if (msg.contains('Connection') || msg.contains('SocketException')) {
      return 'Network error. Check your connection and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final enabled = FeatureFlags.verificationCodeEnabled;

    return Scaffold(
      appBar: VedgeAppBar(
        title: enabled ? 'Verify $_orgName link' : 'Almost there',
        showBack: true,
        showProviderContext: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            VedgeSpacing.space6,
            0,
            VedgeSpacing.space6,
            VedgeSpacing.space8,
          ),
          child: enabled
              ? _enabledBody(context, t, cs)
              : _disabledBody(context, t, cs),
        ),
      ),
    );
  }

  Widget _enabledBody(BuildContext context, TextTheme t, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'To protect your records, $_orgName issued a 6-digit code at your '
          'last visit. Enter it below to confirm this account is yours.',
          style: t.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: VedgeSpacing.space3),
        Align(
          alignment: Alignment.centerLeft,
          child: VedgeButton(
            label: "Where do I find this?",
            variant: VedgeButtonVariant.tertiary,
            isFullWidth: false,
            onPressed: () => _showHelpSheet(context),
          ),
        ),
        const SizedBox(height: VedgeSpacing.space6),
        OtpField(
          onCompleted: _verify,
          isVerifying: _submitting,
          errorText: _error,
        ),
        const SizedBox(height: VedgeSpacing.space4),
        Center(
          child: VedgeButton(
            label: 'Send me a fresh code',
            variant: VedgeButtonVariant.tertiary,
            isFullWidth: false,
            isLoading: _requestingFreshCode,
            onPressed: _requestingFreshCode ? null : _requestFreshCode,
          ),
        ),
      ],
    );
  }

  /// The flag-disabled state. Renders an honest explanation and routes the
  /// patient back to find-records — no auto-confirm, no degraded fallback.
  Widget _disabledBody(BuildContext context, TextTheme t, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(VedgeSpacing.space4),
          decoration: BoxDecoration(
            color: VedgeColors.cautionBg,
            borderRadius: BorderRadius.circular(VedgeSpacing.radiusLg),
            border: Border.all(color: VedgeColors.caution.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_rounded,
                  color: VedgeColors.caution, size: 28),
              const SizedBox(height: VedgeSpacing.space3),
              Text(
                'Verification coming soon',
                style: t.titleMedium
                    ?.copyWith(color: VedgeColors.caution),
              ),
              const SizedBox(height: VedgeSpacing.space2),
              Text(
                'Your records will appear once $_orgName confirms '
                "it's you. We'll notify you the moment they're ready.",
                style:
                    t.bodyMedium?.copyWith(color: VedgeColors.caution),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          'Why are we waiting?',
          style: t.titleMedium,
        ),
        const SizedBox(height: VedgeSpacing.space2),
        Text(
          "Your provider hasn't enabled the new verification yet. We won't "
          "link any records until they confirm it's you — that protects "
          'your privacy.',
          style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: VedgeSpacing.space6),
        VedgeButton(
          label: 'Back to find records',
          onPressed: () {
            ref.read(telemetryProvider).track('verify_link_back_to_find');
            context.pop();
          },
        ),
      ],
    );
  }
}

void _showHelpSheet(BuildContext context) {
  showVedgeSheet<void>(
    context: context,
    title: 'Where to find your code',
    builder: (ctx) {
      final t = Theme.of(ctx).textTheme;
      final cs = Theme.of(ctx).colorScheme;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: VedgeSpacing.space2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your provider's clinic prints this code on your receipt at "
              "every visit. If you don't have a recent receipt, ask the "
              'clinic to send you a new one — they can generate one in '
              'seconds.',
              style: t.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: VedgeSpacing.space4),
            VedgeButton(
              label: 'Got it',
              onPressed: () => Navigator.of(ctx).maybePop(),
            ),
          ],
        ),
      );
    },
  );
}
