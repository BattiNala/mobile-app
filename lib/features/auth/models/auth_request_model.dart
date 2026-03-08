class LoginRequest {
  final String username;
  final String password;

  LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() {
    return {'username': username, 'password': password};
  }
}

class RegisterRequest {
  final String username;
  final String password;
  final String name;
  final String phoneNumber;
  final String email;
  final String homeAddress;

  RegisterRequest({
    required this.username,
    required this.password,
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.homeAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'name': name,
      'phone_number': phoneNumber,
      'email': email,
      'home_address': homeAddress,
    };
  }
}

class RefreshTokenRequest {
  final String refreshToken;

  RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() {
    return {'refresh_token': refreshToken};
  }
}
