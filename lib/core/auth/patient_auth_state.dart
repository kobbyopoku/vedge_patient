import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/patient_auth_api.dart';
import '../api/patient_claims_api.dart';
import '../api/patient_data_api.dart';
import '../api/push_token_api.dart';
import '../models/patient_account.dart';
import '../models/patient_link.dart';
import '../models/patient_token.dart';
import 'secure_storage.dart';

/// Sentinel used by copyWith so we can distinguish "not passed" from
/// "passed null" for the nullable `currentLink` field.
class _Sentinel {
  const _Sentinel();
}

const Object _sentinel = _Sentinel();

/// Five-state machine for the patient app.
///
/// `loading` → bootstrap from secure storage
/// `unauthenticated` → show welcome/register/login
/// `authenticatedNoClaims` → logged in but 0 provider links
/// `authenticatedNoCurrent` → has verified links but no current org selected
/// `authenticatedReady` → fully booted, show shell
enum PatientAuthStatus {
  loading,
  unauthenticated,
  authenticatedNoClaims,
  authenticatedNoCurrent,
  authenticatedReady,
}

@immutable
class PatientAuthState {
  final PatientAuthStatus status;
  final PatientAccount? account;
  final List<PatientLink> links;
  final PatientLink? currentLink;
  final String? errorMessage;

  const PatientAuthState({
    required this.status,
    this.account,
    this.links = const [],
    this.currentLink,
    this.errorMessage,
  });

  const PatientAuthState.loading() : this(status: PatientAuthStatus.loading);

  const PatientAuthState.loggedOut({String? error})
      : this(
          status: PatientAuthStatus.unauthenticated,
          errorMessage: error,
        );

  bool get isAuthenticated =>
      status == PatientAuthStatus.authenticatedNoClaims ||
      status == PatientAuthStatus.authenticatedNoCurrent ||
      status == PatientAuthStatus.authenticatedReady;

  PatientAuthState copyWith({
    PatientAuthStatus? status,
    PatientAccount? account,
    List<PatientLink>? links,
    Object? currentLink = _sentinel,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PatientAuthState(
      status: status ?? this.status,
      account: account ?? this.account,
      links: links ?? this.links,
      currentLink: identical(currentLink, _sentinel)
          ? this.currentLink
          : currentLink as PatientLink?,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

PatientAuthStatus _statusFromLinks(List<PatientLink> links) {
  if (links.isEmpty) return PatientAuthStatus.authenticatedNoClaims;
  final hasCurrent = links.any((l) => l.isVerified && l.isCurrent);
  if (hasCurrent) return PatientAuthStatus.authenticatedReady;
  return PatientAuthStatus.authenticatedNoCurrent;
}

PatientLink? _findCurrent(List<PatientLink> links) {
  for (final l in links) {
    if (l.isCurrent && l.isVerified) return l;
  }
  return null;
}

/// Controller — single source of truth for auth + claims.
class PatientAuthController extends StateNotifier<PatientAuthState> {
  PatientAuthController({
    required this.authApi,
    required this.claimsApi,
    required this.pushApi,
    required this.storage,
    required this.apiClient,
  }) : super(const PatientAuthState.loading()) {
    // Wire refresh-failure here (not in apiClientProvider) to avoid a
    // provider cycle — same pattern as vedge_staff AuthController.
    apiClient.onRefreshFailure = () async {
      await onRefreshFailure();
    };
    _bootstrap();
  }

  final PatientAuthApi authApi;
  final PatientClaimsApi claimsApi;
  final PatientPushTokenApi pushApi;
  final PatientSecureStorage storage;
  final PatientApiClient apiClient;

  Future<void> _bootstrap() async {
    final access = await storage.readAccessToken();
    final refresh = await storage.readRefreshToken();
    if (access == null || refresh == null) {
      state = const PatientAuthState.loggedOut();
      return;
    }

    apiClient.setTokens(accessToken: access, refreshToken: refresh);

    // Optimistic hydrate from cache.
    PatientAccount? cachedAccount;
    List<PatientLink> cachedLinks = const [];
    try {
      final accountJson = await storage.readAccountJson();
      if (accountJson != null) {
        cachedAccount = PatientAccount.fromJson(
          jsonDecode(accountJson) as Map<String, dynamic>,
        );
      }
      final linksJson = await storage.readLinksJson();
      if (linksJson != null) {
        final raw = jsonDecode(linksJson);
        if (raw is List) {
          cachedLinks = raw
              .whereType<Map>()
              .map((e) => PatientLink.fromJson(e.cast<String, dynamic>()))
              .toList(growable: false);
        }
      }
    } catch (_) {}

    if (cachedAccount != null) {
      state = PatientAuthState(
        status: _statusFromLinks(cachedLinks),
        account: cachedAccount,
        links: cachedLinks,
        currentLink: _findCurrent(cachedLinks),
      );
    }

    // Revalidate in background.
    try {
      final account = await authApi.me();
      await storage.writeAccountJson(jsonEncode(account.toJson()));
      final links = await claimsApi.getLinks();
      await storage.writeLinksJson(
        jsonEncode(links.map((l) => l.toJson()).toList()),
      );
      state = PatientAuthState(
        status: _statusFromLinks(links),
        account: account,
        links: links,
        currentLink: _findCurrent(links),
      );
    } catch (e) {
      debugPrint('[vedge-patient] bootstrap revalidate failed: $e');
      if (!state.isAuthenticated) {
        await storage.clear();
        apiClient.clearTokens();
        state = const PatientAuthState.loggedOut();
      }
    }
  }

  /// After a successful register / login flow, apply the token pair and
  /// pivot to the correct post-login state.
  Future<void> applyTokenResponse(PatientTokenResponse token) async {
    apiClient.setTokens(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
    );
    await storage.writeTokens(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
    );
    await storage.writeAccountJson(jsonEncode(token.account.toJson()));

    // Fetch fresh links so our state machine knows where to go.
    List<PatientLink> links = const [];
    try {
      links = await claimsApi.getLinks();
      await storage.writeLinksJson(
        jsonEncode(links.map((l) => l.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('[vedge-patient] post-login getLinks failed: $e');
    }

    state = PatientAuthState(
      status: _statusFromLinks(links),
      account: token.account,
      links: links,
      currentLink: _findCurrent(links),
    );

    // Best-effort push registration — never blocks UI.
    // ignore: unawaited_futures
    pushApi.registerStubToken(accountId: token.account.id);
  }

  /// Refresh the links list (called after confirm / potential-matches).
  Future<void> refreshLinks() async {
    try {
      final links = await claimsApi.getLinks();
      await storage.writeLinksJson(
        jsonEncode(links.map((l) => l.toJson()).toList()),
      );
      state = state.copyWith(
        links: links,
        currentLink: _findCurrent(links),
        status: _statusFromLinks(links),
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: _readableError(e));
    }
  }

  /// Switch active provider. Swaps in the fresh token pair from the
  /// backend's /set-current response so the new JWT claims take effect.
  Future<void> setCurrentLink(String linkId) async {
    try {
      final token = await claimsApi.setCurrent(linkId);
      await applyTokenResponse(token);
    } catch (e) {
      state = state.copyWith(errorMessage: _readableError(e));
    }
  }

  Future<void> logout() async {
    await storage.clear();
    apiClient.clearTokens();
    state = const PatientAuthState.loggedOut();
  }

  Future<void> onRefreshFailure() async {
    await storage.clear();
    apiClient.clearTokens();
    state = const PatientAuthState.loggedOut(
      error: 'Session expired. Please sign in again.',
    );
  }

  String _readableError(Object e) {
    final msg = e.toString();
    if (msg.contains('401')) return 'Please sign in again.';
    if (msg.contains('409')) return 'Pick a current provider first.';
    if (msg.contains('SocketException') || msg.contains('Connection')) {
      return 'Network error. Check your connection and try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}

// ───────────────────────── Riverpod providers ─────────────────────────

final patientSecureStorageProvider = Provider<PatientSecureStorage>(
  (ref) => const PatientSecureStorage(),
);

final patientApiClientProvider = Provider<PatientApiClient>((ref) {
  // onRefreshFailure is wired inside PatientAuthController's constructor to
  // avoid a Riverpod provider cycle.
  return PatientApiClient();
});

final patientAuthApiProvider = Provider<PatientAuthApi>(
  (ref) => PatientAuthApi(ref.watch(patientApiClientProvider)),
);

final patientClaimsApiProvider = Provider<PatientClaimsApi>(
  (ref) => PatientClaimsApi(ref.watch(patientApiClientProvider)),
);

final patientDataApiProvider = Provider<PatientDataApi>(
  (ref) => PatientDataApi(ref.watch(patientApiClientProvider)),
);

final patientPushApiProvider = Provider<PatientPushTokenApi>(
  (ref) => PatientPushTokenApi(ref.watch(patientApiClientProvider)),
);

final patientAuthControllerProvider =
    StateNotifierProvider<PatientAuthController, PatientAuthState>((ref) {
  return PatientAuthController(
    authApi: ref.watch(patientAuthApiProvider),
    claimsApi: ref.watch(patientClaimsApiProvider),
    pushApi: ref.watch(patientPushApiProvider),
    storage: ref.watch(patientSecureStorageProvider),
    apiClient: ref.watch(patientApiClientProvider),
  );
});
