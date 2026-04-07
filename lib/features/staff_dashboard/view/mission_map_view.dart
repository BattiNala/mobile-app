import 'dart:async';
import 'package:batti_nala/core/services/snackbar_services.dart';
import 'package:batti_nala/core/widgets/action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/features/staff_dashboard/model/route_model.dart';
import 'package:batti_nala/features/staff_dashboard/repository/route_repository.dart';
import 'package:batti_nala/features/issue_report/models/issue_model.dart';

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
      final pos = await Geolocator.getCurrentPosition();
      _currentLatLng = LatLng(pos.latitude, pos.longitude);
      await _fetchRoute();
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Location permissions or service error: $e');
      }
    }
  }

  Future<void> _onStartNavigation() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) {
      SnackbarService.showError(context, 'GPS is disabled.');
      return;
    }

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
      final distanceToPath = const Distance().as(
        LengthUnit.Meter,
        newLatLng,
        _route!.path.first,
      );
      // Auto reroute if moved > 50m off
      if (distanceToPath > 50) {
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
      _mapController.move(newLatLng, _mapController.camera.zoom);
    }
  }

  void _updateNavigationHints() {
    if (_route == null || _currentLatLng == null) return;

    final target = LatLng(widget.issue.latitude, widget.issue.longitude);
    final distToTarget = const Distance().as(
      LengthUnit.Meter,
      _currentLatLng!,
      target,
    );

    if (distToTarget < 20) {
      _hintText = "You've arrived at the site!";
      return;
    }

    final offRoadDist = const Distance().as(
      LengthUnit.Meter,
      _route!.path.last,
      target,
    );

    if (offRoadDist > 10 && _route!.path.length <= 5) {
      _hintText = 'Almost there! Follow the off-road path';
    } else {
      _hintText = 'Continue toward the mission site';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Navigation'),
        backgroundColor: AppColors.primaryBlue900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchRoute,
            tooltip: 'Manual Reroute',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  _currentLatLng ??
                  LatLng(widget.issue.latitude, widget.issue.longitude),
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.battinala.app',
              ),
              if (_route != null)
                PolylineLayer(
                  polylines: [
                    // Main routed path on roads
                    Polyline(
                      points: _route!.path,
                      color: AppColors.primaryBlue,
                      strokeWidth: 7,
                    ),

                    // "Off-road" connecting line if road ends early
                    Polyline(
                      points: [
                        _route!.path.last,
                        LatLng(widget.issue.latitude, widget.issue.longitude),
                      ],
                      color: AppColors.primaryBlue.withValues(alpha: 0.6),
                      strokeWidth: 4,
                      isDotted: true,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(
                      widget.issue.latitude,
                      widget.issue.longitude,
                    ),
                    width: 60,
                    height: 60,
                    child: const Icon(
                      Icons.stars_rounded,
                      color: AppColors.adminRed,
                      size: 45,
                    ),
                  ),
                  if (_currentLatLng != null)
                    Marker(
                      point: _currentLatLng!,
                      width: 45,
                      height: 45,
                      child: _buildCurrentLocationMarker(),
                    ),
                ],
              ),
            ],
          ),

          // TOP ACTION HUB
          if (_isNavigating)
            Positioned(
              top: 20,
              left: 16,
              right: 16,
              child: _buildInstructionPanel(),
            ),

          // BOTTOM CONTROL BAR
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _buildControlBar(),
          ),

          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (_error != null) _buildErrorOverlay(),
        ],
      ),
    );
  }

  Widget _buildControlBar() {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Mission Distance',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  _route != null
                      ? '${_route!.distanceKm.toStringAsFixed(1)} KM'
                      : '-- KM',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            ActionButton(
              label: _isNavigating ? 'STOP' : 'START',
              backgroundColor: _isNavigating
                  ? AppColors.adminRed
                  : AppColors.primaryBlue,
              width: 140,
              onPressed: _isNavigating ? _onStopNavigation : _onStartNavigation,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Row(
        children: [
          const Icon(Icons.navigation_rounded, color: Colors.white, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _hintText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _isAutoFollow ? Icons.near_me : Icons.near_me_disabled,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => setState(() => _isAutoFollow = !_isAutoFollow),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLocationMarker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryBlue, width: 4),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: const Center(
        child: Icon(
          Icons.person_pin_circle_rounded,
          color: AppColors.primaryBlue,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.white.withValues(alpha: 0.9),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_off_rounded,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                'Could not access current location.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ActionButton(label: 'Retry', onPressed: _initInitialState),
            ],
          ),
        ),
      ),
    );
  }
}
