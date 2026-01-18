import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'analytics_service.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.messageId}');
}

/// Service for handling Firebase Cloud Messaging notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final _analytics = AnalyticsService();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  final _tokenController = StreamController<String>.broadcast();
  Stream<String> get onTokenRefresh => _tokenController.stream;

  final _messageController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onMessage => _messageController.stream;

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    // Request permission (iOS and Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('FCM permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _setupMessaging();
    }
  }

  Future<void> _setupMessaging() async {
    // Get FCM token
    _fcmToken = await _messaging.getToken();
    debugPrint('FCM Token: $_fcmToken');

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      _tokenController.add(token);
      debugPrint('FCM Token refreshed: $token');
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check for initial message (app opened from terminated state via notification)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    _messageController.add(message);

    // Track notification received
    _analytics.logEvent('notification_received', {
      'message_id': message.messageId ?? '',
      'title': message.notification?.title ?? '',
      'from_background': 'false',
    });
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.notification?.title}');

    // Track notification tap
    _analytics.logEvent('notification_tapped', {
      'message_id': message.messageId ?? '',
      'title': message.notification?.title ?? '',
    });

    // Handle navigation based on message data
    final data = message.data;
    if (data.containsKey('type')) {
      _handleNotificationNavigation(data);
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    switch (type) {
      case 'new_order':
        // Navigate to orders screen
        debugPrint('Navigate to orders: ${data['order_id']}');
        break;
      case 'vendor_nearby':
        // Navigate to vendor on map
        debugPrint('Navigate to vendor: ${data['vendor_id']}');
        break;
      default:
        debugPrint('Unknown notification type: $type');
    }
  }

  /// Subscribe to a topic for targeted notifications
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  /// Subscribe vendor to their order notifications
  Future<void> subscribeVendorToOrders(String vendorId) async {
    await subscribeToTopic('vendor_$vendorId');
  }

  /// Unsubscribe vendor from order notifications
  Future<void> unsubscribeVendorFromOrders(String vendorId) async {
    await unsubscribeFromTopic('vendor_$vendorId');
  }

  /// Subscribe customer to vendor updates (when vendor goes online)
  Future<void> subscribeToVendorUpdates(String vendorId) async {
    await subscribeToTopic('vendor_updates_$vendorId');
  }

  /// Unsubscribe from vendor updates
  Future<void> unsubscribeFromVendorUpdates(String vendorId) async {
    await unsubscribeFromTopic('vendor_updates_$vendorId');
  }

  void dispose() {
    _tokenController.close();
    _messageController.close();
  }
}
