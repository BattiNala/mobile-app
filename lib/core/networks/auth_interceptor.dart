import 'package:batti_nala/core/constants/api_url.dart';
import 'package:batti_nala/core/services/storage_services.dart';
import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  final StorageServices _storage;
  AuthInterceptor(this._storage);

  bool _isRefreshing = false;
  final List<_PendingRequest> _pendingRequests = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Skip auth endpoints
    if (options.path.contains('/auth/')) {
      return handler.next(options);
    }

    _storage.getAccessToken().then((token) {
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    });
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Don't retry refresh token requests
    if (err.requestOptions.path.contains('/auth/refresh')) {
      _storage.clearAll();
      return handler.next(err);
    }

    _handleTokenRefresh(err, handler);
  }

  void _handleTokenRefresh(DioException err, ErrorInterceptorHandler handler) {
    _storage.getRefreshToken().then((refreshToken) async {
      if (refreshToken == null) {
        await _storage.clearAll();
        return handler.next(err);
      }

      if (_isRefreshing) {
        _pendingRequests.add(_PendingRequest(err.requestOptions, handler));
        return;
      }

      _isRefreshing = true;

      try {
        final response = await Dio().post(
          ApiUrl.getRefreshToken,
          data: {'refresh_token': refreshToken},
        );

        if (response.statusCode == 200) {
          final newToken = response.data['access_token'];
          final newRefreshToken = response.data['refresh_token'];

          await _storage.saveAccessToken(newToken);
          await _storage.saveRefreshToken(newRefreshToken);

          // Retry current request
          _retryRequest(err.requestOptions, newToken, handler);

          // Retry pending requests
          for (var pending in _pendingRequests) {
            _retryRequest(pending.options, newToken, pending.handler);
          }
          _pendingRequests.clear();
        } else {
          await _storage.clearAll();
          handler.next(err);
        }
      } catch (e) {
        await _storage.clearAll();
        handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    });
  }

  void _retryRequest(
    RequestOptions options,
    String token,
    ErrorInterceptorHandler handler,
  ) {
    final newOptions = Options(
      method: options.method,
      headers: {...options.headers, 'Authorization': 'Bearer $token'},
    );

    Dio()
        .request(
          options.path,
          data: options.data,
          queryParameters: options.queryParameters,
          options: newOptions,
        )
        .then((response) {
          handler.resolve(response);
        })
        .catchError((e) {
          handler.next(e as DioException);
        });
  }
}

class _PendingRequest {
  final RequestOptions options;
  final ErrorInterceptorHandler handler;
  _PendingRequest(this.options, this.handler);
}
