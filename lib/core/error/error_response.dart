class AuthError {
  final String detail;

  AuthError({required this.detail});

  factory AuthError.fromJson(Map<String, dynamic> json) {
    return AuthError(detail: json['detail'] as String? ?? 'An error occurred');
  }
}
