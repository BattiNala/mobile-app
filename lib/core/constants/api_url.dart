class ApiUrl {
  /// Base URL for the API endpoints
  //   static const String baseUrl = 'http://127.0.0.1:8000/api/v1';
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
  // static const String baseUrl = 'https://backend.zekx.eu.org/api/v1';

  /// Authentication endpoints
  static const String login = '$baseUrl/auth/login';
  static const String citzenRegister = '$baseUrl/auth/citizen-register';
  static const String getRefreshToken = '$baseUrl/auth/refresh';
  static const String passwordResetRequest =
      '$baseUrl/auth/password-reset/request';
  static const String passwordResetVerify =
      '$baseUrl/auth/password-reset/verify';
  static const String passwordResetConfirm =
      '$baseUrl/auth/password-reset/confirm';
  static const String verify = '$baseUrl/auth/verify';
  static const String resendVerification = '$baseUrl/auth/resend-verification';

  /// Profile endpoints
  static const String citizenProfile = '$baseUrl/profile/citizen';
  static const String employeeProfile = '$baseUrl/profile/employee';
}
