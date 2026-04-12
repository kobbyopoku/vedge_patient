/// Lab result as returned by GET /api/patient/my/lab-results.
///
/// Mirrors `LabResult` from `vedge_frontend/src/types/lab.ts` — with the
/// patient-facing endpoint also joining in the test display name and the
/// order date so the mobile UI doesn't have to do a second fetch.
class PatientLabResult {
  final String id;
  final String testName;
  final String value;
  final String? unit;
  final String? referenceRange;
  final bool isAbnormal;
  final bool isCritical;
  final String status;
  final String? performedAt;
  final String? orderedAt;
  final String? notes;
  final String? organizationName;

  const PatientLabResult({
    required this.id,
    required this.testName,
    required this.value,
    required this.status,
    required this.isAbnormal,
    required this.isCritical,
    this.unit,
    this.referenceRange,
    this.performedAt,
    this.orderedAt,
    this.notes,
    this.organizationName,
  });

  factory PatientLabResult.fromJson(Map<String, dynamic> json) {
    return PatientLabResult(
      id: json['id']?.toString() ?? '',
      testName: json['testName']?.toString() ??
          json['test']?.toString() ??
          'Unknown test',
      value: json['value']?.toString() ?? '',
      unit: json['unit']?.toString(),
      referenceRange: json['referenceRange']?.toString(),
      isAbnormal: json['isAbnormal'] == true,
      isCritical: json['isCritical'] == true,
      status: json['status']?.toString() ?? 'PENDING',
      performedAt: json['performedAt']?.toString() ??
          json['validatedAt']?.toString() ??
          json['createdAt']?.toString(),
      orderedAt: json['orderedAt']?.toString() ?? json['orderDate']?.toString(),
      notes: json['notes']?.toString(),
      organizationName: json['organizationName']?.toString(),
    );
  }
}
