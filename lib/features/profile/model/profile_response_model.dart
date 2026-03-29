class CitizenProfile {
  final String name;
  final String email;
  final String phoneNumber;
  final String address;
  final int trustScore;

  CitizenProfile({
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.trustScore,
  });

  factory CitizenProfile.fromJson(Map<String, dynamic> json) {
    return CitizenProfile(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      address: json['address'] ?? '',
      trustScore: json['trust_score'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'address': address,
      'trust_score': trustScore,
    };
  }

  @override
  String toString() {
    return 'CitizenProfile(name: $name, email: $email, phoneNumber: $phoneNumber, address: $address, trustScore: $trustScore)';
  }
}

class EmployeeProfile {
  final String name;
  final String email;
  final String phoneNumber;
  final String department;
  final String teamName;
  final String currentStatus;

  EmployeeProfile({
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.department,
    required this.teamName,
    required this.currentStatus,
  });

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) {
    return EmployeeProfile(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      department: json['department_name'] ?? '',
      teamName: json['team_name'] ?? '',
      currentStatus: json['current_status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'department': department,
      'employee_id': teamName,
      'current_status': currentStatus,
    };
  }
}
