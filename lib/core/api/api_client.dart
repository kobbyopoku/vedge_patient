import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config.dart';

/// Thrown when a /my/* endpoint returns 409 because the patient JWT has no
/// `current_organization_id` claim yet. The UI catches this and prompts the
/// user to pick a current provider from the Me tab.
class NoCurrentLinkException implements Exception {
  const NoCurrentLinkException([this.message]);
  final String? message;
  @override
  String toString() =>
      'NoCurrentLinkException: ${message ?? 'Pick a current provider first.'}';
}

/// Dio-backed API client for vedge_patient.
///
/// Mirrors the staff app's `VedgeApiClient`:
///   * Authorization: Bearer <patient-jwt> injection (except public auth)
///   * 401 → POST /api/patient/auth/refresh → single-flight retry
///   * 409 on /my/* → converted to [NoCurrentLinkException]
///   * [onRefreshFailure] wired from [PatientAuthController] to redirect to
///     welcome screen on hard logout.
class PatientApiClient {
  PatientApiClient() : _dio = _buildDio() {
    _dio.interceptors.add(_buildAuthInterceptor());
  }

  final Dio _dio;

  String? _accessToken;
  String? _refreshToken;
  Future<bool>? _refreshFuture;

  /// Called when the refresh endpoint definitively fails (401 / network).
  /// [PatientAuthController] wires this.
  Future<void> Function()? onRefreshFailure;

  Dio get dio => _dio;

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: VedgePatientConfig.apiBaseUrl,
        connectTimeout: VedgePatientConfig.requestTimeout,
        receiveTimeout: VedgePatientConfig.requestTimeout,
        sendTimeout: VedgePatientConfig.requestTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    if (kDebugMode) {
      // SECURITY P0 (Phase F): the previous LogInterceptor exposed
      // Authorization + Cookie headers in debug logs. Use a custom
      // interceptor that redacts sensitive headers and never prints
      // request/response bodies, only errors.
      dio.interceptors.add(_RedactingLogInterceptor());
    }
    return dio;
  }

  void setTokens({required String accessToken, required String refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  String? get accessToken => _accessToken;

  static bool _isPublicPath(String path) {
    // V128 phone-first flow + /refresh. All other /api/patient/** paths
    // require a patient JWT and go through the Authorization-injection
    // branch of the interceptor.
    return path.endsWith('/auth/start') ||
        path.endsWith('/auth/verify-start') ||
        path.endsWith('/auth/complete-registration') ||
        path.endsWith('/auth/refresh');
  }

  Interceptor _buildAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        if (!_isPublicPath(options.path) && _accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final response = error.response;
        final requestOptions = error.requestOptions;
        final status = response?.statusCode;

        // 409 on any /my/* endpoint = no current link set.
        if (status == 409 && requestOptions.path.contains('/my/')) {
          return handler.reject(
            DioException(
              requestOptions: requestOptions,
              response: response,
              error: const NoCurrentLinkException(
                'No current provider selected. Pick one from the Me tab.',
              ),
              type: DioExceptionType.badResponse,
            ),
          );
        }

        final isRefreshCall = requestOptions.path.endsWith('/auth/refresh');
        final isPublic = _isPublicPath(requestOptions.path);

        if (status != 401 || isRefreshCall || isPublic || _refreshToken == null) {
          return handler.next(error);
        }

        final refreshed = await _refreshTokenOnce();
        if (!refreshed) {
          await onRefreshFailure?.call();
          return handler.next(error);
        }

        try {
          final retry = await _dio.fetch<dynamic>(
            requestOptions
              ..headers['Authorization'] = 'Bearer $_accessToken',
          );
          return handler.resolve(retry);
        } on DioException catch (e) {
          return handler.next(e);
        }
      },
    );
  }

  Future<bool> _refreshTokenOnce() {
    _refreshFuture ??= _doRefresh().whenComplete(() => _refreshFuture = null);
    return _refreshFuture!;
  }

  Future<bool> _doRefresh() async {
    final refresh = _refreshToken;
    if (refresh == null) return false;
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        '${VedgePatientConfig.apiPrefix}/auth/refresh',
        data: {'refreshToken': refresh},
      );
      final body = resp.data;
      if (body == null) return false;
      final newAccess = body['accessToken']?.toString();
      final newRefresh = body['refreshToken']?.toString() ?? refresh;
      if (newAccess == null) return false;
      _accessToken = newAccess;
      _refreshToken = newRefresh;
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// SECURITY P0 — debug-only logger that redacts Authorization, Cookie and
/// any header containing 'token' or 'secret'. Never prints request or
/// response bodies. Errors include status + path only — no response payload.
class _RedactingLogInterceptor extends Interceptor {
  static const _redacted = '<redacted>';
  static final _sensitiveHeaders = {
    'authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
    'x-csrf-token',
  };

  Map<String, dynamic> _scrub(Map<String, dynamic> headers) {
    final out = <String, dynamic>{};
    headers.forEach((k, v) {
      final lower = k.toLowerCase();
      final isSensitive = _sensitiveHeaders.contains(lower) ||
          lower.contains('token') ||
          lower.contains('secret');
      out[k] = isSensitive ? _redacted : v;
    });
    return out;
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final req = err.requestOptions;
    final status = err.response?.statusCode;
    debugPrint(
      '[vedge-api] ERROR ${req.method} ${req.path} '
      'status=$status type=${err.type.name} '
      'headers=${_scrub(req.headers)}',
    );
    handler.next(err);
  }
}

@visibleForTesting
Map<String, dynamic> redactedHeadersForTest(Map<String, dynamic> headers) =>
    _RedactingLogInterceptor()._scrub(headers);
