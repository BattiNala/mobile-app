class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String roleName;
  final bool? isVerified;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.roleName,
    this.isVerified,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      roleName: json['role_name'] as String,
      isVerified: json['is_verified'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'role_name': roleName,
      if (isVerified != null) 'is_verified': isVerified,
    };
  }
}
