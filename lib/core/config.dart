import 'package:flutter/foundation.dart';

/// Runtime configuration for vedge_patient.
///
/// Base URL resolution order:
///   1. `--dart-define=API_BASE_URL=...` (always wins — use for local backend:
///      `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8050`)
///   2. Release builds (Play Store / App Store) → production
///   3. Debug + profile builds (sideloaded onto your phone, emulator,
///      `flutter run`) → staging
///
/// The explicit `kReleaseMode` guard (not `!kDebugMode`) is deliberate:
/// profile builds must NOT hit production, otherwise performance-test runs
/// would mutate live data.
class VedgePatientConfig {
  const VedgePatientConfig._();

  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _productionBaseUrl = 'https://api.tryvedge.com';
  static const String _stagingBaseUrl = 'https://staging-api.tryvedge.com';

  static String get apiBaseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (kReleaseMode) return _productionBaseUrl;
    return _stagingBaseUrl;
  }

  /// Patient endpoints all live under /api/patient/*.
  /// We keep the base Dio baseUrl at the host and let the API classes prepend
  /// '/api/patient/auth' or '/api/patient/my' — this avoids surprises when
  /// the same client ever needs to hit a shared endpoint.
  static const String apiPrefix = '/api/patient';

  /// Request timeout for Dio.
  static const Duration requestTimeout = Duration(seconds: 20);
}
