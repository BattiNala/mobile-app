import 'dart:ui' as ui;

import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/core/services/geocoding_service.dart';
import 'package:batti_nala/core/services/location_service.dart';
import 'package:batti_nala/features/shared/widgets/action_button.dart';
import 'package:batti_nala/features/user-issue/controllers/location_notifier.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

// ─── Location Picker (buttons) ───────────────────────────────────────────────

class LocationPicker extends ConsumerWidget {
  const LocationPicker({super.key});

  Future<void> _openMapPicker(BuildContext context, WidgetRef ref) async {
    final locationState = ref.read(locationNotifierProvider);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPicker(
          initialLat: locationState.latitude == 0 ? null : locationState.latitude,
          initialLng: locationState.longitude == 0 ? null : locationState.longitude,
          onLocationSelected: (lat, lng, address) {
            ref.read(locationNotifierProvider.notifier).setMapLocation(
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
                label: locationState.isLoading ? 'Getting…' : 'Current',
                iconPath: Icons.my_location_rounded,
                backgroundColor: AppColors.primaryBlue,
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
                iconPath: Icons.map_rounded,
                backgroundColor: AppColors.adminRed,
                textColor: Colors.white,
                onPressed: locationState.isLoading
                    ? null
                    : () => _openMapPicker(context, ref),
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

// ─── Map Picker ───────────────────────────────────────────────────────────────

class MapPicker extends ConsumerStatefulWidget {
  final Function(double lat, double lng, String address) onLocationSelected;
  final double? initialLat;
  final double? initialLng;

  const MapPicker({
    super.key,
    required this.onLocationSelected,
    this.initialLat,
    this.initialLng,
  });

  @override
  ConsumerState<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends ConsumerState<MapPicker> {
  late LatLng _selectedLocation;
  final MapController _mapController = MapController();
  bool _isLoading = true;
  String? _errorMessage;
  String _address = '';
  late final LocationService _locationService;

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  final FocusNode _searchFocusNode = FocusNode();

  static const LatLng _defaultLocation = LatLng(27.7172, 85.3240);
  double _currentZoom = 15;

  @override
  void initState() {
    super.initState();
    _locationService = ref.read(locationServiceProvider);
    _selectedLocation = LatLng(
      widget.initialLat ?? _defaultLocation.latitude,
      widget.initialLng ?? _defaultLocation.longitude,
    );
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _zoomIn() {
    setState(() {
      _currentZoom = (_currentZoom + 1).clamp(3, 19);
      _mapController.move(_selectedLocation, _currentZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom = (_currentZoom - 1).clamp(3, 19);
      _mapController.move(_selectedLocation, _currentZoom);
    });
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
              child: Text('Location Access Denied', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: const Text(
          'Location permissions are permanently denied. '
          'Enable them in system settings to use auto-location.',
        ),
        actions: [
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

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final coords = await _locationService.getCurrentCoordinates(
        timeLimit: const Duration(seconds: 10),
      );
      if (!mounted) return;
      setState(() {
        _selectedLocation = LatLng(coords.latitude, coords.longitude);
        _mapController.move(_selectedLocation, 15);
        _currentZoom = 15;
        _isLoading = false;
      });
      await _updateAddressFromCoordinates(coords.latitude, coords.longitude);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (e.toString().contains('PERMISSION_DENIED_FOREVER')) {
        _showPermissionDialog();
      } else {
        setState(() => _errorMessage =
            e.toString().contains('Location services are disabled')
                ? 'Please enable GPS / Location services.'
                : 'Could not get location. Try manual selection.');
      }
      await _updateAddressFromCoordinates(
        _selectedLocation.latitude,
        _selectedLocation.longitude,
      );
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() {
      _isSearching = true;
      _searchResults = [];
    });
    try {
      final response = await Dio().get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': '$query, Nepal',
          'format': 'json',
          'limit': 8,
          'addressdetails': 1,
        },
        options: Options(headers: {'User-Agent': 'BattiNala/1.0'}),
      );
      if (response.statusCode == 200 && response.data != null) {
        final List results = response.data;
        setState(() {
          _searchResults = results
              .map((item) => {
                    'display_name': item['display_name'],
                    'lat': double.parse(item['lat']),
                    'lon': double.parse(item['lon']),
                  })
              .toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final lat = result['lat'] as double;
    final lng = result['lon'] as double;
    setState(() {
      _selectedLocation = LatLng(lat, lng);
      _mapController.move(_selectedLocation, 16);
      _currentZoom = 16;
      _address = result['display_name'] as String;
      _searchController.clear();
      _searchResults = [];
      _searchFocusNode.unfocus();
    });
  }

  Future<void> _updateAddressFromCoordinates(double lat, double lng) async {
    final address = await getAddressFromCoordinates(lat, lng);
    if (mounted) setState(() => _address = address);
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() => _selectedLocation = point);
    _updateAddressFromCoordinates(point.latitude, point.longitude);
  }

  void _onMapPositionChanged(MapPosition position, bool hasGesture) {
    if (hasGesture && position.center != null) {
      setState(() {
        _selectedLocation = position.center!;
        _currentZoom = position.zoom ?? _currentZoom;
      });
      _updateAddressFromCoordinates(
        _selectedLocation.latitude,
        _selectedLocation.longitude,
      );
    }
  }

  void _confirmLocation() {
    widget.onLocationSelected(
      _selectedLocation.latitude,
      _selectedLocation.longitude,
      _address,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── Map ───────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: _currentZoom,
              onTap: _onMapTap,
              onPositionChanged: _onMapPositionChanged,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.batti_nala',
                tileProvider: NetworkTileProvider(),
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 48,
                    height: 56,
                    point: _selectedLocation,
                    child: const _PinMarker(),
                  ),
                ],
              ),
            ],
          ),

          // ── Glass top bar ─────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  color: isDark
                      ? AppColors.darkBackground.withValues(alpha: 0.75)
                      : Colors.white.withValues(alpha: 0.82),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.of(context).padding.top + 8,
                    16,
                    12,
                  ),
                  child: Column(
                    children: [
                      // Back + title
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : AppColors.primaryBlue.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : AppColors.border,
                                ),
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 16,
                                color: isDark
                                    ? AppColors.darkTextMain
                                    : AppColors.primaryBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pick Location',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? AppColors.darkTextMain
                                        : AppColors.textMain,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  'Tap map or search to set location',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // My location button
                          GestureDetector(
                            onTap: _getCurrentLocation,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primaryBlue.withValues(alpha: 0.2),
                                ),
                              ),
                              child: const Icon(
                                Icons.my_location_rounded,
                                size: 18,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Search bar
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface2.withValues(alpha: 0.7)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: _searchLocation,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkTextMain
                                : AppColors.textMain,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search for a location…',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textMuted,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textMuted,
                              size: 20,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() => _searchResults = []);
                                    },
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.textMuted,
                                    ),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 12,
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

          // ── Search results ────────────────────────────────────────────────
          if (_searchResults.isNotEmpty || _isSearching)
            Positioned(
              top: MediaQuery.of(context).padding.top + 130,
              left: 16,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 260),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface.withValues(alpha: 0.95)
                          : Colors.white.withValues(alpha: 0.97),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : AppColors.border,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isSearching
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Searching…',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: _searchResults.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.border,
                            ),
                            itemBuilder: (context, index) {
                              final result = _searchResults[index];
                              return InkWell(
                                onTap: () => _selectSearchResult(result),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.adminRed
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.location_on_rounded,
                                          color: AppColors.adminRed,
                                          size: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          result['display_name'],
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark
                                                ? AppColors.darkTextMain
                                                : AppColors.textMain,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
            ),

          // ── Zoom controls ─────────────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 160,
            child: Column(
              children: [
                _GlassButton(
                  onTap: _zoomIn,
                  isDark: isDark,
                  child: const Icon(
                    Icons.add_rounded,
                    size: 20,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 8),
                _GlassButton(
                  onTap: _zoomOut,
                  isDark: isDark,
                  child: const Icon(
                    Icons.remove_rounded,
                    size: 20,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom card ───────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface.withValues(alpha: 0.92)
                        : Colors.white.withValues(alpha: 0.93),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : AppColors.border,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: AppColors.primaryBlue,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _address.isNotEmpty
                                      ? _address
                                      : 'Tap on the map to set location',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: isDark
                                        ? AppColors.darkTextMain
                                        : AppColors.textMain,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ActionButton(
                            width: double.infinity,
                            label: 'Confirm Location',
                            iconPath: Icons.check_rounded,
                            backgroundColor: AppColors.primaryBlue,
                            textColor: Colors.white,
                            onPressed: _confirmLocation,
                            borderRadius: 14,
                            verticalPadding: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Error banner ──────────────────────────────────────────────────
          if (_errorMessage != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 120,
              left: 16,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.adminRed.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _errorMessage = null),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Loading overlay ───────────────────────────────────────────────
          if (_isLoading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 24,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface.withValues(alpha: 0.92)
                                : Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : AppColors.border,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                strokeWidth: 3,
                                color: AppColors.primaryBlue,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Getting your location…',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkTextMain
                                      : AppColors.textMain,
                                ),
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
        ],
      ),
    );
  }
}

// ─── Pin marker ───────────────────────────────────────────────────────────────

class _PinMarker extends StatelessWidget {
  const _PinMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.adminRed,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.adminRed.withValues(alpha: 0.45),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        CustomPaint(
          size: const Size(12, 8),
          painter: _PinTailPainter(),
        ),
      ],
    );
  }
}

class _PinTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.adminRed
      ..style = PaintingStyle.fill;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTailPainter old) => false;
}

// ─── Glass button ─────────────────────────────────────────────────────────────

class _GlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final bool isDark;

  const _GlassButton({
    required this.onTap,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurface.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppColors.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
