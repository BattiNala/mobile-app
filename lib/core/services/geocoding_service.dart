import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Returns a human-readable address string from [lat]/[lng] using Nominatim (OSM).
/// Falls back to coordinate string on failure.
Future<String> getAddressFromCoordinates(double lat, double lng) async {
  try {
    final response = await Dio().get(
      'https://nominatim.openstreetmap.org/reverse',
      queryParameters: {
        'format': 'json',
        'lat': lat,
        'lon': lng,
        'zoom': 18,
        'addressdetails': 1,
      },
      options: Options(
        headers: {'User-Agent': 'BattiNala/1.0'},
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final Map<String, dynamic> data = response.data;
      final address = data['address'] as Map<String, dynamic>?;

      if (address != null) {
        // Build address from available components
        final parts = <String>[
          if (address['road']?.isNotEmpty == true) address['road'] as String,
          if (address['suburb']?.isNotEmpty == true)
            address['suburb'] as String,
          if (address['city']?.isNotEmpty == true) address['city'] as String,
          if (address['district']?.isNotEmpty == true)
            address['district'] as String,
          if (address['state']?.isNotEmpty == true) address['state'] as String,
        ].where((s) => s.isNotEmpty).toSet().toList();

        if (parts.isNotEmpty) return parts.join(', ');

        // Fallback to display_name if components unavailable
        final displayName = data['display_name'] as String?;
        if (displayName?.isNotEmpty == true) return displayName!;
      }
    }
  } catch (e) {
    debugPrint('[GEOCODING] Nominatim error: $e');
  }

  // Fallback to coordinate format
  final latDir = lat >= 0 ? 'N' : 'S';
  final lngDir = lng >= 0 ? 'E' : 'W';
  return '${lat.abs().toStringAsFixed(4)}°$latDir, ${lng.abs().toStringAsFixed(4)}°$lngDir';
}

final addressProvider =
    FutureProvider.family<String, ({double lat, double lng})>((
      ref,
      location,
    ) async {
      return getAddressFromCoordinates(location.lat, location.lng);
    });
