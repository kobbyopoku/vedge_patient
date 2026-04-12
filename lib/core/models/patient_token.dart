import 'patient_account.dart';

/// Mirrors `com.vedge.patient.dto.PatientTokenResponse` from W5.4.
///
/// Returned by register/verify-otp/login/verify-login-otp/refresh/set-current.
class PatientTokenResponse {
  final String accessToken;
  final String refreshToken;
  final int? expiresIn;
  final PatientAccount account;

  /// Populated if the JWT has `current_organization_id` / `current_patient_id`
  /// claims (only after /links/{id}/set-current has been called).
  final String? currentOrganizationId;
  final String? currentPatientId;

  const PatientTokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.account,
    this.expiresIn,
    this.currentOrganizationId,
    this.currentPatientId,
  });

  factory PatientTokenResponse.fromJson(Map<String, dynamic> json) {
    return PatientTokenResponse(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      expiresIn: (json['expiresIn'] as num?)?.toInt(),
      account: PatientAccount.fromJson(
        (json['account'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      currentOrganizationId: json['currentOrganizationId']?.toString(),
      currentPatientId: json['currentPatientId']?.toString(),
    );
  }
}
