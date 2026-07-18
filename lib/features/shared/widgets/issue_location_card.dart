import 'dart:ui';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurface.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.7),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Map preview
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(19),
                  ),
                  child: SizedBox(
                    height: 175,
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
                                  width: 48,
                                  height: 48,
                                  child: _PinMarker(),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Transparent tap overlay — FlutterMap absorbs events
                        // so this intercepts the tap before the map does
                        if (onTap != null)
                          Positioned.fill(
                            child: GestureDetector(
                              onTap: onTap,
                              behavior: HitTestBehavior.translucent,
                              child: const SizedBox.expand(),
                            ),
                          ),

                        // Bottom gradient fade
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 48,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  (isDark
                                          ? AppColors.darkSurface
                                          : Colors.white)
                                      .withValues(alpha: 0.5),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Navigate button
                        if (showNavigateButton)
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryBlue
                                            .withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.navigation_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'NAVIGATE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Address row
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.adminRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.adminRed,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAddressText(
                          addressAsync,
                          location,
                          latitude,
                          longitude,
                          isDark,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.primaryBlue,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressText(
    AsyncValue<String>? addressAsync,
    String fallback,
    double? latitude,
    double? longitude,
    bool isDark,
  ) {
    final style = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: isDark ? AppColors.darkTextMain : AppColors.textMain,
      height: 1.4,
    );

    if (fallback.isNotEmpty) {
      return Text(fallback, style: style, maxLines: 2,
          overflow: TextOverflow.ellipsis);
    }

    if (addressAsync != null) {
      return addressAsync.when(
        data: (address) =>
            Text(address, style: style, maxLines: 2,
                overflow: TextOverflow.ellipsis),
        loading: () => Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Getting location...',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
        error: (_, __) => Text(
          _formatCoordinates(latitude, longitude),
          style: style,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return Text(
      _formatCoordinates(latitude, longitude),
      style: style,
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

class _PinMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow ring
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.adminRed.withValues(alpha: 0.2),
          ),
        ),
        // Pin
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.adminRed,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.adminRed.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
