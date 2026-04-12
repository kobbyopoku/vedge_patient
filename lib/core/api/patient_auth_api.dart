import '../config.dart';
import '../models/patient_account.dart';
import '../models/patient_token.dart';
import 'api_client.dart';

/// Wraps the public + authenticated /api/patient/auth/* endpoints.
class PatientAuthApi {
  PatientAuthApi(this._client);
  final PatientApiClient _client;

  static const _base = '${VedgePatientConfig.apiPrefix}/auth';

  /// Contact type the backend expects on verify-otp: 'PHONE' or 'EMAIL'.
  static String detectContactType(String input) {
    return input.contains('@') ? 'EMAIL' : 'PHONE';
  }

  /// Step 1 of registration — returns the `accountId` used to verify the
  /// OTP in step 2.
  Future<RegisterPending> register({
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    String? phone,
    String? email,
    String? gender,
  }) async {
    final body = <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (gender != null && gender.isNotEmpty) 'gender': gender,
    };
    final resp = await _client.dio.post<Map<String, dynamic>>(
      '$_base/register',
      data: body,
    );
    final data = resp.data ?? const {};
    return RegisterPending(
      accountId: data['accountId']?.toString() ?? '',
      contactType:
          data['contactType']?.toString() ?? (phone != null ? 'PHONE' : 'EMAIL'),
      message: data['message']?.toString() ?? 'Check your messages for a code.',
    );
  }

  /// Step 2 of registration — exchanges the OTP for a token pair.
  Future<PatientTokenResponse> verifyRegisterOtp({
    required String accountId,
    required String code,
    required String contactType,
  }) async {
    final resp = await _client.dio.post<Map<String, dynamic>>(
      '$_base/verify-otp',
      data: {
        'accountId': accountId,
        'code': code,
        'contactType': contactType,
      },
    );
    return PatientTokenResponse.fromJson(resp.data ?? const {});
  }

  /// Kick off OTP for an existing account. Returns 202 with no body on the
  /// backend — we do not leak whether the account exists.
  Future<void> requestLoginOtp({required String phoneOrEmail}) async {
    await _client.dio.post<void>(
      '$_base/login-otp',
      data: {'phoneOrEmail': phoneOrEmail},
    );
  }

  /// Verify the login OTP and receive tokens.
  Future<PatientTokenResponse> verifyLoginOtp({
    required String phoneOrEmail,
    required String code,
  }) async {
    final resp = await _client.dio.post<Map<String, dynamic>>(
      '$_base/verify-login-otp',
      data: {
        'phoneOrEmail': phoneOrEmail,
        'code': code,
      },
    );
    return PatientTokenResponse.fromJson(resp.data ?? const {});
  }

  /// GET /auth/me — refreshes the account profile.
  Future<PatientAccount> me() async {
    final resp = await _client.dio.get<Map<String, dynamic>>('$_base/me');
    return PatientAccount.fromJson(resp.data ?? const {});
  }
}

class RegisterPending {
  final String accountId;
  final String contactType;
  final String message;
  const RegisterPending({
    required this.accountId,
    required this.contactType,
    required this.message,
  });
}
