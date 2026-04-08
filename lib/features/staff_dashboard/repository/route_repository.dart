import 'package:batti_nala/core/constants/api_url.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:batti_nala/core/networks/dio_client.dart';
import 'package:batti_nala/features/staff_dashboard/model/route_model.dart';

final routeRepositoryProvider = Provider<RouteRepository>((ref) {
  final dioClient = ref.read(dioProvider);
  return RouteRepository(dioClient);
});

class RouteRepository {
  final Dio _dioClient;

  RouteRepository(this._dioClient);

  Future<RouteResponseModel> getShortestRoute(RouteRequest request) async {
    final response = await _dioClient.post(
      ApiUrl.shortestRoute,
      data: {
        'start': {
          'latitude': request.start.latitude,
          'longitude': request.start.longitude,
        },
        'destination': {
          'latitude': request.destination.latitude,
          'longitude': request.destination.longitude,
        },
      },
    );
    return RouteResponseModel.fromJson(response.data);
  }
}
