import 'package:flutter/foundation.dart';

/// Availability slot exposed by
/// `GET /api/patient/my/teleconsults/providers/{userId}/slots`.
///
/// Mirrors backend record
/// `com.vedge.billing.teleconsult.dto.AvailabilitySlotResponse`:
///
/// ```
/// record AvailabilitySlotResponse(
///   UUID id,
///   UUID organizationId,
///   UUID providerUserId,
///   Instant startTime,
///   Instant endTime,
///   boolean isBooked,
///   UUID bookingReference
/// )
/// ```
///
/// `Instant` is serialized as ISO-8601 with a trailing `Z` by Jackson; we
/// parse it into a local-TZ `DateTime` for display.
@immutable
class AvailabilitySlot {
  final String id;
  final String organizationId;
  final String providerUserId;
  final DateTime startTime;
  final DateTime endTime;
  final bool isBooked;
  final String? bookingReference;

  const AvailabilitySlot({
    required this.id,
    required this.organizationId,
    required this.providerUserId,
    required this.startTime,
    required this.endTime,
    required this.isBooked,
    this.bookingReference,
  });

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      id: json['id']?.toString() ?? '',
      organizationId: json['organizationId']?.toString() ?? '',
      providerUserId: json['providerUserId']?.toString() ?? '',
      startTime: DateTime.parse(json['startTime'].toString()).toLocal(),
      endTime: DateTime.parse(json['endTime'].toString()).toLocal(),
      isBooked: json['isBooked'] == true || json['booked'] == true,
      bookingReference: json['bookingReference']?.toString(),
    );
  }

  Duration get duration => endTime.difference(startTime);
}
