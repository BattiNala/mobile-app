import 'package:batti_nala/features/auth/controllers/auth_state.dart';
import 'package:batti_nala/features/auth/repositories/auth_repository.dart';
import 'package:batti_nala/features/auth/models/auth_response_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthState());

  void updateName(String name) {
    state = state.copyWith(name: name, errorMessage: null);
  }

  void updatePhone(String phone) {
    state = state.copyWith(phone: phone, errorMessage: null);
  }

  void updateEmail(String email) {
    state = state.copyWith(email: email, errorMessage: null);
  }

  void updateHomeAddress(String homeAddress) {
    state = state.copyWith(homeAddress: homeAddress, errorMessage: null);
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

      // Make API call - use email as username
      await _authRepository.login(
        username: state.email ?? state.phone,
        password: state.password,
      );

      // Success
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthError catch (e) {
      state = state.copyWith(errorMessage: e.detail, isLoading: false);
      return false;
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

      // Make API call - use email as username
      await _authRepository.register(
        username: state.email ?? state.phone,
        password: state.password,
        name: state.name,
        phoneNumber: state.phone,
        email: state.email!,
        homeAddress: state.homeAddress,
      );

      // Success
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthError catch (e) {
      state = state.copyWith(errorMessage: e.detail, isLoading: false);
      return false;
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
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});
