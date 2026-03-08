import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

class StorageServices {
  final storage = FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userRole = 'user_role';

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

  // Delete all tokens and user role
  Future<void> clearAll() async {
    await storage.deleteAll();
  }
}

final storageServiceProvider = Provider<StorageServices>((ref) {
  return StorageServices();
});
