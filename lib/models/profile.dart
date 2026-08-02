class Profile {
  final String id;
  final String? healthId;
  final String? fullName;
  final String? avatarUrl;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? emergencyContact;

  Profile({
    required this.id,
    this.healthId,
    this.fullName,
    this.avatarUrl,
    this.phoneNumber,
    this.dateOfBirth,
    this.gender,
    this.emergencyContact,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      healthId: json['health_id'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      phoneNumber: json['phone_number'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'])
          : null,
      gender: json['gender'],
      emergencyContact: json['emergency_contact'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (healthId != null) 'health_id': healthId,
      if (fullName != null) 'full_name': fullName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (dateOfBirth != null)
        'date_of_birth': dateOfBirth!.toIso8601String().split('T')[0],
      if (gender != null) 'gender': gender,
      if (emergencyContact != null) 'emergency_contact': emergencyContact,
    };
  }
}
