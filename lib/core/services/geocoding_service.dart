import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GeocodingService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  static const String _nominatimUrl =
      'https://nominatim.openstreetmap.org/reverse';

  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final response = await _dio.get(
        _nominatimUrl,
        queryParameters: {
          'format': 'json',
          'lat': lat,
          'lon': lng,
          'zoom': 18,
          'addressdetails': 1,
        },
        options: Options(
          headers: {'User-Agent': 'BattiNalaApp/1.0', 'Accept-Language': 'en'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return _formatAddress(response.data);
      } else {
        debugPrint('Geocoding Warning: Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Geocoding critical error: $e');
    }
    return _formatCoordinatesOnly(lat, lng);
  }

  String _formatAddress(Map<String, dynamic> data) {
    final address = data['address'] as Map<String, dynamic>?;

    if (address != null) {
      final parts = <String>[];
      final keys = [
        'road',
        'neighbourhood',
        'suburb',
        'hamlet',
        'village',
        'city',
        'state',
        'country',
      ];

      for (var key in keys) {
        if (address[key] != null) {
          final value = address[key].toString();
          if (!parts.contains(value)) parts.add(value);
        }
      }

      if (parts.isNotEmpty) return parts.join(', ');
    }

    return data['display_name'] ?? _formatCoordinatesOnly(0, 0);
  }

  String _formatCoordinatesOnly(double lat, double lng) {
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(4)}°$latDir, ${lng.abs().toStringAsFixed(4)}°$lngDir';
  }
}

final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  return GeocodingService();
});

final addressProvider =
    FutureProvider.family<String, ({double lat, double lng})>((
      ref,
      location,
    ) async {
      final service = ref.read(geocodingServiceProvider);
      return await service.getAddressFromCoordinates(
        location.lat,
        location.lng,
      );
    });
