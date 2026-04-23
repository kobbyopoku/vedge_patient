import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/patient_teleconsult_api.dart';
import '../../core/models/teleconsult_session.dart';
import '../../core/telemetry/telemetry_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/vedge_button.dart';

/// Spec §6.16 — Paystack callback reconciliation.
///
/// BACKEND-DEPENDENT: requires Paystack `callback_url` configured to a
/// deep-link-friendly URL such as `https://app.vedge.health/payment-return?ref=:ref`
/// that resolves to this screen. Until that's in place, the launch flow
/// can still route here manually after the user returns from the browser.
///
/// Polling strategy: every 1.5s for up to 8s, then fail. State machine
/// extracted to [PaymentPollState] so it's unit-testable.
enum PaymentPollPhase { verifying, success, failed }

class PaymentPollState {
  const PaymentPollState({
    required this.phase,
    this.session,
    this.attempts = 0,
  });
  final PaymentPollPhase phase;
  final TeleconsultSession? session;
  final int attempts;

  PaymentPollState copyWith({
    PaymentPollPhase? phase,
    TeleconsultSession? session,
    int? attempts,
  }) =>
      PaymentPollState(
        phase: phase ?? this.phase,
        session: session ?? this.session,
        attempts: attempts ?? this.attempts,
      );

  /// Pure transition: given the current state, the latest session result,
  /// and an elapsed budget in milliseconds, return the next state.
  ///
  /// Rules (spec §6.16):
  /// * [TeleconsultSession.isPaid] true → success.
  /// * Reached attempt cap or elapsed >= [maxElapsedMs] without success → failed.
  /// * Otherwise → verifying with attempts incremented.
  static PaymentPollState reduce({
    required PaymentPollState current,
    required TeleconsultSession? polled,
    required int elapsedMs,
    int maxElapsedMs = 8000,
    int maxAttempts = 6,
  }) {
    if (polled != null && polled.isPaid) {
      return current.copyWith(
        phase: PaymentPollPhase.success,
        session: polled,
      );
    }
    final nextAttempts = current.attempts + 1;
    if (nextAttempts >= maxAttempts || elapsedMs >= maxElapsedMs) {
      return current.copyWith(
        phase: PaymentPollPhase.failed,
        session: polled,
        attempts: nextAttempts,
      );
    }
    return current.copyWith(
      phase: PaymentPollPhase.verifying,
      session: polled,
      attempts: nextAttempts,
    );
  }
}

class PaymentReturnScreen extends ConsumerStatefulWidget {
  const PaymentReturnScreen({
    required this.sessionId,
    this.reference,
    super.key,
  });

  final String sessionId;
  final String? reference;

  @override
  ConsumerState<PaymentReturnScreen> createState() =>
      _PaymentReturnScreenState();
}

class _PaymentReturnScreenState extends ConsumerState<PaymentReturnScreen> {
  PaymentPollState _state =
      const PaymentPollState(phase: PaymentPollPhase.verifying);
  Timer? _timer;
  late final Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(telemetryProvider).track('payment_return_seen', {
        'session_id': widget.sessionId,
        if (widget.reference != null) 'reference': widget.reference,
      });
    });
    _scheduleNext();
  }

  void _scheduleNext() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1500), _poll);
  }

  Future<void> _poll() async {
    if (!mounted) return;
    try {
      final session = await ref
          .read(patientTeleconsultApiProvider)
          .getSession(widget.sessionId);
      final next = PaymentPollState.reduce(
        current: _state,
        polled: session,
        elapsedMs: _stopwatch.elapsedMilliseconds,
      );
      if (!mounted) return;
      setState(() => _state = next);
      switch (next.phase) {
        case PaymentPollPhase.verifying:
          _scheduleNext();
          break;
        case PaymentPollPhase.success:
          ref
              .read(telemetryProvider)
              .track('payment_verified_success');
          break;
        case PaymentPollPhase.failed:
          ref
              .read(telemetryProvider)
              .track('payment_verified_failed');
          break;
      }
    } catch (_) {
      // Treat errors as a failed attempt; reduce will eventually flip
      // to failed once the budget is exhausted.
      final next = PaymentPollState.reduce(
        current: _state,
        polled: null,
        elapsedMs: _stopwatch.elapsedMilliseconds,
      );
      if (!mounted) return;
      setState(() => _state = next);
      if (next.phase == PaymentPollPhase.verifying) _scheduleNext();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(VedgeSpacing.space6),
          child: switch (_state.phase) {
            PaymentPollPhase.verifying => _verifying(context),
            PaymentPollPhase.success => _success(context),
            PaymentPollPhase.failed => _failed(context),
          },
        ),
      ),
    );
  }

  Widget _verifying(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 3, color: cs.primary),
          ),
          const SizedBox(height: VedgeSpacing.space4),
          Text(
            'Confirming your payment…',
            style: t.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'This usually takes a few seconds.',
            style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _success(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        const Spacer(),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 350),
          tween: Tween(begin: 0.6, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (_, value, child) =>
              Transform.scale(scale: value, child: child),
          child: Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: VedgeColors.positiveBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: VedgeColors.positive,
              size: 56,
            ),
          ),
        ),
        const SizedBox(height: VedgeSpacing.space6),
        Text('Payment confirmed', style: t.headlineSmall),
        const SizedBox(height: VedgeSpacing.space3),
        Text(
          "Your consult is booked. We'll send you a reminder before it starts.",
          style: t.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        VedgeButton(
          label: 'See my consult',
          onPressed: () {
            ref.read(telemetryProvider).track(
                'payment_return_cta', {'cta': 'see_consult'});
            context.go('/care');
          },
        ),
        const SizedBox(height: VedgeSpacing.space3),
        VedgeButton(
          label: 'Back to Today',
          variant: VedgeButtonVariant.tertiary,
          onPressed: () {
            ref.read(telemetryProvider).track(
                'payment_return_cta', {'cta': 'today'});
            context.go('/today');
          },
        ),
      ],
    );
  }

  Widget _failed(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        const Spacer(),
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            color: VedgeColors.criticalBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            color: VedgeColors.critical,
            size: 56,
          ),
        ),
        const SizedBox(height: VedgeSpacing.space6),
        Text("Payment didn't complete", style: t.headlineSmall),
        const SizedBox(height: VedgeSpacing.space3),
        Text(
          "We haven't charged you. You can try booking again from Care.",
          style: t.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        VedgeButton(
          label: 'Back to Care',
          onPressed: () => context.go('/care'),
        ),
      ],
    );
  }
}
