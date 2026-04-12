import 'package:flutter/foundation.dart';

/// Response from `GET /api/patient/my/teleconsults/{id}/join-url`. Mirrors
/// backend record `com.vedge.billing.teleconsult.dto.JoinUrlResponse`:
///
/// ```
/// record JoinUrlResponse(String joinUrl, String roomUrl, String token)
/// ```
///
/// In v1 the backend populates `joinUrl` with the Daily.co room URL and
/// leaves `token` null (or set to a short-lived meeting token if the
/// DailyRoomService has credentials). We open `joinUrl` in the device
/// browser via `url_launcher` — full in-app WebRTC is a W5.6c follow-up.
@immutable
class TeleconsultJoin {
  /// The URL the patient should open to join the call. May be the same as
  /// [roomUrl] in stub mode.
  final String joinUrl;

  /// Raw Daily.co room URL, if the backend wants to expose it separately
  /// from the tokenized join URL.
  final String? roomUrl;

  /// Short-lived meeting token. Not used in v1's external-browser flow, but
  /// kept so an embedded SDK can pick it up later.
  final String? token;

  /// Reserved for when the backend starts stamping expirations on join
  /// URLs. Not currently emitted.
  final DateTime? expiresAt;

  const TeleconsultJoin({
    required this.joinUrl,
    this.roomUrl,
    this.token,
    this.expiresAt,
  });

  factory TeleconsultJoin.fromJson(Map<String, dynamic> json) {
    return TeleconsultJoin(
      joinUrl: json['joinUrl']?.toString() ?? '',
      roomUrl: json['roomUrl']?.toString(),
      token: json['token']?.toString(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())?.toLocal()
          : null,
    );
  }
}
