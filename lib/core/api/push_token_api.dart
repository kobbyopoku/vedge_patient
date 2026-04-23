import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../config.dart';
import 'api_client.dart';

/// Push-token registration for the patient app.
///
/// W5.5 v1 ships with a stub token (same pattern as vedge_staff PushApi):
///  * generate a random device token
///  * POST to /api/patient/my/push-tokens
///  * If the endpoint 404s we log and move on — the backend added this in
///    W5.4 so in practice it should always be 2xx.
///
/// A future W5.5b will replace the stub with a real FCM/APNs token.
class PatientPushTokenApi {
  PatientPushTokenApi(this._client);
  final PatientApiClient _client;

  static const _base = '${VedgePatientConfig.apiPrefix}/my';

  Future<void> registerStubToken({required String accountId}) async {
    final token = _generateStubToken();
    final platform = _platformLabel();

    debugPrint(
      '[vedge-patient] push token (stub) generated account=$accountId '
      'platform=$platform token=$token',
    );

    try {
      await _client.dio.post<void>(
        '$_base/push-tokens',
        data: {
          'deviceToken': token,
          'platform': platform,
          'deviceId': 'stub-$accountId',
          'appVersion': '0.1.0',
        },
      );
      debugPrint('[vedge-patient] push token registered with backend');
    } catch (e) {
      debugPrint('[vedge-patient] push token endpoint error (non-fatal): $e');
    }
  }

  Future<void> deregister(String tokenId) async {
    try {
      await _client.dio.delete<void>('$_base/push-tokens/$tokenId');
    } catch (_) {
      // Best-effort.
    }
  }

  String _generateStubToken() {
    final rng = Random.secure();
    final bytes = List<int>.generate(24, (_) => rng.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return 'stub_${DateTime.now().millisecondsSinceEpoch}_$bytes';
  }

  /// Upper-case to satisfy the backend's chk_push_platform CHECK
  /// constraint (V45): platform IN ('IOS','ANDROID','WEB'). The backend
  /// also treats 'UNKNOWN' as invalid; a fallback device platform maps
  /// to 'WEB' so the register call still succeeds on exotic hosts
  /// (emulators, desktop IDEs) rather than being silently rejected.
  String _platformLabel() {
    if (kIsWeb) return 'WEB';
    try {
      if (Platform.isIOS) return 'IOS';
      if (Platform.isAndroid) return 'ANDROID';
    } catch (_) {}
    return 'WEB';
  }
}
