/// Patient-facing prescription DTO. Mirrors GET /api/patient/my/prescriptions.
class PatientPrescription {
  final String id;
  final String medicationName;
  final String? dose;
  final String? frequency;
  final String? route;
  final String? instructions;
  final String? prescriberName;
  final String? organizationName;
  final String status;
  final int? refillsRemaining;
  final String? prescribedAt;

  const PatientPrescription({
    required this.id,
    required this.medicationName,
    required this.status,
    this.dose,
    this.frequency,
    this.route,
    this.instructions,
    this.prescriberName,
    this.organizationName,
    this.refillsRemaining,
    this.prescribedAt,
  });

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  factory PatientPrescription.fromJson(Map<String, dynamic> json) {
    return PatientPrescription(
      id: json['id']?.toString() ?? '',
      medicationName: json['medicationName']?.toString() ??
          json['name']?.toString() ??
          'Medication',
      dose: json['dose']?.toString() ?? json['dosage']?.toString(),
      frequency: json['frequency']?.toString(),
      route: json['route']?.toString(),
      instructions: json['instructions']?.toString(),
      prescriberName: json['prescriberName']?.toString(),
      organizationName: json['organizationName']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
      refillsRemaining: (json['refillsRemaining'] as num?)?.toInt(),
      prescribedAt: json['prescribedAt']?.toString() ??
          json['createdAt']?.toString(),
    );
  }
}
