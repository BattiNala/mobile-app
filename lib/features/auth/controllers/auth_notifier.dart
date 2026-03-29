import 'package:batti_nala/core/error/error_response.dart';
import 'package:batti_nala/core/models/user_model.dart';
import 'package:batti_nala/core/services/storage_services.dart';
import 'package:batti_nala/features/auth/controllers/auth_state.dart';
import 'package:batti_nala/features/auth/repositories/auth_repository.dart';
import 'package:batti_nala/features/profile/controller/profile_notifer.dart';
import 'package:batti_nala/features/citizen_dashboard/controllers/citizen_dashboard_notifier.dart';
import 'package:batti_nala/features/staff_dashboard/controller/employee_dashboard_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final repository = ref.watch(authRepositoryProvider);
  final storage = ref.watch(storageServiceProvider);
  return AuthNotifier(repository, storage, ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  final AuthRepository _authRepository;
  final StorageServices _storageServices;

  AuthNotifier(this._authRepository, this._storageServices, this.ref)
    : super(AuthState()) {
    _loadUserFromStorage();
  }

  /// LOGIN
  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final authResponse = await _authRepository.login(
        username: username,
        password: password,
      );

      final role = authResponse.roleName.toLowerCase();
      if (role != 'citizen' && role != 'staff') {
        await logout();
        throw AuthError(detail: 'Login not allowed for $role role.');
      }

      final user = User(
        role: authResponse.roleName,
        isVerified: authResponse.isVerified ?? false,
      );

      if (user.isVerified) {
        await ref
            .read(profileNotifierProvider.notifier)
            .fetchProfile(user.role);
      }

      if (!mounted) return;
      state = state.copyWith(user: user, isLoading: false);
    } on AuthError catch (e) {
      if (!mounted) return;
      // Reset to null first so the listener fires even if the same error repeats
      state = state.copyWith(isLoading: false, errorMessage: null);
      if (!mounted) return;
      state = state.copyWith(errorMessage: e.detail);
      rethrow;
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: null);
      if (!mounted) return;
      state = state.copyWith(
        errorMessage:
            'Connection failed. Please check your internet or try again later.',
      );
    }
  }

  /// REGISTER
  Future<void> register({
    required String username,
    required String password,
    required String name,
    required String phoneNumber,
    required String email,
    required String homeAddress,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final authResponse = await _authRepository.register(
        username: username,
        password: password,
        name: name,
        phoneNumber: phoneNumber,
        email: email,
        homeAddress: homeAddress,
      );

      final user = User(
        role: authResponse.roleName,
        isVerified: authResponse.isVerified ?? false,
      );

      if (user.isVerified) {
        await ref
            .read(profileNotifierProvider.notifier)
            .fetchProfile(user.role);
      }

      if (!mounted) return;
      state = state.copyWith(
        user: user,
        name: name,
        email: email,
        phone: phoneNumber,
        homeAddress: homeAddress,
        isLoading: false,
        errorMessage: null,
      );
    } on AuthError catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: null);
      if (!mounted) return;
      state = state.copyWith(errorMessage: e.detail);
      rethrow;
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: null);
      if (!mounted) return;
      state = state.copyWith(errorMessage: 'An unexpected error occurred: $e');
      rethrow;
    }
  }

  /// LOGOUT
  Future<void> logout() async {
    await _authRepository.logout();
    await _storageServices.clearAll();
    if (!mounted) return;
    state = AuthState();

    // Invalidate providers to clear stale data
    ref.invalidate(profileNotifierProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(employeeDashboardProvider);
  }

  /// VERIFY USER
  Future<void> verify() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authRepository.verify(code: state.verificationCode);

      // Update storage and state
      await _storageServices.saveIsVerified(true);
      if (state.user != null) {
        final updatedUser = User(role: state.user!.role, isVerified: true);
        state = state.copyWith(user: updatedUser);

        // Fetch profile once verified
        await ref
            .read(profileNotifierProvider.notifier)
            .fetchProfile(updatedUser.role);
      }

      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        isVerified: true,
        verificationMessage: 'User verified successfully',
      );
    } on AuthError catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: e.detail);
      rethrow;
    }
  }

  /// RESEND VERIFICATION
  Future<void> resendVerification() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authRepository.resendVerification();

      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        verificationMessage: 'Verification code resent successfully',
      );
    } on AuthError catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: e.detail);
      rethrow;
    }
  }

  /// SESSION RESTORE
  Future<void> _loadUserFromStorage() async {
    try {
      final accessToken = await _storageServices.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        return;
      }

      final role = await _storageServices.getUserRole();
      final isVerified = await _storageServices.getIsVerified() ?? false;

      if (role != null) {
        final user = User(role: role, isVerified: isVerified);

        if (!mounted) return;
        state = state.copyWith(user: user);
        await ref.read(profileNotifierProvider.notifier).fetchProfile(role);
      }
    } catch (_) {}
  }

  // /// TOKEN REFRESH
  // Future<void> _refreshAccessTokenIfNeeded() async {
  //   try {
  //     final refreshToken = await _storageServices.getRefreshToken();

  //     if (refreshToken == null || refreshToken.isEmpty) return;

  //     final newAuthResponse = await _authRepository.refreshToken();

  //     await _storageServices.saveAccessToken(newAuthResponse.accessToken);
  //     await _storageServices.saveRefreshToken(newAuthResponse.refreshToken);
  //   } catch (_) {
  //     await _storageServices.clearAll();
  //     state = AuthState();
  //   }
  // }

  /// FORM HELPERS
  void updateName(String name) {
    state = state.copyWith(name: name.trim());
  }

  void updateEmail(String email) {
    state = state.copyWith(email: email.trim());
  }

  void updatePhone(String phone) {
    state = state.copyWith(phone: phone.trim());
  }

  void updatePassword(String password) {
    state = state.copyWith(password: password.trim());
  }

  void updateConfirmPassword(String confirmPassword) {
    state = state.copyWith(confirmPassword: confirmPassword.trim());
  }

  void updateHomeAddress(String address) {
    state = state.copyWith(homeAddress: address.trim());
  }

  void updateVerificationCode(String code) {
    state = state.copyWith(verificationCode: code);
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
    state = AuthState();
  }

  void resetForm() {
    state = state.copyWith(
      name: '',
      phone: '',
      email: '',
      homeAddress: '',
      password: '',
      confirmPassword: '',
      errorMessage: null,
      verificationCode: '',
    );
  }
}
