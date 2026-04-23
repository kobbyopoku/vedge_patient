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
  ///
  /// CALLERS BEWARE — when `FeatureFlags.verificationCodeEnabled` is false
  /// (the v1 default), the find-records UI does NOT route here from the
  /// "Yes, this is me" CTA. The security review's #1 P0 was exactly that:
  /// instant cross-tenant PHI access without out-of-band proof. The verify-
  /// link screen exists to surface this to the user honestly.
  Future<PatientLink> confirm(String linkId) async {
    final resp = await _client.dio.post<Map<String, dynamic>>(
      '$_base/links/$linkId/confirm',
    );
    return PatientLink.fromJson(resp.data ?? const {});
  }

  /// Mark a possible match as not the patient. Backend logs a security
  /// event and stops re-suggesting it on subsequent scans.
  ///
  /// BACKEND-DEPENDENT — endpoint specified in spec §6.6 + §8.4. If the
  /// backend doesn't yet implement /reject, this throws a 404 which the UI
  /// catches and surfaces as "Couldn't update — try again later".
  Future<void> reject(String linkId) async {
    await _client.dio.post<void>('$_base/links/$linkId/reject');
  }

  /// BACKEND-DEPENDENT (security review P0, spec §8.3). Asks the backend to
  /// generate + SMS a fresh verification code to the patient via the
  /// provider's contact. Throttled to 1/24h per link server-side.
  ///
  /// If the backend has not yet shipped this endpoint, callers should catch
  /// the resulting 404 and surface "Verification coming soon" without
  /// falling back to the legacy trust-based confirm.
  Future<void> requestVerificationCode(String linkId) async {
    await _client.dio.post<void>(
      '$_base/links/$linkId/request-verification-code',
    );
  }

  /// BACKEND-DEPENDENT — validates a 6-digit code issued by the provider.
  /// On success, upgrades the link to VERIFIED with `verificationMethod`
  /// of PROVIDER_CODE. Returns the upgraded link.
  ///
  /// MUST be guarded by `FeatureFlags.verificationCodeEnabled` at call
  /// sites — until the backend implements the endpoint, this throws 404 /
  /// 405 and the UI must NOT silently fall back to trust-based confirm.
  Future<PatientLink> verifyWithCode(String linkId, String code) async {
    final resp = await _client.dio.post<Map<String, dynamic>>(
      '$_base/links/$linkId/verify-with-code',
      data: {'code': code},
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
