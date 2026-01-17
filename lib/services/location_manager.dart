import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'permission_service.dart';
import 'location_foreground_service.dart';
import 'database_service.dart';
import 'location_queue_service.dart';

enum LocationManagerState {
  idle,
  starting,
  active,
  stopping,
  error,
}

class LocationManager extends ChangeNotifier {
  static final LocationManager _instance = LocationManager._internal();
  factory LocationManager() => _instance;
  LocationManager._internal();

  final PermissionService _permissionService = PermissionService();
  final LocationForegroundService _foregroundService = LocationForegroundService();
  final DatabaseService _databaseService = DatabaseService();
  final LocationQueueService _queueService = LocationQueueService();
  final Connectivity _connectivity = Connectivity();

  LocationManagerState _state = LocationManagerState.idle;
  LocationManagerState get state => _state;

  // Timeout detection
  Timer? _timeoutCheckTimer;
  static const Duration _timeoutDuration = Duration(minutes: 10);
  static const Duration _checkInterval = Duration(minutes: 2);
  static const Duration _warningThreshold = Duration(minutes: 7);

  String? _vendorId;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  DateTime? _lastUpdateTime;
  DateTime? get lastUpdateTime => _lastUpdateTime;

  double? _lastLatitude;
  double? _lastLongitude;
  double? get lastLatitude => _lastLatitude;
  double? get lastLongitude => _lastLongitude;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;
  bool _isInitialized = false;

  /// Initialize the location manager for a specific vendor
  Future<void> initialize(String vendorId) async {
    if (_isInitialized && _vendorId == vendorId) return;

    _vendorId = vendorId;
    await _queueService.init();
    await _foregroundService.init();

    // Listen for connectivity changes
    _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final wasOffline = !_isOnline;
        _isOnline = results.isNotEmpty &&
            !results.contains(ConnectivityResult.none);

        // If we just came online, flush the queue
        if (wasOffline && _isOnline && _state == LocationManagerState.active) {
          _flushQueue();
        }
      },
    );

    // Check current connectivity
    final results = await _connectivity.checkConnectivity();
    _isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);

    _isInitialized = true;
  }

  /// Start broadcasting location (called when vendor toggles "Open")
  Future<bool> startBroadcasting(BuildContext context) async {
    if (_vendorId == null) {
      _errorMessage = 'Vendor ID not set. Please log in again.';
      notifyListeners();
      return false;
    }

    _setState(LocationManagerState.starting);

    // Step 1: Request permissions
    final hasPermissions = await _permissionService.requestLocationPermissions(context);
    if (!hasPermissions) {
      _errorMessage = 'Location permissions required to go online.';
      _setState(LocationManagerState.error);
      return false;
    }

    // Step 2: Start foreground service
    final serviceStarted = await _foregroundService.startService(
      onLocationUpdate: _handleLocationUpdate,
      onStopRequested: _handleStopRequested,
      onError: _handleError,
    );

    if (!serviceStarted) {
      _errorMessage = 'Failed to start location service.';
      _setState(LocationManagerState.error);
      return false;
    }

    // Step 3: Get initial location and update Firebase
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      await _handleLocationUpdate(
        position.latitude,
        position.longitude,
        DateTime.now(),
      );
    } catch (e) {
      // Non-fatal - service will get location eventually
      debugPrint('Initial location fetch failed: $e');
    }

    // Step 4: Set vendor as active in Firebase
    try {
      await _databaseService.setVendorActiveStatus(_vendorId!, true);
    } catch (e) {
      debugPrint('Failed to set vendor active status: $e');
      // Non-fatal - continue anyway
    }

    // Step 5: Start timeout monitoring
    _startTimeoutMonitoring();

    _setState(LocationManagerState.active);
    return true;
  }

  /// Stop broadcasting location (called when vendor toggles "Closed")
  Future<void> stopBroadcasting() async {
    _setState(LocationManagerState.stopping);

    // Stop timeout monitoring
    _stopTimeoutMonitoring();

    // Stop foreground service
    await _foregroundService.stopService();

    // Update Firebase
    if (_vendorId != null) {
      try {
        await _databaseService.setVendorActiveStatus(_vendorId!, false);
      } catch (e) {
        debugPrint('Failed to set vendor inactive status: $e');
      }
    }

    _lastLatitude = null;
    _lastLongitude = null;
    _lastUpdateTime = null;

    _setState(LocationManagerState.idle);
  }

  /// Handle location update from foreground service
  Future<void> _handleLocationUpdate(
    double latitude,
    double longitude,
    DateTime timestamp,
  ) async {
    _lastLatitude = latitude;
    _lastLongitude = longitude;
    _lastUpdateTime = timestamp;
    notifyListeners();

    if (_vendorId == null) return;

    if (_isOnline) {
      // Try to update Firebase directly
      try {
        await _databaseService.updateVendorLocation(
          _vendorId!,
          latitude,
          longitude,
        );

        // Also flush any queued updates
        await _flushQueue();

        // Update notification
        await _foregroundService.updateNotification(
          'Location updated at ${_formatTime(timestamp)}',
        );
      } catch (e) {
        // If Firebase update fails, queue it
        debugPrint('Firebase update failed, queueing: $e');
        await _queueService.enqueue(latitude, longitude, timestamp);
      }
    } else {
      // Offline - queue the update
      await _queueService.enqueue(latitude, longitude, timestamp);
      await _foregroundService.updateNotification(
        'Offline - ${_queueService.queueLength} updates pending',
      );
    }
  }

  /// Flush queued location updates to Firebase
  Future<void> _flushQueue() async {
    if (_vendorId == null || !_isOnline) return;

    final queuedUpdates = await _queueService.getAll();
    if (queuedUpdates.isEmpty) return;

    // Only send the most recent update (no need for historical data in MVP)
    final mostRecent = queuedUpdates.last;

    try {
      await _databaseService.updateVendorLocation(
        _vendorId!,
        mostRecent['latitude'] as double,
        mostRecent['longitude'] as double,
      );

      // Clear the queue after successful sync
      await _queueService.clear();

      await _foregroundService.updateNotification(
        'Back online - location synced',
      );
    } catch (e) {
      debugPrint('Queue flush failed: $e');
    }
  }

  /// Handle stop request from notification button
  void _handleStopRequested() {
    stopBroadcasting();
  }

  /// Handle errors from foreground service
  void _handleError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _setState(LocationManagerState newState) {
    _state = newState;
    _errorMessage = null;
    notifyListeners();
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Start monitoring for timeout (call after going online)
  void _startTimeoutMonitoring() {
    _timeoutCheckTimer?.cancel();
    _timeoutCheckTimer = Timer.periodic(_checkInterval, (timer) {
      _checkForTimeout();
    });
  }

  /// Stop monitoring (call when going offline)
  void _stopTimeoutMonitoring() {
    _timeoutCheckTimer?.cancel();
    _timeoutCheckTimer = null;
  }

  /// Check if we've timed out
  void _checkForTimeout() {
    if (_lastUpdateTime == null) return;

    final timeSinceLastUpdate = DateTime.now().difference(_lastUpdateTime!);

    if (timeSinceLastUpdate > _timeoutDuration) {
      // We've timed out - go offline
      debugPrint('Location timeout detected - going offline');
      stopBroadcasting();
    } else if (timeSinceLastUpdate > _warningThreshold) {
      // Warning - update notification
      _foregroundService.updateNotification(
        'Warning: No location update in ${timeSinceLastUpdate.inMinutes} min',
      );
    }
  }

  /// Clean up resources
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _timeoutCheckTimer?.cancel();
    super.dispose();
  }

  /// Check if currently broadcasting
  bool get isActive => _state == LocationManagerState.active;

  /// Check if online
  bool get isOnline => _isOnline;

  /// Get queue length
  int get pendingUpdates => _queueService.queueLength;
}
