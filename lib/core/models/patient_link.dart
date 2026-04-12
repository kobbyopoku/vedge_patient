/// A single link between a PatientAccount and a provider-org Patient record.
/// Mirrors backend `com.vedge.patient.dto.PatientLinkResponse` from W5.4.
///
/// `claimStatus` values: PENDING, VERIFIED, REJECTED.
enum PatientClaimStatus { pending, verified, rejected, unknown }

PatientClaimStatus _parseClaimStatus(String? raw) {
  switch (raw?.toUpperCase()) {
    case 'PENDING':
      return PatientClaimStatus.pending;
    case 'VERIFIED':
      return PatientClaimStatus.verified;
    case 'REJECTED':
      return PatientClaimStatus.rejected;
    default:
      return PatientClaimStatus.unknown;
  }
}

String claimStatusLabel(PatientClaimStatus s) {
  switch (s) {
    case PatientClaimStatus.pending:
      return 'Pending';
    case PatientClaimStatus.verified:
      return 'Verified';
    case PatientClaimStatus.rejected:
      return 'Rejected';
    case PatientClaimStatus.unknown:
      return 'Unknown';
  }
}

class PatientLink {
  final String id;
  final String organizationId;
  final String organizationName;
  final String patientId;
  final String? patientNameOnRecord;
  final PatientClaimStatus claimStatus;
  final bool isCurrent;
  final String? verifiedAt;
  final String? createdAt;

  const PatientLink({
    required this.id,
    required this.organizationId,
    required this.organizationName,
    required this.patientId,
    required this.claimStatus,
    required this.isCurrent,
    this.patientNameOnRecord,
    this.verifiedAt,
    this.createdAt,
  });

  bool get isVerified => claimStatus == PatientClaimStatus.verified;
  bool get isPending => claimStatus == PatientClaimStatus.pending;

  factory PatientLink.fromJson(Map<String, dynamic> json) {
    return PatientLink(
      id: json['id']?.toString() ?? '',
      organizationId: json['organizationId']?.toString() ?? '',
      organizationName: json['organizationName']?.toString() ?? 'Unknown provider',
      patientId: json['patientId']?.toString() ?? '',
      patientNameOnRecord: json['patientNameOnRecord']?.toString() ??
          json['patientDisplayName']?.toString(),
      claimStatus: _parseClaimStatus(json['claimStatus']?.toString()),
      isCurrent: json['isCurrent'] == true || json['current'] == true,
      verifiedAt: json['verifiedAt']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'organizationId': organizationId,
        'organizationName': organizationName,
        'patientId': patientId,
        'patientNameOnRecord': patientNameOnRecord,
        'claimStatus': claimStatus.name.toUpperCase(),
        'isCurrent': isCurrent,
        'verifiedAt': verifiedAt,
        'createdAt': createdAt,
      };
}
