import 'package:batti_nala/core/constants/api_url.dart';
import 'package:batti_nala/core/error/error_response.dart';
import 'package:batti_nala/core/networks/dio_client.dart';
import 'package:batti_nala/core/services/storage_services.dart';
import 'package:batti_nala/features/auth/models/auth_request_model.dart';
import 'package:batti_nala/features/auth/models/auth_response_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthRepository {
  final Dio _dio;
  final StorageServices _storage;

  AuthRepository({required Dio dio, required StorageServices storage})
    : _dio = dio,
      _storage = storage;

  /// Login with username and password
  /// Returns AuthResponse with access_token, refresh_token, and role_name
  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final loginRequest = LoginRequest(username: username, password: password);

      final response = await _dio.post(
        ApiUrl.login,
        data: loginRequest.toJson(),
      );

      if (response.statusCode != 200) {
        throw AuthError(detail: response.data.toString());
      } else {
        final authResponse = AuthResponse.fromJson(response.data);
        // Save tokens to secure storage
        await _storage.saveAccessToken(authResponse.accessToken);
        await _storage.saveRefreshToken(authResponse.refreshToken);
        await _storage.saveUserRole(authResponse.roleName);
        return authResponse;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final errorData = e.response?.data;
        if (errorData != null && errorData is Map) {
          throw AuthError.fromJson(errorData as Map<String, dynamic>);
        }
        throw AuthError(detail: 'Invalid credentials');
      }
      if (e.response?.statusCode == 500) {
        throw AuthError(
          detail: 'Internal server error. Please try again later.',
        );
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Register a new citizen user
  /// Returns AuthResponse with access_token, refresh_token, and role_name
  Future<AuthResponse> register({
    required String username,
    required String password,
    required String name,
    required String phoneNumber,
    required String email,
    required String homeAddress,
  }) async {
    try {
      final registerRequest = RegisterRequest(
        username: username,
        password: password,
        name: name,
        phoneNumber: phoneNumber,
        email: email,
        homeAddress: homeAddress,
      );

      final response = await _dio.post(
        ApiUrl.citzenRegister,
        data: registerRequest.toJson(),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);
        await _storage.saveUserRole(authResponse.roleName);
        return authResponse;
      } else {
        throw Exception(
          'Registration failed with status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData != null && errorData is Map) {
          throw AuthError.fromJson(errorData as Map<String, dynamic>);
        }
        throw AuthError(detail: 'User already exists');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Refresh access token using refresh token
  /// Returns new AuthResponse with fresh tokens
  Future<AuthResponse> refreshToken() async {
    try {
      final storedRefreshToken = await _storage.getRefreshToken();
      if (storedRefreshToken == null) {
        throw Exception('No refresh token available');
      }

      final refreshRequest = RefreshTokenRequest(
        refreshToken: storedRefreshToken,
      );

      final response = await _dio.post(
        ApiUrl.getRefreshToken,
        data: refreshRequest.toJson(),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);
        // Update tokens in secure storage
        await _storage.saveAccessToken(authResponse.accessToken);
        await _storage.saveRefreshToken(authResponse.refreshToken);
        await _storage.saveUserRole(authResponse.roleName);
        return authResponse;
      } else {
        throw Exception(
          'Token refresh failed with status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Refresh token is invalid or expired
        await _storage.clearAll();
        throw AuthError(detail: 'Invalid or expired token');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Logout - clears all stored tokens
  Future<void> logout() async {
    if (kDebugMode) {
      print(' [AUTH_REPOSITORY] Logging out user and clearing tokens');
    }
    await _storage.clearAll();
  }

  String _extractAuthErrorDetail(dynamic data, String fallback) {
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail.trim();
      }
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
      return data.toString();
    }
    if (data is String && data.trim().isNotEmpty) return data.trim();
    return fallback;
  }

  /// Request a password reset OTP (email/SMS) for the given username.
  Future<void> requestPasswordReset({required String username}) async {
    try {
      final response = await _dio.post(
        ApiUrl.passwordResetRequest,
        data: PasswordResetRequest(username: username).toJson(),
      );

      if (response.statusCode != 200) {
        throw AuthError(
          detail: _extractAuthErrorDetail(
            response.data,
            'Failed to request password reset.',
          ),
        );
      }
    } on DioException catch (e) {
      final message = _extractAuthErrorDetail(
        e.response?.data,
        e.message ?? '',
      );
      throw AuthError(detail: message);
    }
  }

  /// Verify password reset OTP and receive a reset token.
  Future<PasswordResetVerifyResponse> verifyPasswordResetOtp({
    required String username,
    required String code,
  }) async {
    try {
      final response = await _dio.post(
        ApiUrl.passwordResetVerify,
        data: PasswordResetVerifyRequest(
          username: username,
          code: code,
        ).toJson(),
      );

      if (response.statusCode != 200) {
        throw AuthError(
          detail: _extractAuthErrorDetail(
            response.data,
            'Failed to verify OTP.',
          ),
        );
      }

      return PasswordResetVerifyResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      final message = _extractAuthErrorDetail(
        e.response?.data,
        e.message ?? '',
      );
      throw AuthError(detail: message);
    }
  }

  /// Confirm password reset using reset token + new password.
  Future<void> confirmPasswordReset({
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        ApiUrl.passwordResetConfirm,
        data: PasswordResetConfirmRequest(
          resetToken: resetToken,
          newPassword: newPassword,
        ).toJson(),
      );

      if (response.statusCode != 200) {
        throw AuthError(
          detail: _extractAuthErrorDetail(
            response.data,
            'Failed to reset password.',
          ),
        );
      }
    } on DioException catch (e) {
      final message = _extractAuthErrorDetail(
        e.response?.data,
        e.message ?? '',
      );
      throw AuthError(detail: message);
    }
  }

  /// Verify user with OTP code
  /// Returns success message
  Future<void> verify({required String code}) async {
    try {
      final verifyRequest = VerifyOtpRequest(code: code);

      final response = await _dio.post(
        ApiUrl.verify,
        data: verifyRequest.toJson(),
      );

      if (response.statusCode != 200) {
        throw AuthError(
          detail: response.data['message'] ?? 'Verification failed',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData != null && errorData is Map) {
          throw AuthError.fromJson(errorData as Map<String, dynamic>);
        }
        throw AuthError(detail: 'Invalid or expired OTP');
      }
      if (e.response?.statusCode == 404) {
        throw AuthError(detail: 'No OTP found for user');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Resend OTP verification code
  /// Returns success message
  Future<void> resendVerification() async {
    try {
      final response = await _dio.post(ApiUrl.resendVerification);

      if (response.statusCode != 200) {
        throw AuthError(
          detail: response.data['message'] ?? 'Failed to resend verification',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData != null && errorData is Map) {
          throw AuthError.fromJson(errorData as Map<String, dynamic>);
        }
        throw AuthError(detail: 'User already verified');
      }
      if (e.response?.statusCode == 429) {
        throw AuthError(
          detail: 'Too many requests. Please wait before trying again.',
        );
      }
      throw Exception('Network error: ${e.message}');
    }
  }
}

// Riverpod provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageServiceProvider);
  return AuthRepository(dio: dio, storage: storage);
});
