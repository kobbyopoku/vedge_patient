import 'package:flutter_test/flutter_test.dart';
import 'package:vedge_patient/core/models/teleconsult_session.dart';
import 'package:vedge_patient/features/care/payment_return_screen.dart';

TeleconsultSession _session({required String paymentStatus}) {
  return TeleconsultSession.fromJson({
    'id': 'sess-1',
    'organizationId': 'org-1',
    'providerUserId': 'p-1',
    'patientLinkId': 'link-1',
    'scheduledStart': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
    'scheduledEnd': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
    'status': 'BOOKED',
    'paymentStatus': paymentStatus,
  });
}

void main() {
  group('PaymentPollState.reduce', () {
    const initial = PaymentPollState(phase: PaymentPollPhase.verifying);

    test('flips to success when polled session is paid', () {
      final next = PaymentPollState.reduce(
        current: initial,
        polled: _session(paymentStatus: 'PAID'),
        elapsedMs: 0,
      );
      expect(next.phase, PaymentPollPhase.success);
      expect(next.session, isNotNull);
    });

    test('stays verifying when polled session is unpaid and budget remains', () {
      final next = PaymentPollState.reduce(
        current: initial,
        polled: _session(paymentStatus: 'PENDING'),
        elapsedMs: 1500,
      );
      expect(next.phase, PaymentPollPhase.verifying);
      expect(next.attempts, 1);
    });

    test('flips to failed when polled-null AND elapsed exceeds budget', () {
      final next = PaymentPollState.reduce(
        current: initial,
        polled: null,
        elapsedMs: 9000,
      );
      expect(next.phase, PaymentPollPhase.failed);
    });

    test('flips to failed when attempts >= cap regardless of elapsed', () {
      const cap = 3;
      var state = initial;
      for (var i = 0; i < cap - 1; i++) {
        state = PaymentPollState.reduce(
          current: state,
          polled: _session(paymentStatus: 'PENDING'),
          elapsedMs: 0,
          maxAttempts: cap,
        );
        expect(state.phase, PaymentPollPhase.verifying);
      }
      // Attempt at the cap should flip to failed.
      state = PaymentPollState.reduce(
        current: state,
        polled: _session(paymentStatus: 'PENDING'),
        elapsedMs: 0,
        maxAttempts: cap,
      );
      expect(state.phase, PaymentPollPhase.failed);
      expect(state.attempts, cap);
    });

    test('paid wins even at the very last attempt', () {
      // Two unsuccessful polls then a success at the cap.
      var state = PaymentPollState.reduce(
        current: initial,
        polled: _session(paymentStatus: 'PENDING'),
        elapsedMs: 1500,
      );
      state = PaymentPollState.reduce(
        current: state,
        polled: _session(paymentStatus: 'PENDING'),
        elapsedMs: 3000,
      );
      // At elapsed >= 8000ms but with paid=true, success still wins.
      state = PaymentPollState.reduce(
        current: state,
        polled: _session(paymentStatus: 'PAID'),
        elapsedMs: 9000,
      );
      expect(state.phase, PaymentPollPhase.success);
    });
  });
}
