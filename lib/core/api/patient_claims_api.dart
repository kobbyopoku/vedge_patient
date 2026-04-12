import '../config.dart';
import '../models/patient_link.dart';
import '../models/patient_token.dart';
import 'api_client.dart';

/// Cross-tenant claim flow endpoints (W5.4 `/api/patient/my/*`).
class PatientClaimsApi {
  PatientClaimsApi(this._client);
  final PatientApiClient _client;

  static const _base = '${VedgePatientConfig.apiPrefix}/my';

  /// Everything currently linked to this account (any claim status).
  Future<List<PatientLink>> getLinks() async {
    final resp = await _client.dio.get<List<dynamic>>('$_base/links');
    final list = resp.data ?? const [];
    return list
        .whereType<Map>()
        .map((e) => PatientLink.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  /// Run a cross-tenant scan for records matching this account's name + DOB +
  /// phone. Returns newly created PENDING links (the backend dedupes).
  Future<List<PatientLink>> potentialMatches() async {
    final resp = await _client.dio.post<List<dynamic>>(
      '$_base/potential-matches',
    );
    final list = resp.data ?? const [];
    return list
        .whereType<Map>()
        .map((e) => PatientLink.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  /// v1 trust-based confirm: flips PENDING → VERIFIED.
  Future<PatientLink> confirm(String linkId) async {
    final resp = await _client.dio.post<Map<String, dynamic>>(
      '$_base/links/$linkId/confirm',
    );
    return PatientLink.fromJson(resp.data ?? const {});
  }

  /// Switch the current provider. Returns a fresh token pair with the new
  /// `current_organization_id` / `current_patient_id` claims — the caller
  /// MUST overwrite stored tokens with this response.
  Future<PatientTokenResponse> setCurrent(String linkId) async {
    final resp = await _client.dio.post<Map<String, dynamic>>(
      '$_base/links/$linkId/set-current',
    );
    return PatientTokenResponse.fromJson(resp.data ?? const {});
  }
}
