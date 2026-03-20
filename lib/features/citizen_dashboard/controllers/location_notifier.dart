import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:batti_nala/core/services/location_service.dart';

// ignore: always_use_package_imports
import 'location_state.dart';

class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService;

  LocationNotifier(this._locationService)
    : super(const LocationState.initial());

  Future<void> fetchCurrentLocation() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final coords = await _locationService.getCurrentCoordinates();
      final locationString = _locationService.formatCoordinateLocation(
        coords.latitude,
        coords.longitude,
      );

      state = state.copyWith(
        isLoading: false,
        issueLocation: locationString,
        latitude: coords.latitude,
        longitude: coords.longitude,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error getting location: $e',
      );
    }
  }

  void setMapLocation({
    required String address,
    required double latitude,
    required double longitude,
  }) {
    state = state.copyWith(
      errorMessage: null,
      issueLocation: address,
      latitude: latitude,
      longitude: longitude,
    );
  }

  void clear() {
    state = const LocationState.initial();
  }
}

final locationNotifierProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
      final locationService = ref.read(locationServiceProvider);
      return LocationNotifier(locationService);
    });
