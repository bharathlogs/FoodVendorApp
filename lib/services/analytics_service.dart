import 'package:firebase_analytics/firebase_analytics.dart';

/// Service for tracking analytics events throughout the app.
/// Provides a centralized way to log user actions and screen views.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // User Properties
  Future<void> setUserRole(String role) async {
    await _analytics.setUserProperty(name: 'user_role', value: role);
  }

  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }

  // Authentication Events
  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> logLogout() async {
    await _analytics.logEvent(name: 'logout');
  }

  // Vendor Events
  Future<void> logVendorGoOnline(String vendorId) async {
    await _analytics.logEvent(
      name: 'vendor_go_online',
      parameters: {'vendor_id': vendorId},
    );
  }

  Future<void> logVendorGoOffline(String vendorId) async {
    await _analytics.logEvent(
      name: 'vendor_go_offline',
      parameters: {'vendor_id': vendorId},
    );
  }

  Future<void> logVendorView(String vendorId, String? cuisineType) async {
    await _analytics.logEvent(
      name: 'vendor_view',
      parameters: {
        'vendor_id': vendorId,
        if (cuisineType != null) 'cuisine': cuisineType,
      },
    );
  }

  // Menu Events
  Future<void> logMenuItemAdd(String vendorId, String itemName) async {
    await _analytics.logEvent(
      name: 'menu_item_add',
      parameters: {
        'vendor_id': vendorId,
        'item_name': itemName,
      },
    );
  }

  Future<void> logMenuItemDelete(String vendorId, String itemName) async {
    await _analytics.logEvent(
      name: 'menu_item_delete',
      parameters: {
        'vendor_id': vendorId,
        'item_name': itemName,
      },
    );
  }

  Future<void> logMenuItemUpdate(String vendorId, String itemName) async {
    await _analytics.logEvent(
      name: 'menu_item_update',
      parameters: {
        'vendor_id': vendorId,
        'item_name': itemName,
      },
    );
  }

  // Order Events
  Future<void> logOrderPlaced(String vendorId, int itemCount) async {
    await _analytics.logEvent(
      name: 'order_placed',
      parameters: {
        'vendor_id': vendorId,
        'item_count': itemCount,
      },
    );
  }

  Future<void> logOrderCompleted(String orderId, String vendorId) async {
    await _analytics.logEvent(
      name: 'order_completed',
      parameters: {
        'order_id': orderId,
        'vendor_id': vendorId,
      },
    );
  }

  // Location Events
  Future<void> logLocationPermissionGranted() async {
    await _analytics.logEvent(name: 'location_permission_granted');
  }

  Future<void> logLocationPermissionDenied() async {
    await _analytics.logEvent(name: 'location_permission_denied');
  }

  // Screen Views
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // Search Events
  Future<void> logSearch(String searchTerm) async {
    await _analytics.logSearch(searchTerm: searchTerm);
  }

  // Generic Event
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }
}
