import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/core/widgets/action_button.dart';
import 'package:batti_nala/core/services/location_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';

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
  String _address = '';
  late final LocationService _locationService;

  // Search related
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  final FocusNode _searchFocusNode = FocusNode();

  // Default center (Kathmandu)
  static const LatLng _defaultLocation = LatLng(27.7172, 85.3240);

  // Zoom level
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

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      final coords = await _locationService.getCurrentCoordinates(
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _selectedLocation = LatLng(coords.latitude, coords.longitude);
        _mapController.move(_selectedLocation, 15);
        _currentZoom = 15;
        _updateAddressFromCoordinates(coords.latitude, coords.longitude);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[MAP] Error getting location: $e');
      setState(() {
        _isLoading = false;
        _updateAddressFromCoordinates(
          _selectedLocation.latitude,
          _selectedLocation.longitude,
        );
      });
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final response = await Dio().get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': '$query, Kathmandu, Nepal',
          'format': 'json',
          'limit': 10,
          'addressdetails': 1,
        },
        options: Options(headers: {'User-Agent': 'BattiNala/1.0'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List results = response.data;
        setState(() {
          _searchResults = results
              .map(
                (item) => {
                  'display_name': item['display_name'],
                  'lat': double.parse(item['lat']),
                  'lon': double.parse(item['lon']),
                },
              )
              .toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('[SEARCH] Error: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final lat = result['lat'] as double;
    final lng = result['lon'] as double;
    final name = result['display_name'] as String;

    setState(() {
      _selectedLocation = LatLng(lat, lng);
      _mapController.move(_selectedLocation, 16);
      _currentZoom = 16;
      _address = name;
      _searchController.clear();
      _searchResults = [];
      _searchFocusNode.unfocus();
    });
  }

  void _updateAddressFromCoordinates(double lat, double lng) {
    setState(() {
      _address = _locationService.buildMapAddress(lat, lng);
    });
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
      _updateAddressFromCoordinates(point.latitude, point.longitude);
    });
  }

  void _onMapPositionChanged(MapPosition position, bool hasGesture) {
    if (hasGesture && position.center != null) {
      setState(() {
        _selectedLocation = position.center!;
        _currentZoom = position.zoom ?? _currentZoom;
        _updateAddressFromCoordinates(
          _selectedLocation.latitude,
          _selectedLocation.longitude,
        );
      });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Location on Map',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  const BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _searchLocation,
                decoration: InputDecoration(
                  hintText: 'Search for a location...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchResults = []);
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: _currentZoom,
              onTap: _onMapTap,
              onPositionChanged: _onMapPositionChanged,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all, // Enables pinch, double tap, pan
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.batti_nala',
                tileProvider: NetworkTileProvider(),
              ),
              // Marker at selected location
              MarkerLayer(
                markers: [
                  Marker(
                    width: 50,
                    height: 50,
                    point: _selectedLocation,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              const BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 24,
                          ),
                        ),
                        Container(
                          width: 0,
                          height: 0,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.transparent),
                              top: BorderSide(color: Colors.red, width: 8),
                              left: BorderSide(
                                color: Colors.transparent,
                                width: 6,
                              ),
                              right: BorderSide(
                                color: Colors.transparent,
                                width: 6,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Zoom Controls (Floating buttons)
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height / 2 - 60,
            child: Column(
              children: [
                FloatingActionButton.small(
                  onPressed: _zoomIn,
                  heroTag: 'map_picker_zoom_in',
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  onPressed: _zoomOut,
                  heroTag: 'map_picker_zoom_out',
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

          // Search Results Dropdown
          if (_searchResults.isNotEmpty)
            Positioned(
              top: kToolbarHeight + 70,
              left: 16,
              right: 16,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    const BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                      ),
                      title: Text(
                        result['display_name'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                      onTap: () => _selectSearchResult(result),
                    );
                  },
                ),
              ),
            ),

          // Loading indicator for search
          if (_isSearching)
            const Positioned(
              top: kToolbarHeight + 70,
              left: 16,
              right: 16,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Searching...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Center crosshair
          IgnorePointer(
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: const Icon(Icons.add, color: Colors.red, size: 20),
              ),
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),

          // Bottom card with location info
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  const BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.location_on, size: 18, color: Colors.blue),
                      SizedBox(width: 6),
                      Text(
                        'Selected Location',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _address.isNotEmpty
                        ? _address
                        : 'Tap on map or search for a location',
                    style: const TextStyle(fontSize: 13),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.my_location),
                        tooltip: 'My Location',
                        color: Colors.blue,
                      ),
                      const Spacer(),
                      ActionButton(
                        label: 'Confirm Location',
                        onPressed: _confirmLocation,
                        backgroundColor: AppColors.primaryBlue,
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
