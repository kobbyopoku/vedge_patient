import '../config.dart';
import '../models/patient_account.dart';
import '../models/patient_token.dart';
import 'api_client.dart';

/// Wraps the public + authenticated /api/patient/auth/* endpoints.
///
/// V128 phone-first flow:
///   1. [startPhoneAuth] with phone → backend returns 202 (enumeration-safe)
///      and sends OTP if the phone is already a registered account OR
///      creates a short-lived pending-registration row if it isn't.
///   2. [verifyStart] with phone + code → returns either
///      [VerifyStartExistingAccount] (log the user in with the returned
///      tokens) or [VerifyStartPendingRegistration] (a short-lived
///      registration JWT that the client redeems at
///      [completeRegistration] with the new user's name + DOB).
///   3. [completeRegistration] with the token + profile → creates the
///      account with phone already verified and returns tokens.
class PatientAuthApi {
  PatientAuthApi(this._client);
  final PatientApiClient _client;

  static const _base = '${VedgePatientConfig.apiPrefix}/auth';

  /// V128 step 1. Always returns 202 when the phone is valid; the response
  /// body is identical whether or not the phone is already registered.
  ///
  /// Throws on 400 (malformed phone) or 429 (rate-limit hit).
  Future<void> startPhoneAuth({
    required String phone,
    String? deviceFingerprint,
  }) async {
    await _client.dio.post<void>(
      '$_base/start',
      data: {
        'phone': phone,
        if (deviceFingerprint != null && deviceFingerprint.isNotEmpty)
          'deviceFingerprint': deviceFingerprint,
      },
    );
  }

  /// V128 step 2. Verifies the OTP and returns a discriminated outcome.
  ///
  /// Throws on 401 (invalid / expired OTP — no leak; identical for both
  /// existing-account and new-phone paths).
  Future<VerifyStartResult> verifyStart({
    required String phone,
    required String code,
  }) async {
    final resp = await _client.dio.post<Map<String, dynamic>>(
      '$_base/verify-start',
      data: {'phone': phone, 'code': code},
    );
    final data = resp.data ?? const {};
    if (data['needsRegistration'] == true || data['registrationToken'] != null) {
      return VerifyStartPendingRegistration(
        registrationToken: data['registrationToken']?.toString() ?? '',
        expiresInSeconds: (data['expiresInSeconds'] as num?)?.toInt() ?? 0,
      );
    }
    // ExistingAccount shape: { tokens: PatientTokenResponse, account: ..., links: [...] }
    // PatientTokenResponse already embeds `account`, so we parse from that
    // sub-object and ignore the redundant top-level copy.
    final tokensJson = (data['tokens'] as Map?)?.cast<String, dynamic>() ?? data;
    return VerifyStartExistingAccount(
      tokens: PatientTokenResponse.fromJson(tokensJson),
    );
  }

  /// V128 step 3 — redeem the registration JWT + collected profile.
  ///
  /// V130: optional [nhisNumber] and [nationalId] (Ghana Card) are used as
  /// alternative second factors to [dateOfBirth] when the backend later
  /// matches this account to per-tenant patients records. Without at least
  /// one second factor that matches what a facility has on file, no
  /// records will be auto-linked — the patient will be told to visit the
  /// facility to complete linking. That's the correct security trade-off.
  ///
  /// Throws on 401 (invalid / expired / consumed token) or 409 (parallel
  /// completion created the account first).
  Future<PatientTokenResponse> completeRegistration({
    required String registrationToken,
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    String? nhisNumber,
    String? nationalId,
    String? deviceFingerprint,
  }) async {
    final resp = await _client.dio.post<Map<String, dynamic>>(
      '$_base/complete-registration',
      data: {
        'registrationToken': registrationToken,
        'firstName': firstName,
        'lastName': lastName,
        'dateOfBirth': dateOfBirth,
        if (nhisNumber != null && nhisNumber.trim().isNotEmpty)
          'nhisNumber': nhisNumber.trim(),
        if (nationalId != null && nationalId.trim().isNotEmpty)
          'nationalId': nationalId.trim(),
        if (deviceFingerprint != null && deviceFingerprint.isNotEmpty)
          'deviceFingerprint': deviceFingerprint,
      },
    );
    final data = resp.data ?? const {};
    final tokensJson = (data['tokens'] as Map?)?.cast<String, dynamic>() ?? data;
    return PatientTokenResponse.fromJson(tokensJson);
  }

  /// GET /auth/me — refreshes the account profile.
  Future<PatientAccount> me() async {
    final resp = await _client.dio.get<Map<String, dynamic>>('$_base/me');
    return PatientAccount.fromJson(resp.data ?? const {});
  }
}

/// Discriminated outcome of [PatientAuthApi.verifyStart].
sealed class VerifyStartResult {
  const VerifyStartResult();
}

class VerifyStartExistingAccount extends VerifyStartResult {
  const VerifyStartExistingAccount({required this.tokens});
  final PatientTokenResponse tokens;
}

class VerifyStartPendingRegistration extends VerifyStartResult {
  const VerifyStartPendingRegistration({
    required this.registrationToken,
    required this.expiresInSeconds,
  });
  final String registrationToken;
  final int expiresInSeconds;
}
