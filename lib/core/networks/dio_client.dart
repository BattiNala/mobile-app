import 'package:batti_nala/core/constants/api_url.dart';
import 'package:batti_nala/core/networks/auth_interceptor.dart';
import 'package:batti_nala/core/services/storage_services.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiUrl.baseUrl,
      connectTimeout: const Duration(seconds: 1),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'BattinalaApp/1.2.0 (android)',
      },
    ),
  );

  // Add interceptors if needed (e.g., for logging, authentication, etc.)
  dio.interceptors.add(
    LogInterceptor(
      request: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      requestHeader: false,
    ),
  );

  dio.interceptors.add(AuthInterceptor(ref.read(storageServiceProvider)));

  return dio;
});
