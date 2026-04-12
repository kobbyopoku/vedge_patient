/// Patient-facing appointment DTO.
///
/// Mirrors the shape returned by GET /api/patient/my/appointments. The
/// backend flattens the raw `scheduledDate` + `scheduledTime` into a single
/// `scheduledAt` ISO string for convenience. Providers are pre-joined.
class PatientAppointment {
  final String id;
  final String scheduledAt;
  final int? durationMinutes;
  final String status;
  final String? reason;
  final String? notes;
  final String? providerName;
  final String? departmentName;
  final String? organizationName;
  final bool isPast;

  const PatientAppointment({
    required this.id,
    required this.scheduledAt,
    required this.status,
    this.durationMinutes,
    this.reason,
    this.notes,
    this.providerName,
    this.departmentName,
    this.organizationName,
    this.isPast = false,
  });

  factory PatientAppointment.fromJson(Map<String, dynamic> json) {
    // Accept either the enriched `scheduledAt` or the raw split pair.
    String scheduledAt = json['scheduledAt']?.toString() ?? '';
    if (scheduledAt.isEmpty) {
      final d = json['scheduledDate']?.toString();
      final t = json['scheduledTime']?.toString();
      if (d != null && t != null) scheduledAt = '${d}T$t';
    }

    final isPast = json['isPast'] == true ||
        (scheduledAt.isNotEmpty &&
            DateTime.tryParse(scheduledAt)?.isBefore(DateTime.now()) == true);

    return PatientAppointment(
      id: json['id']?.toString() ?? '',
      scheduledAt: scheduledAt,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      status: json['status']?.toString() ?? 'SCHEDULED',
      reason: json['reason']?.toString(),
      notes: json['notes']?.toString(),
      providerName: json['providerName']?.toString(),
      departmentName: json['departmentName']?.toString(),
      organizationName: json['organizationName']?.toString(),
      isPast: isPast,
    );
  }

  DateTime? get scheduledDateTime => DateTime.tryParse(scheduledAt);
}
