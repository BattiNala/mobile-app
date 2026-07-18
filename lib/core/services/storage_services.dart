import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageServices {
  static const storage = FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userRole = 'user_role';
  static const _isVerified = 'is_verified';

  // Multi-account biometric map: {email: refreshToken}
  static const _biometricAccountsKey = 'biometric_accounts';

  // ── Session tokens ──────────────────────────────────────────────────────────

  Future<void> saveAccessToken(String token) async {
    await storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return storage.read(key: _accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return storage.read(key: _refreshTokenKey);
  }

  Future<void> saveUserRole(String role) async {
    await storage.write(key: _userRole, value: role);
  }

  Future<String?> getUserRole() async {
    return storage.read(key: _userRole);
  }

  Future<void> saveIsVerified(bool isVerified) async {
    await storage.write(key: _isVerified, value: isVerified.toString());
  }

  Future<bool?> getIsVerified() async {
    final value = await storage.read(key: _isVerified);
    return value == null ? null : value == 'true';
  }

  // ── Biometric accounts map ──────────────────────────────────────────────────

  Future<Map<String, String>> getBiometricAccounts() async {
    final raw = await storage.read(key: _biometricAccountsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return decoded.map((k, v) => MapEntry(k, v as String));
      } catch (_) {}
    }
    // One-time migration from old single-account keys.
    final oldEnabled = await storage.read(key: 'biometric_enabled');
    if (oldEnabled == 'true') {
      final oldUser = await storage.read(key: 'biometric_username');
      final oldToken = await storage.read(key: _refreshTokenKey);
      if (oldUser != null && oldToken != null) {
        final migrated = {oldUser: oldToken};
        await storage.write(
          key: _biometricAccountsKey,
          value: jsonEncode(migrated),
        );
        await storage.delete(key: 'biometric_enabled');
        await storage.delete(key: 'biometric_username');
        return migrated;
      }
    }
    return {};
  }

  Future<void> addBiometricAccount(String email, String refreshToken) async {
    final accounts = await getBiometricAccounts();
    accounts[email] = refreshToken;
    await storage.write(
      key: _biometricAccountsKey,
      value: jsonEncode(accounts),
    );
  }

  Future<void> removeBiometricAccount(String email) async {
    final accounts = await getBiometricAccounts();
    accounts.remove(email);
    if (accounts.isEmpty) {
      await storage.delete(key: _biometricAccountsKey);
    } else {
      await storage.write(
        key: _biometricAccountsKey,
        value: jsonEncode(accounts),
      );
    }
  }

  Future<String?> getRefreshTokenForBiometricUser(String email) async {
    final accounts = await getBiometricAccounts();
    return accounts[email];
  }

  Future<bool> hasBiometricForUser(String email) async {
    if (email.isEmpty) return false;
    final accounts = await getBiometricAccounts();
    return accounts.containsKey(email);
  }

  // True if any account has biometric saved on this device.
  Future<bool> isBiometricEnabled() async {
    final accounts = await getBiometricAccounts();
    return accounts.isNotEmpty;
  }

  // ── Logout helpers ──────────────────────────────────────────────────────────

  /// Wipes everything including biometric accounts (full sign-out).
  Future<void> clearAll() async {
    await storage.deleteAll();
  }

  /// Clears only the active session; biometric accounts survive so chips
  /// remain on the login screen for all saved users.
  Future<void> softLogout() async {
    await storage.delete(key: _accessTokenKey);
    await storage.delete(key: _refreshTokenKey);
    await storage.delete(key: _isVerified);
    await storage.delete(key: _userRole);
  }

  /// Clears the active session without touching biometric accounts.
  /// Used by the auth repository after a 401 on token refresh.
  Future<void> clearSession() async {
    await storage.delete(key: _accessTokenKey);
    await storage.delete(key: _refreshTokenKey);
    await storage.delete(key: _isVerified);
    await storage.delete(key: _userRole);
  }
}

final storageServiceProvider = Provider<StorageServices>((ref) {
  return StorageServices();
});
