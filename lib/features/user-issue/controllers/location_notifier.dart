import 'package:batti_nala/core/services/geocoding_service.dart';
import 'package:batti_nala/core/services/location_service.dart';
import 'package:batti_nala/features/user-issue/controllers/location_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService;

  LocationNotifier(this._locationService)
    : super(const LocationState.initial());

  Future<void> fetchCurrentLocation() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      isPermissionPermanentlyDenied: false,
    );

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

      String message = 'Error getting location: $e';
      bool permanentlyDenied = false;

      if (e.toString().contains('PERMISSION_DENIED_FOREVER')) {
        message =
            'Location access is blocked. Please enable it in system settings.';
        permanentlyDenied = true;
      } else if (e.toString().contains('PERMISSION_DENIED')) {
        message = 'Location permission denied.';
      } else if (e.toString().contains('Location services are disabled')) {
        message = 'Please enable location services on your device.';
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: message,
        isPermissionPermanentlyDenied: permanentlyDenied,
      );
    }
  }

  Future<void> openSettings() async {
    await Geolocator.openAppSettings();
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
