import 'package:latlong2/latlong.dart';

class RouteRequest {
  final LatLng start;
  final LatLng destination;

  RouteRequest({required this.start, required this.destination});

  Map<String, dynamic> toJson() {
    return {
      'start': [start.latitude, start.longitude],
      'destination': [destination.latitude, destination.longitude],
    };
  }
}

class RouteResponseModel {
  final double distanceKm;
  final List<LatLng> path;
  final LatLng snappedStart;
  final LatLng snappedDestination;

  RouteResponseModel({
    required this.distanceKm,
    required this.path,
    required this.snappedStart,
    required this.snappedDestination,
  });

  factory RouteResponseModel.fromJson(Map<String, dynamic> json) {
    return RouteResponseModel(
      distanceKm: (json['distance_km'] as num).toDouble(),
      path: (json['path'] as List)
          .map(
            (item) => LatLng(
              (item['latitude'] as num).toDouble(),
              (item['longitude'] as num).toDouble(),
            ),
          )
          .toList(),
      snappedStart: LatLng(
        (json['snapped_start']['latitude'] as num).toDouble(),
        (json['snapped_start']['longitude'] as num).toDouble(),
      ),
      snappedDestination: LatLng(
        (json['snapped_destination']['latitude'] as num).toDouble(),
        (json['snapped_destination']['longitude'] as num).toDouble(),
      ),
    );
  }
}
