import 'package:batti_nala/core/constants/api_url.dart';
import 'package:batti_nala/core/services/storage_services.dart';
import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  final StorageServices _storage;
  AuthInterceptor(this._storage);

  /// Flag to indicate if a token refresh is in progress
  static bool _isRefreshing = false;
  static final List<void Function(Response)> _retryQueue = [];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.path.contains('/auth/login') ||
        options.path.contains('/auth/register')) {
      return handler.next(options);
    }

    final token = await _storage.getAccessToken();

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized (Expired Token)
    if (err.response?.statusCode == 401) {
      final refreshToken = await _storage.getRefreshToken();

      // No refresh token available - user must login again
      if (refreshToken == null) {
        print(
          "Interceptor: No refresh token available. Clearing storage and requiring login.",
        );
        await _storage.clearAll();
        return handler.next(err);
      }

      // Already attempting to refresh - queue this request
      if (_isRefreshing) {
        _retryQueue.add((response) async {
          final options = err.requestOptions;
          options.headers['Authorization'] =
              'Bearer ${await _storage.getAccessToken()}';
          final retryResponse = await Dio().fetch(options);
          handler.resolve(retryResponse);
        });
        return;
      }

      _isRefreshing = true;

      try {
        // Call Refresh Token API
        final dio = Dio();
        final result = await dio.post(
          ApiUrl.getRefreshToken,
          data: {'refreshToken': refreshToken},
        );

        if (result.statusCode == 200) {
          final newAccessToken = result.data['accessToken'];
          final newRefreshToken = result.data['refreshToken'];

          await _storage.saveAccessToken(newAccessToken);
          await _storage.saveRefreshToken(newRefreshToken);
          print("Interceptor: Token refreshed successfully");

          // Retry all queued requests
          for (final retry in _retryQueue) {
            retry(result);
          }
          _retryQueue.clear();
        } else {
          // Refresh failed clear storage and force login
          print(
            "Interceptor: Token refresh failed with status ${result.statusCode}",
          );
          await _storage.clearAll();
        }
      } catch (e) {
        // Refresh token API error clear storage and force login
        print("Interceptor: Token refresh error: $e");
        await _storage.clearAll();
      } finally {
        _isRefreshing = false;
      }
    }

    return handler.next(err);
  }
}
