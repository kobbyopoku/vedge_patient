import 'package:dio/dio.dart';

import '../config.dart';
import '../models/appointment.dart';
import '../models/lab_result.dart';
import '../models/prescription.dart';
import 'api_client.dart';

/// Read-only data endpoints — all scoped to the current organization via the
/// `current_organization_id` claim in the patient JWT.
///
/// Any of these will throw a [NoCurrentLinkException] if the patient JWT has
/// no current link. The api_client interceptor wraps the 409 into a
/// DioException whose `.error` is the [NoCurrentLinkException]; we unwrap
/// it here so calling code can `try { ... } on NoCurrentLinkException`.
class PatientDataApi {
  PatientDataApi(this._client);
  final PatientApiClient _client;

  static const _base = '${VedgePatientConfig.apiPrefix}/my';

  Future<T> _unwrap<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on DioException catch (e) {
      final inner = e.error;
      if (inner is NoCurrentLinkException) throw inner;
      rethrow;
    }
  }

  Future<List<PatientLabResult>> getLabResults() {
    return _unwrap(() async {
      final resp = await _client.dio.get<List<dynamic>>('$_base/lab-results');
      final list = resp.data ?? const [];
      return list
          .whereType<Map>()
          .map((e) => PatientLabResult.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false);
    });
  }

  Future<List<PatientAppointment>> getAppointments() {
    return _unwrap(() async {
      final resp = await _client.dio.get<List<dynamic>>('$_base/appointments');
      final list = resp.data ?? const [];
      return list
          .whereType<Map>()
          .map((e) => PatientAppointment.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false);
    });
  }

  Future<List<PatientPrescription>> getPrescriptions() {
    return _unwrap(() async {
      final resp =
          await _client.dio.get<List<dynamic>>('$_base/prescriptions');
      final list = resp.data ?? const [];
      return list
          .whereType<Map>()
          .map((e) => PatientPrescription.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false);
    });
  }
}
