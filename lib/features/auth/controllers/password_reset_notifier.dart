import 'package:batti_nala/core/error/error_response.dart';
import 'package:batti_nala/features/auth/repositories/auth_repository.dart';
import 'package:batti_nala/features/auth/controllers/password_reset_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final passwordResetProvider = StateNotifierProvider<
    PasswordResetNotifier, PasswordResetState>((ref) {
  final repository = ref.read(authRepositoryProvider);
  return PasswordResetNotifier(repository);
});

class PasswordResetNotifier extends StateNotifier<PasswordResetState> {
  final AuthRepository _repository;

  PasswordResetNotifier(this._repository)
      : super(const PasswordResetState.initial());

  void updateUsername(String username) {
    state = state.copyWith(username: username, errorMessage: null);
  }

  void updateOtpCode(String code) {
    state = state.copyWith(otpCode: code, errorMessage: null);
  }

  void updateNewPassword(String password) {
    state = state.copyWith(newPassword: password, errorMessage: null);
  }

  void updateConfirmPassword(String password) {
    state = state.copyWith(confirmPassword: password, errorMessage: null);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  Future<void> requestOtp() async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      await _repository.requestPasswordReset(username: state.username);
      state = state.copyWith(isLoading: false, step: PasswordResetStep.verifyOtp);
    } catch (e) {
      final message = e is AuthError ? e.detail : e.toString();
      state = state.copyWith(
        isLoading: false,
        errorMessage: message,
      );
    }
  }

  Future<void> verifyOtp() async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      final response = await _repository.verifyPasswordResetOtp(
        username: state.username,
        code: state.otpCode,
      );
      state = state.copyWith(
        isLoading: false,
        step: PasswordResetStep.confirmPassword,
        resetToken: response.resetToken,
      );
    } catch (e) {
      final message = e is AuthError ? e.detail : e.toString();
      state = state.copyWith(
        isLoading: false,
        errorMessage: message,
      );
    }
  }

  Future<void> confirmReset() async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      final token = state.resetToken;
      if (token == null || token.isEmpty) {
        throw Exception('Reset token is missing.');
      }
      await _repository.confirmPasswordReset(
        resetToken: token,
        newPassword: state.newPassword,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Password reset successfully.',
      );
    } catch (e) {
      final message = e is AuthError ? e.detail : e.toString();
      state = state.copyWith(
        isLoading: false,
        errorMessage: message,
      );
    }
  }
}

