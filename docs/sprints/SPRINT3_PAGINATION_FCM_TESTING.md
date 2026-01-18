# Sprint 3: Pagination, Push Notifications & Testing

**Status:** Completed
**Duration:** Core infrastructure and quality assurance

## Overview

Sprint 3 focused on implementing efficient data pagination, push notification infrastructure, and comprehensive test coverage.

## Completed Tasks

### 1. Firestore Cursor-Based Pagination

**Implementation:**
- Created `PaginatedResult<T>` generic class for pagination results
- Added `getActiveVendorsPaginated()` method with cursor support
- Added `searchVendorsPaginated()` method for paginated search
- Implemented infinite scroll with `ScrollController` detection
- Fetches 10 vendors per page with "load more" capability

**Key Classes:**

```dart
/// Result of a paginated query
class PaginatedResult<T> {
  final List<T> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  PaginatedResult({
    required this.items,
    this.lastDocument,
    required this.hasMore,
  });
}
```

**DatabaseService Methods:**

```dart
static const int vendorsPerPage = 10;

Future<PaginatedResult<VendorProfile>> getActiveVendorsPaginated({
  DocumentSnapshot? startAfter,
  int limit = vendorsPerPage,
}) async {
  final cutoffTime = DateTime.now().subtract(const Duration(minutes: 10));

  Query query = _firestore
      .collection('vendor_profiles')
      .where('isActive', isEqualTo: true)
      .orderBy('locationUpdatedAt', descending: true)
      .limit(limit + 1); // Fetch one extra to check for more

  if (startAfter != null) {
    query = query.startAfterDocument(startAfter);
  }

  final snapshot = await query.get();
  // ... process and return PaginatedResult
}
```

**VendorListScreen Updates:**
- Added `ScrollController` with scroll position listener
- Triggers load more when within 200px of bottom
- Shows loading indicator during pagination
- Maintains scroll position during data updates

---

### 2. Firebase Cloud Messaging (FCM)

**Package Added:** `firebase_messaging: ^15.0.0`

**Implementation:**
- Created `NotificationService` singleton class
- Implemented background message handler (top-level function)
- Request permission handling for iOS/Android 13+
- Foreground and background message handling
- Topic-based subscription system

**Key File:** `lib/services/notification_service.dart`

```dart
/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _fcmToken;

  Future<void> initialize() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await _setupMessaging();
    }
  }

  Future<void> _setupMessaging() async {
    _fcmToken = await _messaging.getToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      _tokenController.add(token);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check for initial message (cold start from notification)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }
}
```

**Topic Subscription Methods:**
- `subscribeToTopic(String topic)` - Generic topic subscription
- `subscribeVendorToOrders(String vendorId)` - Vendor order notifications
- `subscribeToVendorUpdates(String vendorId)` - Customer vendor tracking
- `unsubscribeFromTopic(String topic)` - Topic unsubscription

**Integration in main.dart:**
```dart
void main() async {
  // ...
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService().initialize();
  // ...
}
```

---

### 3. Test Coverage

**Test Dependencies Added:**
```yaml
dev_dependencies:
  mockito: ^5.4.4
  build_runner: ^2.4.8
  fake_cloud_firestore: ^3.1.0
```

**Test Files Created:**

#### `test/utils/validators_test.dart` (36 tests)

Tests for `Validators` class:
- Email validation (null, empty, invalid format, valid emails)
- Password validation (null, empty, short, valid)
- Business name validation (null, empty, short, max length, XSS injection, valid)
- Description validation (null, empty, max length, XSS injection, valid)

Tests for `MenuItemValidators` class:
- Name validation (null, empty, short, max length, XSS injection, valid)
- Price validation (null, empty, non-numeric, negative, max limit, valid)
- Description validation (null, empty, max length, XSS injection, valid)

#### `test/services/theme_service_test.dart` (8 tests)

- Default theme mode is system
- Correct label for each theme mode
- Correct icon for each theme mode
- Theme change notifies listeners
- No notification when setting same theme
- Toggle cycles through modes correctly
- Theme persists to SharedPreferences
- All theme modes can be set

#### `test/widgets/menu_item_form_test.dart` (11 tests)

- Displays "Add Menu Item" title for new item
- Displays "Edit Item" title for existing item
- Pre-populates fields when editing
- Shows delete button only when editing
- Validates required fields
- Calls onSave with correct values
- Passes null for empty description
- Shows delete confirmation dialog
- Closes dialog on cancel
- Has close button
- Shows max length counter for name field

#### `test/widget_test.dart` (3 tests)

- Light theme has correct primary color
- Dark theme has correct primary color
- Light and dark themes share primary color

**Test Command:**
```bash
flutter test
# Output: 67 tests passed!
```

---

## Files Created/Modified

| File | Action | Description |
|------|--------|-------------|
| `pubspec.yaml` | Modified | Added firebase_messaging, test dependencies |
| `lib/services/database_service.dart` | Modified | Added PaginatedResult, pagination methods |
| `lib/services/notification_service.dart` | Created | FCM notification handling |
| `lib/screens/customer/vendor_list_screen.dart` | Modified | Added infinite scroll pagination |
| `lib/main.dart` | Modified | Added FCM initialization |
| `test/utils/validators_test.dart` | Created | Validator unit tests |
| `test/services/theme_service_test.dart` | Created | ThemeService unit tests |
| `test/widgets/menu_item_form_test.dart` | Created | MenuItemForm widget tests |
| `test/widget_test.dart` | Modified | AppTheme tests |

## Test Results Summary

| Test File | Tests | Status |
|-----------|-------|--------|
| validators_test.dart | 36 | PASS |
| theme_service_test.dart | 8 | PASS |
| menu_item_form_test.dart | 11 | PASS |
| widget_test.dart | 3 | PASS |
| location_queue_service_test.dart | 9 | PASS |
| **Total** | **67** | **ALL PASS** |

## Performance Improvements

1. **Reduced Initial Load:** Only 10 vendors loaded initially vs. entire collection
2. **On-Demand Loading:** Additional vendors loaded as user scrolls
3. **Freshness Check:** Filters out stale vendor data (>10 min old)
4. **Memory Efficiency:** Cursor-based pagination doesn't load all documents

## Next Steps

Sprint 4: State Management Migration (Riverpod), Customer Favorites, Offline Sync
