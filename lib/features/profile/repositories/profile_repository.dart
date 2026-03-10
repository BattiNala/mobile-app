import 'package:batti_nala/core/constants/api_url.dart';
import 'package:batti_nala/core/error/error_response.dart';
import 'package:batti_nala/core/networks/dio_client.dart';
import 'package:batti_nala/features/profile/model/profile_response_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileRepository {
  final Dio _dio;

  ProfileRepository({required Dio dio}) : _dio = dio;

  /// Get citizen profile
  /// Returns CitizenProfile with name, email, phone_number, address, trust_score
  Future<CitizenProfile> getCitizenProfile() async {
    try {
      final response = await _dio.get(ApiUrl.citizenProfile);

      if (response.statusCode == 200) {
        return CitizenProfile.fromJson(response.data);
      } else {
        throw Exception(
          'Failed to fetch citizen profile with status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthError(detail: 'Unauthorized. Please login again.');
      }
      if (e.response?.statusCode == 404) {
        throw AuthError(detail: 'Profile not found.');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Get employee profile
  /// Returns EmployeeProfile with name, email, phone_number, department, employee_id
  Future<EmployeeProfile> getEmployeeProfile() async {
    try {
      final response = await _dio.get(ApiUrl.employeeProfile);

      if (response.statusCode == 200) {
        return EmployeeProfile.fromJson(response.data);
      } else {
        throw Exception(
          'Failed to fetch employee profile with status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthError(detail: 'Unauthorized. Please login again.');
      }
      if (e.response?.statusCode == 404) {
        throw AuthError(detail: 'Profile not found.');
      }
      throw Exception('Network error: ${e.message}');
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ProfileRepository(dio: dio);
});
