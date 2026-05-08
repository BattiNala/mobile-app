import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/core/services/geocoding_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:latlong2/latlong.dart';

/// Reusable location card widget displaying a map preview and address
class IssueLocationCard extends ConsumerWidget {
  final String location;
  final double? latitude;
  final double? longitude;
  final VoidCallback? onTap;
  final bool showNavigateButton;

  const IssueLocationCard({
    super.key,
    required this.location,
    this.latitude,
    this.longitude,
    this.onTap,
    this.showNavigateButton = false,
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
                              child: const FaIcon(
                                FontAwesomeIcons.signsPost,
                                color: AppColors.primaryBlue800,
                                size: 45,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Optional Navigate button
                    if (showNavigateButton)
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.directions_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'NAVIGATE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Address row
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
                    child: _buildAddressText(
                      addressAsync,
                      location,
                      latitude,
                      longitude,
                    ),
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
    String fallback,
    double? latitude,
    double? longitude,
  ) {
    // Priority 1: Use backend location if available (most reliable - from issue creation)
    if (fallback.isNotEmpty) {
      return Text(
        fallback,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Priority 2: Use Nominatim reverse geocoding if coordinates available
    if (addressAsync != null) {
      return addressAsync.when(
        data: (address) => Text(
          address,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        loading: () => Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
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
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    // Priority 3: Fallback to coordinate format if nothing else available
    return Text(
      _formatCoordinates(latitude, longitude),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textMain,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _formatCoordinates(double? lat, double? lng) {
    if (lat == null || lng == null) return 'Unknown location';
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(4)}°$latDir, ${lng.abs().toStringAsFixed(4)}°$lngDir';
  }
}
