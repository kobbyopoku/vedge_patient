import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around flutter_secure_storage for the patient tokens +
/// account JSON + link cache.
///
/// Keys are prefixed `vedge_patient.` so a user who also has the
/// `vedge_staff` app installed never gets token collision.
class PatientSecureStorage {
  static const _accessKey = 'vedge_patient.access_token';
  static const _refreshKey = 'vedge_patient.refresh_token';
  static const _accountKey = 'vedge_patient.account_json';
  static const _linksKey = 'vedge_patient.links_json';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  const PatientSecureStorage();

  Future<String?> readAccessToken() => _storage.read(key: _accessKey);
  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);
  Future<String?> readAccountJson() => _storage.read(key: _accountKey);
  Future<String?> readLinksJson() => _storage.read(key: _linksKey);

  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  Future<void> writeAccountJson(String accountJson) =>
      _storage.write(key: _accountKey, value: accountJson);

  Future<void> writeLinksJson(String linksJson) =>
      _storage.write(key: _linksKey, value: linksJson);

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _accountKey);
    await _storage.delete(key: _linksKey);
  }
}
