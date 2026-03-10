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
  final String employeeId;

  EmployeeProfile({
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.department,
    required this.employeeId,
  });

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) {
    return EmployeeProfile(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      department: json['department'] ?? '',
      employeeId: json['employee_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'department': department,
      'employee_id': employeeId,
    };
  }

  @override
  String toString() {
    return 'EmployeeProfile(name: $name, email: $email, phoneNumber: $phoneNumber, department: $department, employeeId: $employeeId)';
  }
}
