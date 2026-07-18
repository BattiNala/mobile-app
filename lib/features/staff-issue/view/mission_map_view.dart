import 'dart:async';
import 'dart:ui';

import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/core/services/location_service.dart';
import 'package:batti_nala/core/services/snackbar_services.dart';
import 'package:batti_nala/features/shared/issue/models/issue_model.dart';
import 'package:batti_nala/features/shared/widgets/action_button.dart';
import 'package:batti_nala/features/staff-issue/model/route_model.dart';
import 'package:batti_nala/features/staff-issue/repository/route_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MissionMapView extends ConsumerStatefulWidget {
  final IssueModel issue;
  const MissionMapView({super.key, required this.issue});

  @override
  ConsumerState<MissionMapView> createState() => _MissionMapViewState();
}

class _MissionMapViewState extends ConsumerState<MissionMapView> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSubscription;
  LatLng? _currentLatLng;
  RouteResponseModel? _route;
  bool _isLoading = true;
  bool _isNavigating = false;
  bool _isAutoFollow = true;
  String? _error;
  String _hintText = 'Destination set';

  @override
  void initState() {
    super.initState();
    _initInitialState();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initInitialState() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final coords = await locationService.getCurrentCoordinates(
        timeLimit: const Duration(seconds: 10),
      );
      _currentLatLng = LatLng(coords.latitude, coords.longitude);
      await _fetchRoute();
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('[MISSION_MAP] Error getting location: $e');
      if (mounted) {
        String errorMsg = 'Could not access location: ${e.toString()}';

        if (e.toString().contains('PERMISSION_DENIED_FOREVER')) {
          errorMsg =
              'Location access is blocked. Please enable it in system settings.';
          if (mounted) {
            _showPermissionDialog();
          }
        } else if (e.toString().contains('PERMISSION_DENIED')) {
          errorMsg = 'Location permission was denied.';
        } else if (e.toString().contains('Location services are disabled')) {
          errorMsg = 'Please enable GPS/Location services on your device.';
        }

        setState(() => _error = errorMsg);
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.red),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Location Access Required',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Text(
          'To use live navigation for this mission, location permissions are required. '
          'Please enable location access in your app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ActionButton(
            label: 'Open Settings',
            onPressed: () {
              Geolocator.openAppSettings();
              Navigator.pop(context);
            },
            backgroundColor: AppColors.adminRed,
            textColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Future<void> _onStartNavigation() async {
    // Check if location service is enabled
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) {
      if (!mounted) return;
      SnackbarService.showError(
        context,
        'GPS is disabled. Please enable location services.',
      );
      return;
    }

    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (!mounted) return;
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (!mounted) return;
    }

    if (permission == LocationPermission.denied) {
      if (!mounted) return;
      SnackbarService.showError(context, 'Location permission denied.');
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      SnackbarService.showError(
        context,
        'Location access permanently denied. Enable in settings.',
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isNavigating = true);

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(_onLocationUpdate);

    // Auto-center on start
    if (_currentLatLng != null) {
      _mapController.move(_currentLatLng!, 17);
    }
  }

  void _onStopNavigation() {
    _positionSubscription?.cancel();
    setState(() {
      _isNavigating = false;
      _isAutoFollow = false;
      _hintText = 'Navigation paused';
    });
  }

  Future<void> _fetchRoute() async {
    if (_currentLatLng == null) return;

    try {
      final routeRepo = ref.read(routeRepositoryProvider);
      final destination = LatLng(widget.issue.latitude, widget.issue.longitude);

      final routeRes = await routeRepo.getShortestRoute(
        RouteRequest(start: _currentLatLng!, destination: destination),
      );

      if (mounted) {
        setState(() {
          _route = routeRes;
          _updateNavigationHints();
        });
      }
    } catch (e) {
      debugPrint('Routing error: $e');
    }
  }

  void _onLocationUpdate(Position pos) {
    if (!_isNavigating) return;
    final newLatLng = LatLng(pos.latitude, pos.longitude);

    if (_route != null) {
      // Find the closest point on the route to the user
      double minDistance = double.maxFinite;
      for (var point in _route!.path) {
        final dist = const Distance().as(LengthUnit.Meter, newLatLng, point);
        if (dist < minDistance) minDistance = dist;
      }

      // If the user is > 50m away from ANY point on the road, reroute
      if (minDistance > 50) {
        _currentLatLng = newLatLng;
        _fetchRoute();
        return;
      }
    }

    setState(() {
      _currentLatLng = newLatLng;
      _updateNavigationHints();
    });

    if (_isAutoFollow) {
      // ADD ROTATION based on heading (makes it feel like Google Maps)
      // heading is 0-360, null if standing still
      double? heading = pos.heading;
      _mapController.moveAndRotate(
        newLatLng,
        _mapController.camera.zoom,
        heading,
      );
    }
  }

  void _updateNavigationHints() {
    if (_route == null || _currentLatLng == null) return;

    final target = LatLng(widget.issue.latitude, widget.issue.longitude);

    // Use straight line only for arrival detection (more reliable for "you're here")
    final distToTarget = const Distance().as(
      LengthUnit.Meter,
      _currentLatLng!,
      target,
    );

    if (distToTarget < 20) {
      _hintText = "You've arrived at the site!";
    } else {
      // Use the polyline distance for accurate road hint
      double remainingKm = _calculateRemainingDistance();
      _hintText = 'Destination is ${remainingKm.toStringAsFixed(1)} km away';
    }
  }

  double _calculateRemainingDistance() {
    if (_route == null || _currentLatLng == null || _route!.path.isEmpty) {
      return 0.0;
    }

    final path = _route!.path;
    const distanceCalculator = Distance();

    // 1. Find the closest point on the route to the user's current location
    int closestIndex = 0;
    double minDist = double.maxFinite;

    for (int i = 0; i < path.length; i++) {
      final dist = distanceCalculator.as(
        LengthUnit.Meter,
        _currentLatLng!,
        path[i],
      );
      if (dist < minDist) {
        minDist = dist;
        closestIndex = i;
      }
    }

    // 2. Calculate distance from user to that closest path point
    double remainingMeters = minDist;

    // 3. Add up the distance from the closest point to the end of the route
    for (int i = closestIndex; i < path.length - 1; i++) {
      remainingMeters += distanceCalculator.as(
        LengthUnit.Meter,
        path[i],
        path[i + 1],
      );
    }

    // 4. Add the final off-road distance to the exact issue coordinates
    final target = LatLng(widget.issue.latitude, widget.issue.longitude);
    remainingMeters += distanceCalculator.as(
      LengthUnit.Meter,
      path.last,
      target,
    );

    // Convert meters to kilometers
    return remainingMeters / 1000.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLatLng ??
                  LatLng(widget.issue.latitude, widget.issue.longitude),
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.battinala.app',
              ),
              if (_route != null)
                PolylineLayer(
                  polylines: [
                    // Shadow stroke for depth
                    Polyline(
                      points: _route!.path,
                      color: AppColors.primaryBlue950.withValues(alpha: 0.4),
                      strokeWidth: 11,
                    ),
                    // Main route
                    Polyline(
                      points: _route!.path,
                      color: AppColors.primaryBlue800,
                      strokeWidth: 7,
                    ),
                    // Off-road dotted tail
                    Polyline(
                      points: [
                        _route!.path.last,
                        LatLng(
                          widget.issue.latitude,
                          widget.issue.longitude,
                        ),
                      ],
                      color: AppColors.adminRed.withValues(alpha: 0.7),
                      strokeWidth: 4,
                      isDotted: true,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Destination marker
                  Marker(
                    point: LatLng(
                      widget.issue.latitude,
                      widget.issue.longitude,
                    ),
                    width: 56,
                    height: 56,
                    child: _DestinationMarker(
                      issueType: widget.issue.issueType,
                    ),
                  ),
                  // Current location marker
                  if (_currentLatLng != null)
                    Marker(
                      point: _currentLatLng!,
                      width: 52,
                      height: 52,
                      child: const _CurrentLocationMarker(),
                    ),
                ],
              ),
            ],
          ),

          // ── Top bar ──────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(context),
          ),

          // ── Instruction panel (navigating only) ──────
          if (_isNavigating)
            Positioned(
              top: 110,
              left: 16,
              right: 16,
              child: _buildInstructionPanel(),
            ),

          // ── Bottom control bar ────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildControlBar(),
          ),

          // ── Loading & error overlays ──────────────────
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          if (_error != null) _buildErrorOverlay(),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primaryBlue900.withValues(alpha: 0.88),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
              child: Row(
                children: [
                  // Back button
                  ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Live Navigation',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          widget.issue.issueType.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Reroute button
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _fetchRoute,
                          tooltip: 'Reroute',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionPanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue900.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.navigation_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _hintText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _isAutoFollow = !_isAutoFollow),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isAutoFollow
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    _isAutoFollow
                        ? Icons.near_me_rounded
                        : Icons.near_me_disabled_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlBar() {
    final double displayDistance = _isNavigating && _currentLatLng != null
        ? _calculateRemainingDistance()
        : (_route?.distanceKm ?? 0.0);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  // Distance info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isNavigating ? 'Remaining' : 'Total Distance',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            displayDistance.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMain,
                              letterSpacing: -1,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'km',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Start/Stop button
                  GestureDetector(
                    onTap: _isNavigating
                        ? _onStopNavigation
                        : _onStartNavigation,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: _isNavigating
                            ? AppColors.adminRed
                            : AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (_isNavigating
                                    ? AppColors.adminRed
                                    : AppColors.primaryBlue)
                                .withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isNavigating
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isNavigating ? 'Stop' : 'Start',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
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
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: Colors.black.withValues(alpha: 0.6),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.adminRed.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_off_rounded,
                            color: AppColors.adminRed,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Location Unavailable',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ActionButton(
                          label: 'Retry',
                          onPressed: _initInitialState,
                          backgroundColor: AppColors.primaryBlue,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Map markers ─────────────────────────────────────────────────────────────

class _DestinationMarker extends StatelessWidget {
  final String issueType;
  const _DestinationMarker({required this.issueType});

  @override
  Widget build(BuildContext context) {
    final typeLower = issueType.toLowerCase();
    final isElectricity = typeLower.contains('electricity');
    final isSewage =
        typeLower.contains('sewage') || typeLower.contains('drain');
    final color = isElectricity
        ? AppColors.primaryBlue
        : isSewage
            ? const Color(0xFF059669)
            : AppColors.adminRed;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.18),
          ),
        ),
        // Icon container
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ],
    );
  }
}

class _CurrentLocationMarker extends StatelessWidget {
  const _CurrentLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse ring
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryBlue.withValues(alpha: 0.15),
          ),
        ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryBlue.withValues(alpha: 0.25),
          ),
        ),
        // Core dot
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
