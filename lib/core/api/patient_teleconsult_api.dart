import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/patient_auth_state.dart';
import '../config.dart';
import '../models/availability_slot.dart';
import '../models/provider_summary.dart';
import '../models/teleconsult_join.dart';
import '../models/teleconsult_session.dart';
import 'api_client.dart';

/// Result of a successful booking — wraps the session id and the Paystack
/// checkout URL we need to launch in the device browser.
class BookSessionResult {
  final String sessionId;
  final String paystackCheckoutUrl;
  final String? paystackReference;
  final TeleconsultSession session;

  const BookSessionResult({
    required this.sessionId,
    required this.paystackCheckoutUrl,
    required this.session,
    this.paystackReference,
  });
}

/// Patient-side teleconsult API. All endpoints live under
/// `/api/patient/my/teleconsults/*` and are auto-authenticated by the
/// existing [PatientApiClient] interceptor.
class PatientTeleconsultApi {
  PatientTeleconsultApi(this._client);
  final PatientApiClient _client;

  static const _base = '${VedgePatientConfig.apiPrefix}/my/teleconsults';

  Future<T> _unwrap<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on DioException catch (e) {
      final inner = e.error;
      if (inner is NoCurrentLinkException) throw inner;
      rethrow;
    }
  }

  Future<List<ProviderSummary>> listProviders(String organizationId) {
    return _unwrap(() async {
      final resp = await _client.dio.get<List<dynamic>>(
        '$_base/providers',
        queryParameters: {'organizationId': organizationId},
      );
      final list = resp.data ?? const [];
      return list
          .whereType<Map>()
          .map((e) => ProviderSummary.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false);
    });
  }

  Future<List<AvailabilitySlot>> listSlotsForProvider(
    String providerUserId,
    DateTime from,
    DateTime to,
  ) {
    return _unwrap(() async {
      final resp = await _client.dio.get<List<dynamic>>(
        '$_base/providers/$providerUserId/slots',
        queryParameters: {
          // Spring's @RequestParam Instant parser accepts ISO-8601 with
          // trailing Z — always send UTC.
          'from': from.toUtc().toIso8601String(),
          'to': to.toUtc().toIso8601String(),
        },
      );
      final list = resp.data ?? const [];
      return list
          .whereType<Map>()
          .map((e) => AvailabilitySlot.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false);
    });
  }

  Future<BookSessionResult> book({
    required String providerUserId,
    required String slotId,
    String? reason,
    double? amountGhs,
  }) {
    return _unwrap(() async {
      final resp = await _client.dio.post<Map<String, dynamic>>(
        '$_base/book',
        data: {
          'providerUserId': providerUserId,
          'slotId': slotId,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
          if (amountGhs != null) 'amountGhs': amountGhs,
        },
      );
      final body = resp.data ?? const <String, dynamic>{};
      final sessionJson = (body['session'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      final session = TeleconsultSession.fromJson(sessionJson);
      return BookSessionResult(
        sessionId: session.id,
        paystackCheckoutUrl: body['paystackCheckoutUrl']?.toString() ?? '',
        paystackReference: body['paystackReference']?.toString(),
        session: session,
      );
    });
  }

  Future<List<TeleconsultSession>> listMySessions() {
    return _unwrap(() async {
      final resp = await _client.dio.get<List<dynamic>>(_base);
      final list = resp.data ?? const [];
      return list
          .whereType<Map>()
          .map((e) => TeleconsultSession.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false);
    });
  }

  Future<TeleconsultSession> getSession(String sessionId) {
    return _unwrap(() async {
      final resp =
          await _client.dio.get<Map<String, dynamic>>('$_base/$sessionId');
      return TeleconsultSession.fromJson(resp.data ?? const {});
    });
  }

  Future<TeleconsultJoin> getJoinUrl(String sessionId) {
    return _unwrap(() async {
      final resp = await _client.dio
          .get<Map<String, dynamic>>('$_base/$sessionId/join-url');
      return TeleconsultJoin.fromJson(resp.data ?? const {});
    });
  }

  Future<void> cancelSession(String sessionId, String reason) {
    return _unwrap(() async {
      await _client.dio.post<void>(
        '$_base/$sessionId/cancel',
        data: {'reason': reason},
      );
    });
  }
}

/// Riverpod provider — piggybacks on the shared [PatientApiClient].
final patientTeleconsultApiProvider = Provider<PatientTeleconsultApi>(
  (ref) => PatientTeleconsultApi(ref.watch(patientApiClientProvider)),
);
