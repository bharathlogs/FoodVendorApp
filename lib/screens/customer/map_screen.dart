import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/vendor_profile.dart';
import '../../services/database_service.dart';
import '../../services/customer_location_service.dart';
import '../../utils/cuisine_categories.dart';
import '../../widgets/customer/vendor_bottom_sheet.dart';
import 'vendor_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final DatabaseService _databaseService = DatabaseService();
  final CustomerLocationService _locationService = CustomerLocationService();

  LatLng? _customerLocation;
  bool _isLoadingLocation = true;
  String? _locationError;

  // Filter state
  final Set<String> _selectedCuisines = {};

  // Default center (Bangalore, India)
  static const LatLng _defaultCenter = LatLng(12.9716, 77.5946);

  @override
  void initState() {
    super.initState();
    _initCustomerLocation();
  }

  Future<void> _initCustomerLocation() async {
    if (!mounted) return;
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final position = await _locationService.getCurrentLocation(context);
      if (!mounted) return;
      if (position != null) {
        setState(() {
          _customerLocation = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });

        // Center map on customer location
        _mapController.move(_customerLocation!, 15.0);
      } else {
        setState(() {
          _isLoadingLocation = false;
          _locationError = 'Could not get your location';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingLocation = false;
        _locationError = 'Location error: $e';
      });
    }
  }

  void _toggleCuisineFilter(String cuisine) {
    setState(() {
      if (_selectedCuisines.contains(cuisine)) {
        _selectedCuisines.remove(cuisine);
      } else {
        _selectedCuisines.add(cuisine);
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCuisines.clear();
    });
  }

  void _centerOnCustomer() {
    if (_customerLocation != null) {
      _mapController.move(_customerLocation!, 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          _buildMap(),

          // Filter chips at top
          _buildFilterChips(),

          // Loading indicator for location
          if (_isLoadingLocation)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Getting your location...'),
                    ],
                  ),
                ),
              ),
            ),

          // Location error
          if (_locationError != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.location_off, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_locationError!)),
                      TextButton(
                        onPressed: _initCustomerLocation,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),

      // Center on me button
      floatingActionButton: FloatingActionButton(
        onPressed: _centerOnCustomer,
        backgroundColor: Colors.white,
        child: const Icon(Icons.my_location, color: Colors.blue),
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _customerLocation ?? _defaultCenter,
        initialZoom: 14.0,
        minZoom: 10.0,
        maxZoom: 18.0,
      ),
      children: [
        // OpenStreetMap tile layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.vendorapp.food_vendor_app',
          maxZoom: 19,
        ),

        // Customer location marker
        if (_customerLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _customerLocation!,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

        // Vendor markers
        _buildVendorMarkers(),
      ],
    );
  }

  Widget _buildVendorMarkers() {
    return StreamBuilder<List<VendorProfile>>(
      stream: _databaseService.getActiveVendorsWithFreshnessCheck(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MarkerLayer(markers: []);
        }

        List<VendorProfile> vendors = snapshot.data!;

        // Apply cuisine filter
        if (_selectedCuisines.isNotEmpty) {
          vendors = vendors.where((vendor) {
            return vendor.cuisineTags.any(
              (tag) => _selectedCuisines.contains(tag),
            );
          }).toList();
        }

        // Filter vendors with valid location
        vendors = vendors.where((v) => v.location != null).toList();

        final markers = vendors.map((vendor) {
          return Marker(
            point: LatLng(
              vendor.location!.latitude,
              vendor.location!.longitude,
            ),
            width: 50,
            height: 50,
            child: GestureDetector(
              onTap: () => _showVendorBottomSheet(vendor),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.storefront,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          );
        }).toList();

        return MarkerLayer(markers: markers);
      },
    );
  }

  Widget _buildFilterChips() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 0,
      right: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                // Clear all button (only show when filters active)
                if (_selectedCuisines.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: const Text('Clear All'),
                      avatar: const Icon(Icons.clear, size: 18),
                      onPressed: _clearFilters,
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),

                // Cuisine filter chips
                ...cuisineCategories.map((cuisine) {
                  final isSelected = _selectedCuisines.contains(cuisine);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cuisine),
                      selected: isSelected,
                      onSelected: (_) => _toggleCuisineFilter(cuisine),
                      selectedColor: Colors.orange.shade200,
                      checkmarkColor: Colors.orange.shade800,
                      backgroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: Colors.black26,
                    ),
                  );
                }),
              ],
            ),
          ),

          // Active filter count
          if (_selectedCuisines.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selectedCuisines.length} filter${_selectedCuisines.length > 1 ? 's' : ''} active',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showVendorBottomSheet(VendorProfile vendor) {
    double? distance;
    if (_customerLocation != null && vendor.location != null) {
      distance = _locationService.calculateDistance(
        _customerLocation!.latitude,
        _customerLocation!.longitude,
        vendor.location!.latitude,
        vendor.location!.longitude,
      );
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => VendorBottomSheet(
        vendor: vendor,
        distanceKm: distance,
        onViewMenu: () {
          Navigator.pop(context); // Close bottom sheet
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VendorDetailScreen(
                vendor: vendor,
                distanceKm: distance,
              ),
            ),
          );
        },
      ),
    );
  }
}
