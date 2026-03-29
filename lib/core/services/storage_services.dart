import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageServices {
  static const storage = FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userRole = 'user_role';
  static const _isVerified = 'is_verified';

  // Save access token
  Future<void> saveAccessToken(String token) async {
    await storage.write(key: _accessTokenKey, value: token);
  }

  // Get access token
  Future<String?> getAccessToken() async {
    return await storage.read(key: _accessTokenKey);
  }

  // Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await storage.write(key: _refreshTokenKey, value: token);
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    return await storage.read(key: _refreshTokenKey);
  }

  // Save user role
  Future<void> saveUserRole(String role) async {
    await storage.write(key: _userRole, value: role);
  }

  // Save verification status
  Future<void> saveIsVerified(bool isVerified) async {
    await storage.write(key: _isVerified, value: isVerified.toString());
  }

  // Get verification status
  Future<bool?> getIsVerified() async {
    final value = await storage.read(key: _isVerified);
    return value == null ? null : value == 'true';
  }

  // Delete all tokens and user role
  Future<void> clearAll() async {
    await storage.deleteAll();
  }

  Future<String?> getUserRole() async {
    return await storage.read(key: _userRole);
  }
}

final storageServiceProvider = Provider<StorageServices>((ref) {
  return StorageServices();
});
