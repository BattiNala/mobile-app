import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Coordinates {
  final double latitude;
  final double longitude;

  const Coordinates({
    required this.latitude,
    required this.longitude,
  });
}

class LocationService {
  Future<Coordinates> getCurrentCoordinates({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration? timeLimit,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are denied');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        timeLimit: timeLimit,
      ),
    );

    return Coordinates(latitude: position.latitude, longitude: position.longitude);
  }

  /// Used by the "Use My Location" button to keep the existing behavior.
  String formatCoordinateLocation(double lat, double lng) {
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';
    final latAbs = lat.abs();
    final lngAbs = lng.abs();

    return '${latAbs.toStringAsFixed(4)}°$latDir, ${lngAbs.toStringAsFixed(4)}°$lngDir';
  }

  String getAreaName(double lat, double lng) {
    // Kathmandu area
    if (lat >= 27.68 && lat <= 27.75 && lng >= 85.28 && lng <= 85.35) {
      if (lng < 85.31) return 'Thamel, Kathmandu';
      if (lng < 85.33) return 'Durbarmarg, Kathmandu';
      return 'New Road, Kathmandu';
    }

    // Lalitpur area
    if (lat >= 27.65 && lat <= 27.68 && lng >= 85.31 && lng <= 85.35) {
      return 'Patan, Lalitpur';
    }

    // Bhaktapur area
    if (lat >= 27.66 && lat <= 27.68 && lng >= 85.40 && lng <= 85.44) {
      return 'Bhaktapur';
    }

    return '';
  }

  /// Used by the map picker to build the address shown to users and sent to backend.
  String buildMapAddress(double lat, double lng) {
    final latStr = lat.toStringAsFixed(6);
    final lngStr = lng.toStringAsFixed(6);
    final area = getAreaName(lat, lng);

    return area.isNotEmpty ? '$area ($latStr, $lngStr)' : '$latStr, $lngStr';
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

