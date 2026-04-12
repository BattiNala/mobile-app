import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Coordinates {
  final double latitude;
  final double longitude;

  const Coordinates({required this.latitude, required this.longitude});
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
      locationSettings: LocationSettings(accuracy: accuracy, timeLimit: timeLimit),
    );

    return Coordinates(latitude: position.latitude, longitude: position.longitude);
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});
