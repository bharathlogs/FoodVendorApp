# FoodVendorApp Enhancement Roadmap Documentation

This document describes all enhancements implemented as part of the mobile app optimization roadmap.

## Table of Contents

1. [Sprint 1 - Quick Wins](#sprint-1---quick-wins)
2. [Sprint 2-3 - High-Impact Features](#sprint-2-3---high-impact-features)
3. [Strategic Investments](#strategic-investments)
4. [Testing](#testing)
5. [Deployment](#deployment)

---

## Sprint 1 - Quick Wins

### Item 2: Offline Persistence Configuration

**Purpose:** Enable offline data access for better user experience in areas with poor connectivity.

**Implementation:**
- Configured Firestore offline persistence settings
- Enabled automatic caching of frequently accessed data

**Files Modified:**
- `lib/main.dart` - Firebase initialization with persistence settings

---

### Item 4: Image Compression Before Upload

**Purpose:** Reduce bandwidth usage and storage costs by compressing images before upload.

**Implementation:**
- Added `flutter_image_compress` package
- Compress images to 70% quality (800x800 max) for vendor photos
- Compress images to 65% quality (600x600 max) for menu items
- Logs compression savings in debug mode

**Files Modified:**
- `lib/services/storage_service.dart`
- `pubspec.yaml`

**Usage:**
```dart
final storageService = StorageService();

// Upload vendor photo (auto-compressed)
final url = await storageService.uploadVendorPhoto(vendorId, imageFile);

// Upload menu item photo (auto-compressed)
final url = await storageService.uploadMenuItemPhoto(vendorId, itemId, imageFile);
```

---

### Item 6: Analytics Event Tracking

**Purpose:** Track user behavior for data-driven product decisions.

**Implementation:**
- Added `AnalyticsService` singleton
- Tracks key events: screen views, vendor interactions, orders, reviews
- Integrates with Firebase Analytics

**Files Modified:**
- `lib/services/analytics_service.dart`
- `lib/services/notification_service.dart`

**Events Tracked:**
- `notification_received` - When push notification arrives
- `notification_tapped` - When user taps notification
- Screen views, vendor views, order placements, etc.

---

### Item 7: Deep Linking Support

**Purpose:** Allow sharing of vendor profiles and enable marketing campaigns.

**Implementation:**
- Added `app_links` package for deep link handling
- Created `DeepLinkService` for parsing and handling links
- Supports vendor profile links and order tracking links

**Files Modified:**
- `lib/services/deep_link_service.dart`
- `lib/providers/providers.dart`
- `pubspec.yaml`

**Supported Link Formats:**
```
foodvendor://vendor/{vendorId}
foodvendor://order/{orderId}
https://foodvendorapp.com/vendor/{vendorId}
```

---

## Sprint 2-3 - High-Impact Features

### Item 1: Pagination for Vendor Lists

**Purpose:** Improve performance by loading vendors in batches instead of all at once.

**Implementation:**
- Added cursor-based pagination using Firestore's `startAfterDocument`
- Default page size: 20 vendors
- Implemented infinite scroll with loading indicator
- Added `PaginatedResult` wrapper class

**Files Modified:**
- `lib/services/database_service.dart`
- `lib/screens/customer/vendor_list_screen.dart`

**Usage:**
```dart
// First page
final result = await dbService.getActiveVendorsPaginated();

// Next page
final nextResult = await dbService.getActiveVendorsPaginated(
  startAfter: result.lastDocument,
);
```

---

### Item 5: Background Location Updates

**Purpose:** Keep vendor locations updated even when the app is in the background.

**Implementation:**
- Added `flutter_foreground_task` for background processing
- Location updates every 30 seconds when vendor is active
- Battery-efficient implementation with accuracy settings
- Automatic cleanup when vendor goes offline

**Files Modified:**
- `lib/services/location_service.dart`
- `lib/services/location_queue_service.dart`
- `pubspec.yaml`

---

### Item 8: Review System with Rate Limiting

**Purpose:** Allow customers to review vendors while preventing spam.

**Implementation:**
- Created `Review` model with rating, comment, timestamps
- Reviews stored as subcollection under `vendor_profiles`
- Client-side rate limiting: 5 reviews per hour per user
- Server-side validation in Firestore rules
- Auto-updates vendor's average rating

**Files Modified:**
- `lib/models/review.dart`
- `lib/services/database_service.dart`
- `lib/providers/providers.dart`
- `firestore.rules`

**Firestore Structure:**
```
vendor_profiles/{vendorId}/reviews/{reviewId}
  - customerId: string
  - customerName: string
  - rating: number (1-5)
  - comment: string (optional, max 500 chars)
  - createdAt: timestamp
  - updatedAt: timestamp
```

---

## Strategic Investments

### Item 3: Vendor List Virtualization

**Purpose:** Optimize scrolling performance for large vendor lists.

**Implementation:**
- Added `cacheExtent: 500` to pre-render items ahead of viewport
- Set `addAutomaticKeepAlives: false` to prevent memory bloat
- Wrapped vendor cards in `RepaintBoundary` for isolated repaints
- Explicit `addRepaintBoundaries: true` for clarity

**Files Modified:**
- `lib/screens/customer/vendor_list_screen.dart`

**Code Example:**
```dart
ListView.builder(
  controller: _scrollController,
  cacheExtent: 500,
  addAutomaticKeepAlives: false,
  addRepaintBoundaries: true,
  itemBuilder: (context, index) {
    return RepaintBoundary(
      child: VendorCard(vendor: vendors[index]),
    );
  },
)
```

---

### Item 10: Server-Side Search

**Purpose:** Reduce bandwidth by filtering search results on the server instead of client.

**Implementation:**
- Parallel Firestore queries for business name prefix and cuisine tags
- Business name: Range query with Unicode boundary (`\uf8ff`)
- Cuisine tags: `arrayContains` query
- Results merged and deduplicated client-side
- Secondary case-insensitive filter for edge cases

**Files Modified:**
- `lib/services/database_service.dart`
- `firestore.indexes.json`

**Firestore Index Added:**
```json
{
  "collectionGroup": "vendor_profiles",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "isActive", "order": "ASCENDING" },
    { "fieldPath": "businessName", "order": "ASCENDING" }
  ]
}
```

**Usage:**
```dart
final result = await dbService.searchVendorsPaginated(
  query: 'Taco',
  limit: 20,
);
```

---

### Item 12: Push Notification Segmentation

**Purpose:** Enable targeted push notifications based on user preferences.

**Implementation:**

#### 1. Notification Preferences Model
Added `NotificationPreferences` class to `UserModel`:

```dart
class NotificationPreferences {
  final bool orderUpdates;    // Order status notifications
  final bool promotions;      // Promotional offers
  final bool vendorNearby;    // Nearby vendor alerts
  final bool newVendors;      // New vendor announcements
  final List<String> favoriteCuisines;  // Cuisine-based targeting
}
```

#### 2. FCM Token Storage
Tokens stored as subcollection for multi-device support:

```
users/{userId}/fcm_tokens/{tokenId}
  - token: string
  - platform: 'ios' | 'android'
  - deviceModel: string (optional)
  - createdAt: timestamp
  - lastUpdatedAt: timestamp
```

#### 3. Topic Subscriptions
Users auto-subscribed to topics based on preferences:
- `promotions` - Promotional notifications
- `new_vendors` - New vendor announcements
- `cuisine_{name}` - Cuisine-specific notifications (e.g., `cuisine_mexican`)
- `vendor_{id}` - Order notifications for vendors
- `vendor_updates_{id}` - Updates from favorited vendors

**Files Modified:**
- `lib/models/user_model.dart`
- `lib/services/notification_service.dart`
- `lib/services/database_service.dart`
- `firestore.rules`

**Integration Example:**
```dart
// After user login
await NotificationService().setUserId(userId);

// Sync preferences with topic subscriptions
await NotificationService().syncSubscriptionsWithPreferences(
  orderUpdates: true,
  promotions: true,
  newVendors: false,
  favoriteCuisines: ['Mexican', 'Thai'],
  previousCuisines: [], // Pass old cuisines to unsubscribe
);

// On logout
await NotificationService().clearUserId();
```

---

## Testing

### Test Suite Overview

| Test File | Tests | Purpose |
|-----------|-------|---------|
| `notification_preferences_test.dart` | 21 | NotificationPreferences model |
| `database_service_search_test.dart` | 10 | Server-side search queries |
| `fcm_token_storage_test.dart` | 15 | FCM token CRUD operations |
| `user_model_test.dart` | 12 | UserModel serialization |
| `review_test.dart` | 8 | Review model |
| `vendor_profile_test.dart` | 10 | VendorProfile model |
| `menu_item_test.dart` | 8 | MenuItem model |
| `favorite_test.dart` | 6 | Favorite model |
| `geohash_utils_test.dart` | 12 | Geohash utilities |
| `deep_link_service_test.dart` | 8 | Deep link parsing |
| `biometric_service_test.dart` | 6 | Biometric auth |
| `theme_service_test.dart` | 4 | Theme preferences |
| `location_queue_service_test.dart` | 10 | Location batching |
| `validators_test.dart` | 15 | Input validation |
| `distance_formatter_test.dart` | 8 | Distance formatting |
| `menu_item_form_test.dart` | 12 | Menu item form widget |

### Running Tests

```bash
# Run all tests
./run_tests.sh

# Run unit tests only
flutter test

# Run specific test file
flutter test test/models/notification_preferences_test.dart

# Run with coverage
flutter test --coverage

# Run integration tests (requires device/emulator)
flutter test integration_test/app_test.dart
```

---

## Deployment

### Deploy Firestore Rules and Indexes

```bash
# Set active project
firebase use foodvendorapp2911

# Deploy rules and indexes
firebase deploy --only firestore:rules,firestore:indexes
```

### Post-Deployment Checklist

1. **FCM Token Integration**
   - Call `NotificationService().setUserId(userId)` after user login
   - Call `NotificationService().clearUserId()` on logout

2. **Analytics Verification**
   - Check Firebase Analytics dashboard for incoming events
   - Verify notification tracking events

3. **Deep Link Testing**
   - Test `foodvendor://vendor/{id}` links
   - Verify web links redirect correctly

4. **Search Testing**
   - Test business name prefix search
   - Test cuisine tag search
   - Verify pagination works with search

---

## Architecture Overview

```
lib/
├── models/
│   ├── user_model.dart          # User + NotificationPreferences
│   ├── vendor_profile.dart      # Vendor data
│   ├── menu_item.dart           # Menu items
│   ├── review.dart              # Reviews
│   └── favorite.dart            # Favorites
├── services/
│   ├── database_service.dart    # Firestore operations
│   ├── notification_service.dart # FCM handling
│   ├── analytics_service.dart   # Event tracking
│   ├── storage_service.dart     # Image upload
│   ├── deep_link_service.dart   # Deep link handling
│   └── location_service.dart    # Location tracking
├── providers/
│   └── providers.dart           # Riverpod providers
└── screens/
    └── customer/
        └── vendor_list_screen.dart  # Paginated vendor list
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | Initial | Base app with Firebase integration |
| 1.1.0 | Sprint 1 | Offline persistence, image compression, analytics, deep links |
| 1.2.0 | Sprint 2-3 | Pagination, background location, reviews |
| 1.3.0 | Strategic | Virtualization, server-side search, push segmentation |

---

## Support

For issues or questions:
- GitHub Issues: https://github.com/anthropics/claude-code/issues
- Firebase Console: https://console.firebase.google.com/project/foodvendorapp2911
