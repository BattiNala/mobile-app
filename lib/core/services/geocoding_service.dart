import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';

/// Returns a human-readable address string from [lat]/[lng].
/// Falls back to coordinate string on failure.
Future<String> getAddressFromCoordinates(double lat, double lng) async {
  try {
    final placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isNotEmpty) {
      final p = placemarks.first;
      final parts = <String>[
        if (p.street?.isNotEmpty == true) p.street!,
        if (p.subLocality?.isNotEmpty == true) p.subLocality!,
        if (p.locality?.isNotEmpty == true) p.locality!,
        if (p.administrativeArea?.isNotEmpty == true) p.administrativeArea!,
      ].where((s) => s.isNotEmpty).toSet().toList();

      if (parts.isNotEmpty) return parts.join(', ');
    }
  } catch (e) {
    debugPrint('Geocoding error: $e');
  }
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
