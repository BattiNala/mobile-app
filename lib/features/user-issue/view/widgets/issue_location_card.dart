import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/core/services/geocoding_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class IssueLocationCard extends ConsumerWidget {
  final String location;
  final double? latitude;
  final double? longitude;
  final VoidCallback? onTap;

  const IssueLocationCard({
    super.key,
    required this.location,
    this.latitude,
    this.longitude,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasValidCoords =
        latitude != null &&
        longitude != null &&
        latitude != 0.0 &&
        longitude != 0.0;

    final point = hasValidCoords
        ? LatLng(latitude!, longitude!)
        : const LatLng(27.7172, 85.3240);

    // If we have valid coordinates, fetch the address
    // Don't use the string location at all
    final addressAsync = hasValidCoords
        ? ref.watch(addressProvider((lat: latitude!, lng: longitude!)))
        : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map preview
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(23),
              ),
              child: SizedBox(
                height: 160,
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: point,
                        initialZoom: 15,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.battinala.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: point,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: AppColors.adminRed,
                                size: 36,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Positioned(
                    //   right: 12,
                    //   bottom: 12,
                    //   child: Container(
                    //     padding: const EdgeInsets.symmetric(
                    //       horizontal: 12,
                    //       vertical: 6,
                    //     ),
                    //     decoration: BoxDecoration(
                    //       color: AppColors.primaryBlue,
                    //       borderRadius: BorderRadius.circular(20),
                    //       boxShadow: [
                    //         BoxShadow(
                    //           color: Colors.black.withValues(alpha: 0.25),
                    //           blurRadius: 6,
                    //           offset: const Offset(0, 2),
                    //         ),
                    //       ],
                    //     ),
                    //     child: const Row(
                    //       children: [
                    //         Icon(
                    //           Icons.directions_rounded,
                    //           color: Colors.white,
                    //           size: 14,
                    //         ),
                    //         SizedBox(width: 4),
                    //         Text(
                    //           'OPEN IN MAP',
                    //           style: TextStyle(
                    //             color: Colors.white,
                    //             fontSize: 10,
                    //             fontWeight: FontWeight.bold,
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
            // Address row - using geocoded address from coordinates
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.adminRed,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAddressText(addressAsync, latitude, longitude),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primaryBlue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressText(
    AsyncValue<String>? addressAsync,
    double? latitude,
    double? longitude,
  ) {
    // If we're fetching address from coordinates
    if (addressAsync != null) {
      return addressAsync.when(
        data: (address) => Text(
          address,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
        ),
        loading: () => Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              'Getting location...',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        error: (error, _) => Text(
          _formatCoordinates(latitude, longitude),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
        ),
      );
    }

    return const Text(
      'Location not available',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textMain,
      ),
    );
  }

  String _formatCoordinates(double? lat, double? lng) {
    if (lat == null || lng == null) return 'Unknown location';
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(4)}°$latDir, ${lng.abs().toStringAsFixed(4)}°$lngDir';
  }
}
