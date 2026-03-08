class ApiUrl {
  /// Base URL for the API endpoints
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';

  /// Authentication endpoints
  static const String login = '$baseUrl/auth/login';
  static const String citzenRegister = '$baseUrl/auth/citizen-register';
  static const String getRefreshToken = '$baseUrl/auth/refresh';
}
