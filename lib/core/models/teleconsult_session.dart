import 'package:flutter/foundation.dart';

/// Status values the backend emits on a TeleconsultSession. The wire format
/// is the bare enum name as a string (e.g. "SCHEDULED").
enum TeleconsultStatus {
  scheduled,
  active,
  completed,
  noShow,
  cancelled,
  unknown;

  static TeleconsultStatus fromString(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'SCHEDULED':
        return TeleconsultStatus.scheduled;
      case 'ACTIVE':
      case 'IN_PROGRESS':
        return TeleconsultStatus.active;
      case 'COMPLETED':
        return TeleconsultStatus.completed;
      case 'NO_SHOW':
      case 'NOSHOW':
        return TeleconsultStatus.noShow;
      case 'CANCELLED':
      case 'CANCELED':
        return TeleconsultStatus.cancelled;
      default:
        return TeleconsultStatus.unknown;
    }
  }

  String get label {
    switch (this) {
      case TeleconsultStatus.scheduled:
        return 'Scheduled';
      case TeleconsultStatus.active:
        return 'Live';
      case TeleconsultStatus.completed:
        return 'Completed';
      case TeleconsultStatus.noShow:
        return 'No show';
      case TeleconsultStatus.cancelled:
        return 'Cancelled';
      case TeleconsultStatus.unknown:
        return 'Unknown';
    }
  }

  bool get isTerminal =>
      this == TeleconsultStatus.completed ||
      this == TeleconsultStatus.cancelled ||
      this == TeleconsultStatus.noShow;
}

/// Patient-facing teleconsult session. Mirrors backend record
/// `com.vedge.billing.teleconsult.dto.TeleconsultSessionResponse`:
///
/// ```
/// record TeleconsultSessionResponse(
///   UUID id, UUID organizationId, UUID providerUserId,
///   UUID patientAccountId, UUID slotId,
///   Instant scheduledStart, Instant scheduledEnd,
///   String status,
///   String dailyRoomName, String dailyRoomUrl,
///   Instant startedAt, Instant endedAt,
///   String reason, String soapNote
/// )
/// ```
///
/// The backend does NOT currently send a `providerName` or `createdAt` —
/// those are optional here so a future enrichment can populate them without
/// breaking existing call sites.
@immutable
class TeleconsultSession {
  final String id;
  final String organizationId;
  final String providerUserId;
  final String? providerName;
  final String patientAccountId;
  final String? slotId;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final TeleconsultStatus status;
  final String? reason;
  final String? dailyRoomName;
  final String? dailyRoomUrl;
  final String? soapNote;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? createdAt;

  const TeleconsultSession({
    required this.id,
    required this.organizationId,
    required this.providerUserId,
    required this.patientAccountId,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.status,
    this.providerName,
    this.slotId,
    this.reason,
    this.dailyRoomName,
    this.dailyRoomUrl,
    this.soapNote,
    this.startedAt,
    this.endedAt,
    this.createdAt,
  });

  factory TeleconsultSession.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic raw) {
      if (raw == null) return null;
      return DateTime.tryParse(raw.toString())?.toLocal();
    }

    return TeleconsultSession(
      id: json['id']?.toString() ?? '',
      organizationId: json['organizationId']?.toString() ?? '',
      providerUserId: json['providerUserId']?.toString() ?? '',
      providerName: json['providerName']?.toString(),
      patientAccountId: json['patientAccountId']?.toString() ?? '',
      slotId: json['slotId']?.toString(),
      scheduledStart:
          parse(json['scheduledStart']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      scheduledEnd:
          parse(json['scheduledEnd']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      status: TeleconsultStatus.fromString(json['status']?.toString()),
      reason: json['reason']?.toString(),
      dailyRoomName: json['dailyRoomName']?.toString(),
      dailyRoomUrl: json['dailyRoomUrl']?.toString(),
      soapNote: json['soapNote']?.toString(),
      startedAt: parse(json['startedAt']),
      endedAt: parse(json['endedAt']),
      createdAt: parse(json['createdAt']),
    );
  }

  bool get isPast =>
      status.isTerminal || scheduledEnd.isBefore(DateTime.now());

  /// True within ±15 minutes of the scheduled start, OR while ACTIVE.
  bool get isJoinable {
    if (status == TeleconsultStatus.active) return true;
    if (status != TeleconsultStatus.scheduled) return false;
    final now = DateTime.now();
    final diff = scheduledStart.difference(now).inMinutes;
    // Joinable from 15 min before start until 30 min after start.
    return diff <= 15 && now.isBefore(scheduledEnd.add(const Duration(minutes: 30)));
  }

  /// True when cancellation is still reasonable — SCHEDULED and still >15
  /// min out from start.
  bool get isCancellable {
    if (status != TeleconsultStatus.scheduled) return false;
    return scheduledStart.difference(DateTime.now()).inMinutes > 15;
  }
}
