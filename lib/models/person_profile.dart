class PersonProfile {
  const PersonProfile({
    this.name = '',
    this.dateOfBirth,
    this.gender = '',
    this.bloodGroup = '',
    this.medicalHistory = '',
    this.allergies = '',
  });

  static const empty = PersonProfile();

  final String name;
  final DateTime? dateOfBirth;
  final String gender;
  final String bloodGroup;
  final String medicalHistory;
  final String allergies;

  int? get ageYears {
    final birth = dateOfBirth;
    if (birth == null) {
      return null;
    }
    final today = DateTime.now();
    var age = today.year - birth.year;
    final birthdayPassed = today.month > birth.month ||
        (today.month == birth.month && today.day >= birth.day);
    if (!birthdayPassed) {
      age -= 1;
    }
    return age < 0 ? null : age;
  }

  PersonProfile copyWith({
    String? name,
    DateTime? dateOfBirth,
    bool clearDateOfBirth = false,
    String? gender,
    String? bloodGroup,
    String? medicalHistory,
    String? allergies,
  }) {
    return PersonProfile(
      name: name ?? this.name,
      dateOfBirth: clearDateOfBirth ? null : dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      allergies: allergies ?? this.allergies,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'bloodGroup': bloodGroup,
      'medicalHistory': medicalHistory,
      'allergies': allergies,
    };
  }

  factory PersonProfile.fromJson(Map<String, dynamic> json) {
    return PersonProfile(
      name: json['name'] as String? ?? '',
      dateOfBirth: DateTime.tryParse('${json['dateOfBirth'] ?? ''}'),
      gender: json['gender'] as String? ?? '',
      bloodGroup: json['bloodGroup'] as String? ?? '',
      medicalHistory: json['medicalHistory'] as String? ?? '',
      allergies: json['allergies'] as String? ?? '',
    );
  }
}
