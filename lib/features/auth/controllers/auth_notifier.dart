import 'package:batti_nala/core/error/error_response.dart';
import 'package:batti_nala/features/auth/controllers/biometric_notifier.dart';
import 'package:batti_nala/features/shared/models/user_model.dart';
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
    state = state.copyWith(isLoading: true, clearErrorMessage: true);

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

      if (!mounted) return;
      state = state.copyWith(user: user, isLoading: false);

      if (user.isVerified) {
        final roleLower = user.role.toLowerCase();
        if (roleLower == 'citizen') {
          await ref.read(dashboardProvider.notifier).refreshReports();
        } else if (roleLower == 'staff') {
          await ref.read(employeeDashboardProvider.notifier).refreshReports();
        }
      }
    } on AuthError catch (e) {
      if (!mounted) return;
      // Reset to null first so the listener fires even if the same error repeats
      state = state.copyWith(isLoading: false, clearErrorMessage: true);
      if (!mounted) return;
      state = state.copyWith(errorMessage: e.detail);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, clearErrorMessage: true);
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
    state = state.copyWith(isLoading: true, clearErrorMessage: true);

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

      if (user.isVerified) {
        final roleLower = user.role.toLowerCase();
        if (roleLower == 'citizen') {
          await ref.read(dashboardProvider.notifier).refreshReports();
        } else if (roleLower == 'staff') {
          await ref.read(employeeDashboardProvider.notifier).refreshReports();
        }
      }
    } on AuthError catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, clearErrorMessage: true);
      if (!mounted) return;
      state = state.copyWith(errorMessage: e.detail);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, clearErrorMessage: true);
      if (!mounted) return;
      state = state.copyWith(errorMessage: 'An unexpected error occurred');
    }
  }

  /// LOGOUT
  Future<void> logout() async {
    final email = state.email ?? '';
    final hasBiometric = await _storageServices.hasBiometricForUser(email);
    if (hasBiometric) {
      // Refresh the stored token for this user before wiping the session,
      // in case it was silently rotated since the user enabled biometric.
      final currentToken = await _storageServices.getRefreshToken();
      if (currentToken != null && email.isNotEmpty) {
        await _storageServices.addBiometricAccount(email, currentToken);
      }
      await _storageServices.softLogout();
    } else {
      await _storageServices.clearAll();
    }
    if (!mounted) return;
    state = AuthState();

    ref.invalidate(biometricNotifierProvider);
    ref.invalidate(profileNotifierProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(employeeDashboardProvider);
  }

  /// BIOMETRIC LOGIN — loads the stored refresh token for [username], exchanges
  /// it for a fresh access token, then updates the biometric map with the
  /// new token so subsequent logins keep working.
  Future<void> loginWithRefreshToken(String username) async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final storedToken =
          await _storageServices.getRefreshTokenForBiometricUser(username);
      if (storedToken == null) {
        throw Exception('No biometric token found for $username');
      }
      // Temporarily place this user's token in the global slot so the
      // repository's refreshToken() call picks it up.
      await _storageServices.saveRefreshToken(storedToken);

      final authResponse = await _authRepository.refreshToken();
      final isVerified = await _storageServices.getIsVerified() ?? true;

      // Persist the rotated refresh token back into the biometric map.
      final newToken = await _storageServices.getRefreshToken();
      if (newToken != null) {
        await _storageServices.addBiometricAccount(username, newToken);
      }

      final role = authResponse.roleName.toLowerCase();
      if (role != 'citizen' && role != 'staff') {
        throw AuthError(detail: 'Login not allowed for $role role.');
      }

      final user = User(role: authResponse.roleName, isVerified: isVerified);

      if (!mounted) return;
      state = state.copyWith(user: user, isLoading: false, email: username);

      if (role == 'citizen') {
        await ref.read(dashboardProvider.notifier).refreshReports();
      } else if (role == 'staff') {
        await ref.read(employeeDashboardProvider.notifier).refreshReports();
      }
    } catch (e) {
      if (!mounted) return;
      // Token expired — remove only this user's entry, leave others intact.
      await _storageServices.removeBiometricAccount(username);
      ref.invalidate(biometricNotifierProvider);
      state = state.copyWith(isLoading: false, clearErrorMessage: true);
      if (!mounted) return;
      state = state.copyWith(
        errorMessage:
            'Your session has expired. Please sign in with your password.',
      );
    }
  }

  /// VERIFY USER
  Future<void> verify() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      await _authRepository.verify(code: state.verificationCode);

      // Update storage and state
      await _storageServices.saveIsVerified(true);
      if (state.user != null) {
        final updatedUser = User(role: state.user!.role, isVerified: true);
        state = state.copyWith(user: updatedUser);

        final roleLower = updatedUser.role.toLowerCase();
        if (roleLower == 'citizen') {
          await ref.read(dashboardProvider.notifier).refreshReports();
        } else if (roleLower == 'staff') {
          await ref.read(employeeDashboardProvider.notifier).refreshReports();
        }
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
    state = state.copyWith(isLoading: true, clearErrorMessage: true);

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

  /// SESSION RESTORE (called by biometric login after successful auth)
  Future<void> restoreSession() => _loadUserFromStorage();

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
        
        if (isVerified) {
          final roleLower = role.toLowerCase();
          if (roleLower == 'citizen') {
            await ref.read(dashboardProvider.notifier).refreshReports();
          } else if (roleLower == 'staff') {
            await ref.read(employeeDashboardProvider.notifier).refreshReports();
          }
        } else {
          await ref.read(profileNotifierProvider.notifier).fetchProfile(role);
        }
      }
    } catch (_) {}
  }

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
    state = state.copyWith(clearErrorMessage: true);
  }

  void resetForm() {
    state = state.copyWith(
      name: '',
      phone: '',
      email: '',
      homeAddress: '',
      password: '',
      confirmPassword: '',
      clearErrorMessage: true,
      verificationCode: '',
    );
  }
}
