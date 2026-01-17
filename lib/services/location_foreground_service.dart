import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

// This handler runs in a separate isolate
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class LocationTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _positionSubscription;

  // Location settings: medium accuracy for battery efficiency
  final LocationSettings _locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.medium, // ~100m accuracy, lower battery
    distanceFilter: 50, // Only update if moved 50+ meters
  );

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('LocationTaskHandler started');

    // Start listening to location updates
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).listen((Position position) {
      // Send position back to main isolate
      FlutterForegroundTask.sendDataToMain({
        'type': 'location',
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });

    // Also send periodic updates even if not moving (heartbeat)
    _startPeriodicHeartbeat();
  }

  Timer? _heartbeatTimer;

  void _startPeriodicHeartbeat() {
    // Send heartbeat every 90 seconds to ensure we don't timeout
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 90),
      (timer) async {
        try {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: _locationSettings,
          );
          FlutterForegroundTask.sendDataToMain({
            'type': 'location',
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          FlutterForegroundTask.sendDataToMain({
            'type': 'error',
            'message': e.toString(),
          });
        }
      },
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Called based on eventAction set in ForegroundTaskOptions
    // We use this as a backup heartbeat - already handled by periodic timer
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    print('LocationTaskHandler destroyed');
    _heartbeatTimer?.cancel();
    await _positionSubscription?.cancel();
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'stop') {
      FlutterForegroundTask.sendDataToMain({'type': 'stop_requested'});
    }
  }

  @override
  void onNotificationPressed() {
    // User tapped the notification - launch app
    FlutterForegroundTask.launchApp();
    FlutterForegroundTask.sendDataToMain({'type': 'notification_pressed'});
  }
}

class LocationForegroundService {
  static final LocationForegroundService _instance =
      LocationForegroundService._internal();
  factory LocationForegroundService() => _instance;
  LocationForegroundService._internal();

  Function(double lat, double lng, DateTime timestamp)? _onLocationUpdate;
  Function()? _onStopRequested;
  Function(String error)? _onError;

  /// Initialize the foreground task configuration
  /// Call this in main() before runApp()
  static Future<void> initCommunicationPort() async {
    FlutterForegroundTask.initCommunicationPort();
  }

  /// Initialize the foreground task configuration
  Future<void> init() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'vendor_location_channel',
        channelName: 'Vendor Location Service',
        channelDescription: 'Sharing your location with customers',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(90000), // 90 seconds
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// Start the foreground service and begin location tracking
  Future<bool> startService({
    required Function(double lat, double lng, DateTime timestamp) onLocationUpdate,
    required Function() onStopRequested,
    Function(String error)? onError,
  }) async {
    _onLocationUpdate = onLocationUpdate;
    _onStopRequested = onStopRequested;
    _onError = onError;

    // Request permissions if needed
    final notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    // Add callback to receive data from TaskHandler
    FlutterForegroundTask.addTaskDataCallback(_handleMessage);

    // Start the service
    final ServiceRequestResult result;
    if (await FlutterForegroundTask.isRunningService) {
      result = await FlutterForegroundTask.restartService();
    } else {
      result = await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'You are Open for Business',
        notificationText: 'Customers can see your location',
        notificationIcon: null,
        notificationButtons: [
          const NotificationButton(id: 'stop', text: 'Go Offline'),
        ],
        callback: startCallback,
      );
    }

    return result is ServiceRequestSuccess;
  }

  void _handleMessage(dynamic message) {
    if (message is Map<String, dynamic>) {
      switch (message['type']) {
        case 'location':
          final lat = message['latitude'] as double;
          final lng = message['longitude'] as double;
          final timestamp = DateTime.parse(message['timestamp'] as String);
          _onLocationUpdate?.call(lat, lng, timestamp);
          break;
        case 'stop_requested':
          _onStopRequested?.call();
          break;
        case 'error':
          _onError?.call(message['message'] as String);
          break;
        case 'notification_pressed':
          // App is already in foreground
          break;
      }
    }
  }

  /// Stop the foreground service
  Future<bool> stopService() async {
    FlutterForegroundTask.removeTaskDataCallback(_handleMessage);
    final result = await FlutterForegroundTask.stopService();
    return result is ServiceRequestSuccess;
  }

  /// Check if service is currently running
  Future<bool> get isRunning => FlutterForegroundTask.isRunningService;

  /// Update the notification text
  Future<void> updateNotification(String text) async {
    await FlutterForegroundTask.updateService(
      notificationTitle: 'You are Open for Business',
      notificationText: text,
    );
  }
}
