import 'package:flutter/foundation.dart';

/// Runtime configuration for vedge_patient.
///
/// Override at build time with:
///   --dart-define=API_BASE_URL=https://api.vedge.health
class VedgePatientConfig {
  const VedgePatientConfig._();

  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    // Debug default matches the Spring Boot dev port (vedge-app).
    if (kDebugMode) return 'http://localhost:8050';
    // Release build must supply API_BASE_URL via --dart-define.
    return '';
  }

  /// Patient endpoints all live under /api/patient/*.
  /// We keep the base Dio baseUrl at the host and let the API classes prepend
  /// '/api/patient/auth' or '/api/patient/my' — this avoids surprises when
  /// the same client ever needs to hit a shared endpoint.
  static const String apiPrefix = '/api/patient';

  /// Request timeout for Dio.
  static const Duration requestTimeout = Duration(seconds: 20);
}
