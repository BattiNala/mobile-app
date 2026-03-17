import 'package:batti_nala/core/services/snackbar_services.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationPicker extends StatefulWidget {
  final Function(String location, double lat, double lng) onLocationSelected;

  const LocationPicker({super.key, required this.onLocationSelected});

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  bool _isLoading = false;
  String? _locationError;

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _locationError = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are disabled';
          _isLoading = false;
        });
        return;
      }

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Location permissions are denied';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Location permissions are permanently denied';
          _isLoading = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get location name (you might want to use a geocoding service here)
      // For now, we'll use coordinates as string
      String locationName = await _getLocationName(position);

      widget.onLocationSelected(
        locationName,
        position.latitude,
        position.longitude,
      );

      setState(() {
        _isLoading = false;
      });

      // Show success message
      if (mounted) {
        SnackbarService.showSuccess(
          context,
          "Location selected: $locationName",
        );
      }
    } catch (e) {
      setState(() {
        _locationError = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  Future<String> _getLocationName(Position position) async {
    // TODO: Implement reverse geocoding
    // You can use a service like Google Maps Geocoding or OpenStreetMap Nominatim
    // For now, return coordinates as string
    return '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _getCurrentLocation,
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
          label: Text(
            _isLoading ? 'Getting location...' : 'Use My Current Location',
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        if (_locationError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _locationError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            // TODO: Open map picker for manual location selection
            SnackbarService.showError(
              context,
              "Map picker not implemented yet",
            );
          },
          icon: const Icon(Icons.map),
          label: const Text('Pick from Map'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }
}
