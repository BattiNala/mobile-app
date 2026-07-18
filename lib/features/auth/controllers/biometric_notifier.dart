import 'package:batti_nala/core/services/biometric_util.dart';
import 'package:batti_nala/core/services/storage_services.dart';
import 'package:batti_nala/features/auth/controllers/biometric_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final biometricNotifierProvider =
    StateNotifierProvider<BiometricNotifier, BiometricState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return BiometricNotifier(storage);
});

class BiometricNotifier extends StateNotifier<BiometricState> {
  final StorageServices _storage;

  BiometricNotifier(this._storage) : super(const BiometricState()) {
    _init();
  }

  Future<void> _init() async {
    final isAvailable = BiometricUtil.instance.deviceHasBiometricCapability;
    final accounts = await _storage.getBiometricAccounts();
    final savedAccounts = accounts.keys.toList();
    state = state.copyWith(
      isAvailable: isAvailable,
      savedAccounts: savedAccounts,
      shouldPromptSetup: isAvailable && savedAccounts.isEmpty,
    );
  }

  void dismissSetupPrompt() {
    state = state.copyWith(shouldPromptSetup: false);
  }

  /// Called after password login to set per-user biometric state and offer
  /// setup if this user hasn't enabled it yet.
  Future<void> verifyForUser(String email) async {
    if (email.isEmpty) return;
    final isEnabled = await _storage.hasBiometricForUser(email);
    state = state.copyWith(
      isEnabled: isEnabled,
      storedUsername: isEnabled ? email : null,
      clearStoredUsername: !isEnabled,
      shouldPromptSetup: state.isAvailable && !isEnabled,
    );
  }

  Future<bool> authenticate() async {
    state = state.copyWith(isAuthenticating: true, error: null);
    try {
      final result = await BiometricUtil.instance.didAuthenticate();
      state = state.copyWith(isAuthenticating: false);
      return result;
    } catch (e) {
      state = state.copyWith(isAuthenticating: false, error: e.toString());
      return false;
    }
  }

  Future<void> enableBiometric(String username) async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) return;
    await _storage.addBiometricAccount(username, refreshToken);
    final accounts = await _storage.getBiometricAccounts();
    state = state.copyWith(
      isEnabled: true,
      storedUsername: username,
      savedAccounts: accounts.keys.toList(),
    );
  }

  Future<void> disableBiometricForUser(String email) async {
    await _storage.removeBiometricAccount(email);
    final accounts = await _storage.getBiometricAccounts();
    state = state.copyWith(
      isEnabled: false,
      clearStoredUsername: true,
      savedAccounts: accounts.keys.toList(),
      shouldPromptSetup: state.isAvailable,
    );
  }

  /// Convenience wrapper — disables for the currently signed-in user.
  Future<void> disableBiometric() async {
    if (state.storedUsername != null) {
      await disableBiometricForUser(state.storedUsername!);
    }
  }

}
