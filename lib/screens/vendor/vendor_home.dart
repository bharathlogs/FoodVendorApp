import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/location_manager.dart';
import '../../services/database_service.dart';
import '../../models/vendor_profile.dart';

class VendorHome extends StatefulWidget {
  const VendorHome({super.key});

  @override
  State<VendorHome> createState() => _VendorHomeState();
}

class _VendorHomeState extends State<VendorHome> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  final LocationManager _locationManager = LocationManager();

  VendorProfile? _vendorProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeVendor();
  }

  Future<void> _initializeVendor() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    // Initialize location manager with vendor ID
    await _locationManager.initialize(uid);

    // Load vendor profile
    final profile = await _databaseService.getVendorProfile(uid);

    if (mounted) {
      setState(() {
        _vendorProfile = profile;
        _isLoading = false;
      });
    }

    // Add listener for location updates
    _locationManager.addListener(_onLocationManagerUpdate);
  }

  void _onLocationManagerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleStatus() async {
    if (_locationManager.state == LocationManagerState.starting ||
        _locationManager.state == LocationManagerState.stopping) {
      // Already in transition, ignore
      return;
    }

    if (_locationManager.isActive) {
      await _locationManager.stopBroadcasting();
    } else {
      await _locationManager.startBroadcasting(context);
    }
  }

  Future<void> _handleLogout() async {
    final navigator = Navigator.of(context);
    if (_locationManager.isActive) {
      await _locationManager.stopBroadcasting();
    }
    await _authService.signOut();
    if (mounted) {
      navigator.pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _locationManager.removeListener(_onLocationManagerUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_vendorProfile?.businessName ?? 'Vendor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Status Card
            _buildStatusCard(),

            const SizedBox(height: 24),

            // Toggle Button
            _buildToggleButton(),

            const SizedBox(height: 24),

            // Location Info
            if (_locationManager.isActive) _buildLocationInfo(),

            // Error Message
            if (_locationManager.errorMessage != null) _buildErrorMessage(),

            const Spacer(),

            // Placeholder for Phase 3 features
            _buildPhase3Placeholder(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final isActive = _locationManager.isActive;
    final isTransitioning =
        _locationManager.state == LocationManagerState.starting ||
            _locationManager.state == LocationManagerState.stopping;

    return Card(
      color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isTransitioning
                    ? Colors.orange
                    : (isActive ? Colors.green : Colors.grey),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTransitioning
                        ? 'Updating...'
                        : (isActive ? 'You are OPEN' : 'You are CLOSED'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isActive
                        ? 'Customers can see your location'
                        : 'Customers cannot find you',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton() {
    final isActive = _locationManager.isActive;
    final isTransitioning =
        _locationManager.state == LocationManagerState.starting ||
            _locationManager.state == LocationManagerState.stopping;

    return SizedBox(
      width: double.infinity,
      height: 80,
      child: ElevatedButton(
        onPressed: isTransitioning ? null : _toggleStatus,
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? Colors.red.shade400 : Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isTransitioning
            ? const CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isActive ? Icons.stop : Icons.play_arrow,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isActive ? 'GO OFFLINE' : 'GO ONLINE',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    final lat = _locationManager.lastLatitude;
    final lng = _locationManager.lastLongitude;
    final time = _locationManager.lastUpdateTime;

    if (lat == null || lng == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Getting your location...'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Your Location',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Latitude: ${lat.toStringAsFixed(6)}',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            Text(
              'Longitude: ${lng.toStringAsFixed(6)}',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            if (time != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last updated: ${_formatDateTime(time)}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _locationManager.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhase3Placeholder() {
    return Card(
      color: Colors.blue.shade50,
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.restaurant_menu, size: 32, color: Colors.blue),
            SizedBox(height: 8),
            Text(
              'Menu & Orders',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Coming in Phase 3',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }
}
