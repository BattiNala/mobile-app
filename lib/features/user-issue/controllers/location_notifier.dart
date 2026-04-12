import 'package:batti_nala/core/services/geocoding_service.dart';
import 'package:batti_nala/core/services/location_service.dart';
import 'package:batti_nala/features/user-issue/controllers/location_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService;

  LocationNotifier(this._locationService)
    : super(const LocationState.initial());

  Future<void> fetchCurrentLocation() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final coords = await _locationService.getCurrentCoordinates();
      if (!mounted) return;

      final address = await getAddressFromCoordinates(
        coords.latitude,
        coords.longitude,
      );

      state = state.copyWith(
        isLoading: false,
        issueLocation: address,
        latitude: coords.latitude,
        longitude: coords.longitude,
      );
    } catch (e) {
      if (!mounted) return;
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
