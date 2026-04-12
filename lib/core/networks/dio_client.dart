import 'package:batti_nala/core/constants/api_url.dart';
import 'package:batti_nala/core/networks/auth_interceptor.dart';
import 'package:batti_nala/core/services/storage_services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiUrl.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'BattinalaApp/1.2.0 (android)',
      },
    ),
  );

  // Add interceptors if needed (e.g., for logging, authentication, etc.)
  dio.interceptors.add(
    LogInterceptor(request: true, requestBody: true, responseBody: true),
  );

  dio.interceptors.add(AuthInterceptor(ref.read(storageServiceProvider)));

  return dio;
});
