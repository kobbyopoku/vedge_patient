/// Patient account — mirrors backend `com.vedge.patient.dto.PatientAccountResponse`
/// from W5.4. One account = one human, regardless of how many provider
/// organizations they have records at.
class PatientAccount {
  final String id;
  final String? phone;
  final String? email;
  final String firstName;
  final String lastName;
  final String? dateOfBirth;
  final String? gender;
  final bool phoneVerified;
  final bool emailVerified;
  final String? createdAt;

  const PatientAccount({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.email,
    this.dateOfBirth,
    this.gender,
    this.phoneVerified = false,
    this.emailVerified = false,
    this.createdAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    final out = (first + last).toUpperCase();
    return out.isEmpty ? '?' : out;
  }

  factory PatientAccount.fromJson(Map<String, dynamic> json) {
    return PatientAccount(
      id: json['id']?.toString() ?? json['accountId']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      gender: json['gender']?.toString(),
      phoneVerified: json['phoneVerified'] == true,
      emailVerified: json['emailVerified'] == true,
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'email': email,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'phoneVerified': phoneVerified,
        'emailVerified': emailVerified,
        'createdAt': createdAt,
      };
}
