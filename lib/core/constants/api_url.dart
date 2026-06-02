import 'dart:io';

class ApiUrl {
  /// Base URL for the API endpoints
  // Platform-specific defaults:
  // - Android Emulator: http://10.0.2.2:8000/api/v1
  // - iOS Simulator: http://127.0.0.1:8000/api/v1
  // - Production: https://backend.zekx.eu.org/api/v1
  static final String baseUrl = _getBaseUrl();

  static String _getBaseUrl() {
    // Check for environment variable first
    const envUrl = String.fromEnvironment('BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    // Platform-specific defaults
    if (Platform.isAndroid) {
      // return 'http://10.0.2.2:8000/api/v1'; // Android emulator localhost
      return 'https://backend.parakramk.com.np/api/v1'; // Android emulator localhost
    } else if (Platform.isIOS) {
      return 'http://127.0.0.1:8000/api/v1'; // iOS simulator localhost
    } else {
      return 'http://localhost:8000/api/v1'; // Web/desktop fallback
    }
  }

  /// Authentication endpoints
  static final String login = '$baseUrl/auth/login';
  static final String citzenRegister = '$baseUrl/auth/citizen-register';
  static final String getRefreshToken = '$baseUrl/auth/refresh';
  static final String passwordResetRequest =
      '$baseUrl/auth/password-reset/request';
  static final String passwordResetVerify =
      '$baseUrl/auth/password-reset/verify';
  static final String passwordResetConfirm =
      '$baseUrl/auth/password-reset/confirm';
  static final String verify = '$baseUrl/auth/verify';
  static final String resendVerification = '$baseUrl/auth/resend-verification';

  /// Profile endpoints
  static final String citizenProfile = '$baseUrl/profile/citizen';
  static final String employeeProfile = '$baseUrl/profile/employee';

  /// Issue reporting endpoints
  static final String issueTypes = '$baseUrl/issues/get-issue-types';
  static final String createIssue = '$baseUrl/issues/create';
  static final String citizenIssues = '$baseUrl/issues/my-issues';
  static final String updateStatus = '$baseUrl/issues/resolve';
  static final String reportIssue = '$baseUrl/issues/report-false';
  // required issue_label, reason

  // Route endpoints
  static final String shortestRoute = '$baseUrl/routes/shortest';
}
