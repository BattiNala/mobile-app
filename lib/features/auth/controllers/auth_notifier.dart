import 'package:batti_nala/features/auth/controllers/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  void updateName(String name) {
    state = state.copyWith(
      name: name,
      errorMessage: null,
    ); // Clear error when typing
  }

  void updatePhone(String phone) {
    state = state.copyWith(
      phone: phone,
      errorMessage: null,
    ); // Clear error when typing
  }

  void updateEmail(String email) {
    state = state.copyWith(
      email: email,
      errorMessage: null,
    ); // Clear error when typing
  }

  void updatePassword(String password) {
    state = state.copyWith(password: password, errorMessage: null);
  }

  void updateConfirmPassword(String confirmPassword) {
    state = state.copyWith(
      confirmPassword: confirmPassword,
      errorMessage: null,
    );
  }

  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordObscured: !state.isPasswordObscured);
  }

  void toggleConfirmPasswordVisibility() {
    state = state.copyWith(
      isConfirmPasswordObscured: !state.isConfirmPasswordObscured,
    );
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<bool> login() async {
    try {
      // Clear previous errors and set loading
      state = state.copyWith(isLoading: true, errorMessage: null);

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Success
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Connection error. Please try again.',
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> signup() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      // email or phone number is necessary
      if (state.email.isEmpty && state.phone.isEmpty) {
        state = state.copyWith(
          errorMessage: 'Please enter either email or phone number',
          isLoading: false,
        );
        return false;
      }
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Success
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Connection error. Please try again.',
        isLoading: false,
      );
      return false;
    }
  }

  // Reset form
  void resetForm() {
    state = AuthState();
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
