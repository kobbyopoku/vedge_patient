import 'package:flutter/foundation.dart';

/// Patient-facing view of a provider (doctor) exposed by
/// `GET /api/patient/my/teleconsults/providers`.
///
/// Mirrors the backend record
/// `com.vedge.billing.teleconsult.dto.ProviderSummaryResponse`:
///
/// ```
/// record ProviderSummaryResponse(
///   UUID userId,
///   String firstName,
///   String lastName,
///   String role,
///   int openSlotCount
/// )
/// ```
///
/// The backend currently does not expose a specialty, per-session fee, or
/// profile photo — those are future additions. We keep optional fields here
/// so we can hydrate them later without breaking existing call sites.
@immutable
class ProviderSummary {
  final String userId;
  final String firstName;
  final String lastName;

  /// Backend `role` string (e.g. "DOCTOR", "NURSE"). We render this as the
  /// specialty line until a real specialty column exists.
  final String? role;
  final int openSlotCount;

  /// Not currently returned by the backend — reserved for when the provider
  /// availability schema starts publishing a per-session fee.
  final double? feeGhs;

  const ProviderSummary({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.openSlotCount,
    this.role,
    this.feeGhs,
  });

  factory ProviderSummary.fromJson(Map<String, dynamic> json) {
    return ProviderSummary(
      userId: json['userId']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      role: json['role']?.toString(),
      openSlotCount: (json['openSlotCount'] as num?)?.toInt() ?? 0,
      feeGhs: (json['feeGhs'] as num?)?.toDouble(),
    );
  }

  /// "Dr. Jane Doe" style label. We prepend "Dr." for any DOCTOR role and
  /// fall back to just the first + last name otherwise.
  String get displayName {
    final title = (role != null && role!.toUpperCase().contains('DOCTOR'))
        ? 'Dr.'
        : '';
    return '$title $firstName $lastName'.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    final out = '$f$l'.toUpperCase();
    return out.isEmpty ? '?' : out;
  }

  /// Human-readable role label (e.g. "Doctor", "Nurse") used as the
  /// specialty line in cards. Returns null when we have no role to display.
  String? get roleLabel {
    final r = role;
    if (r == null || r.isEmpty) return null;
    // Convert "DOCTOR" → "Doctor", "NURSE_PRACTITIONER" → "Nurse Practitioner"
    return r
        .split('_')
        .map((w) => w.isEmpty
            ? ''
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}
