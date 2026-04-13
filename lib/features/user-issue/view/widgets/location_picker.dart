import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/core/widgets/action_button.dart';
import 'package:batti_nala/features/user-issue/controllers/location_notifier.dart';
import 'package:batti_nala/features/user-issue/view/widgets/map_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocationPicker extends ConsumerWidget {
  const LocationPicker({super.key});

  Future<void> _openMapPicker(BuildContext context, WidgetRef ref) async {
    final locationState = ref.read(locationNotifierProvider);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPicker(
          initialLat: locationState.latitude == 0
              ? null
              : locationState.latitude,
          initialLng: locationState.longitude == 0
              ? null
              : locationState.longitude,
          onLocationSelected: (lat, lng, address) {
            ref
                .read(locationNotifierProvider.notifier)
                .setMapLocation(
                  address: address,
                  latitude: lat,
                  longitude: lng,
                );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationNotifierProvider);
    final locationNotifier = ref.read(locationNotifierProvider.notifier);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ActionButton(
                label: locationState.isLoading
                    ? 'Getting location...'
                    : 'Current',
                iconPath: Icons.my_location,
                backgroundColor: Colors.blue,
                textColor: Colors.white,
                onPressed: locationState.isLoading
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        locationNotifier.fetchCurrentLocation();
                      },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ActionButton(
                label: 'Pick on Map',
                iconPath: Icons.location_on_outlined,
                onPressed: locationState.isLoading
                    ? null
                    : () => _openMapPicker(context, ref),
                backgroundColor: AppColors.primaryBlue,
                textColor: AppColors.adminRedLight,
              ),
            ),
          ],
        ),
        if (locationState.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              children: [
                Text(
                  locationState.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                if (locationState.isPermissionPermanentlyDenied) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => locationNotifier.openSettings(),
                    icon: const Icon(Icons.settings, size: 18),
                    label: const Text(
                      'Open App Settings',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: AppColors.primaryBlue),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
