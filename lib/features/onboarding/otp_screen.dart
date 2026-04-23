import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/patient_auth_api.dart';
import '../../core/auth/patient_auth_state.dart';
import '../../core/telemetry/telemetry_service.dart';
import '../../theme/spacing.dart';
import '../../widgets/otp_field.dart';
import '../../widgets/vedge_app_bar.dart';
import '../../widgets/vedge_button.dart';
import 'complete_profile_screen.dart';

/// Arguments passed from [WelcomeScreen] to [OtpScreen]. V128 phone-first
/// flow carries just the normalized E.164 phone number — the verify-start
/// response itself tells us whether we're logging in or completing signup.
class OtpArgs {
  const OtpArgs({required this.phone});
  const OtpArgs.empty() : phone = '';
  final String phone;
}

/// Spec §6.4 — enter the 6-digit OTP. Calls POST /verify-start; the result
/// is one of:
///   * [VerifyStartExistingAccount] → log the user in (tokens applied to
///     PatientAuthController, routing takes them to /today).
///   * [VerifyStartPendingRegistration] → route to
///     [CompleteProfileScreen] with the short-lived registration JWT.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({required this.args, super.key});
  final OtpArgs args;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen>
    with WidgetsBindingObserver {
  final TextEditingController _codeCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;
  int _resendIn = 30;
  int _resendCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(telemetryProvider).track('otp_seen');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _codeCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendIn = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_resendIn > 0) _resendIn -= 1;
        if (_resendIn == 0) t.cancel();
      });
    });
  }

  Future<void> _onCompleted(String code) async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    final telemetry = ref.read(telemetryProvider);
    telemetry.track('otp_code_typed');

    try {
      final authApi = ref.read(patientAuthApiProvider);
      final result = await authApi.verifyStart(
        phone: widget.args.phone,
        code: code,
      );
      switch (result) {
        case VerifyStartExistingAccount(:final tokens):
          telemetry.track('otp_verify_existing');
          await ref
              .read(patientAuthControllerProvider.notifier)
              .applyTokenResponse(tokens);
          // Auth-state listener routes us out of /otp.
          break;
        case VerifyStartPendingRegistration(
            :final registrationToken,
            :final expiresInSeconds
          ):
          telemetry.track('otp_verify_needs_registration');
          if (!mounted) return;
          context.pushReplacement(
            '/complete-profile',
            extra: CompleteProfileArgs(
              phone: widget.args.phone,
              registrationToken: registrationToken,
              expiresInSeconds: expiresInSeconds,
            ),
          );
          break;
      }
    } catch (e) {
      if (!mounted) return;
      final humanized = _humanize(e);
      telemetry.track('otp_verify_error', {'error': humanized});
      setState(() {
        _error = humanized;
        _submitting = false;
        _codeCtrl.clear();
      });
    }
  }

  Future<void> _resend() async {
    if (_resendIn > 0 || _resendCount >= 3) return;
    final telemetry = ref.read(telemetryProvider);
    telemetry.track('otp_resend_tapped');
    try {
      await ref
          .read(patientAuthApiProvider)
          .startPhoneAuth(phone: widget.args.phone);
      if (!mounted) return;
      setState(() => _resendCount += 1);
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code sent.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _humanize(e));
    }
  }

  String _humanize(Object e) {
    final msg = e.toString();
    if (msg.contains('EXPIRED')) {
      return 'That code expired — tap Resend to get a fresh one.';
    }
    if (msg.contains('400') || msg.contains('401')) {
      return "That code didn't match. Try again.";
    }
    if (msg.contains('429')) {
      return 'For your security, wait 1 minute before trying again.';
    }
    if (msg.contains('Connection') || msg.contains('SocketException')) {
      return 'Network error. Check your connection and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final sent =
        widget.args.phone.isNotEmpty ? widget.args.phone : 'your phone';

    return Scaffold(
      appBar: VedgeAppBar(
        title: 'Check your messages',
        showBack: true,
        showProviderContext: false,
        onBack: _back,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            VedgeSpacing.space6,
            0,
            VedgeSpacing.space6,
            VedgeSpacing.space8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text.rich(
                TextSpan(
                  style: t.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                  children: [
                    const TextSpan(text: 'We sent a 6-digit code to '),
                    TextSpan(
                      text: sent,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: VedgeSpacing.space8),
              OtpField(
                onCompleted: _onCompleted,
                errorText: _error,
                isVerifying: _submitting,
              ),
              const SizedBox(height: VedgeSpacing.space6),
              Center(
                child: _resendCount >= 3
                    ? Text(
                        'Try again in a few minutes',
                        style: t.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      )
                    : _resendIn > 0
                        ? Text(
                            'Resend code in $_resendIn s',
                            style: t.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          )
                        : VedgeButton(
                            label: 'Resend code',
                            variant: VedgeButtonVariant.tertiary,
                            isFullWidth: false,
                            onPressed: _resend,
                          ),
              ),
              const Spacer(),
              VedgeButton(
                label: 'Wrong number? Go back',
                variant: VedgeButtonVariant.tertiary,
                onPressed: _back,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
