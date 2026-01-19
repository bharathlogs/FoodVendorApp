# Database Service API Documentation

This document describes the Firestore database operations for FoodVendorApp.

## Overview

`DatabaseService` is the primary interface for all Firestore operations, including:
- Vendor profile management
- Paginated queries
- Server-side search
- Reviews and ratings
- Favorites management
- FCM token storage

---

## Vendor Queries

### Get Active Vendors (Paginated)

Fetches vendors with pagination support using cursor-based navigation.

```dart
final dbService = DatabaseService();

// First page (20 vendors)
final result = await dbService.getActiveVendorsPaginated();

// Next page
final nextPage = await dbService.getActiveVendorsPaginated(
  startAfter: result.lastDocument,
);

// Custom page size
final smallPage = await dbService.getActiveVendorsPaginated(limit: 10);
```

**Return Type:** `PaginatedResult<VendorProfile>`

```dart
class PaginatedResult<T> {
  final List<T> items;           // The vendor profiles
  final DocumentSnapshot? lastDocument;  // Cursor for next page
  final bool hasMore;            // Whether more items exist
}
```

### Get Active Vendors (Stream)

Real-time stream of active vendors within last 10 minutes.

```dart
final stream = dbService.getActiveVendorsStream();

stream.listen((vendors) {
  // Update UI with fresh vendor list
  setState(() => _vendors = vendors);
});
```

### Get Vendors Near Location

Geohash-based spatial query for nearby vendors.

```dart
final stream = dbService.getVendorsNearLocation(
  latitude: 37.7749,
  longitude: -122.4194,
  queryPrecision: 5,  // ~5km radius
);
```

---

## Server-Side Search

### Search Vendors (Paginated)

Performs efficient server-side search using parallel Firestore queries.

```dart
final result = await dbService.searchVendorsPaginated(
  query: 'Taco',
  limit: 20,
);
```

**How It Works:**

1. **Parallel Queries:**
   - Business name prefix match (range query)
   - Cuisine tag exact match (arrayContains)

2. **Merge & Deduplicate:**
   - Results combined and deduplicated by vendor ID
   - Freshness filter applied (last 10 minutes)

3. **Secondary Filter:**
   - Case-insensitive substring matching
   - Catches edge cases server queries miss

**Required Firestore Index:**

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

### Search Implementation Details

```dart
// Business name prefix search
// Matches: "Taco Palace", "Taco Express", "Tacos El Rey"
Query query = firestore
    .collection('vendor_profiles')
    .where('isActive', isEqualTo: true)
    .where('businessName', isGreaterThanOrEqualTo: 'Taco')
    .where('businessName', isLessThan: 'Taco\uf8ff')
    .limit(20);

// Cuisine tag search
// Matches vendors with 'Mexican' in cuisineTags array
Query query = firestore
    .collection('vendor_profiles')
    .where('isActive', isEqualTo: true)
    .where('cuisineTags', arrayContains: 'Mexican')
    .limit(20);
```

---

## Vendor Profile Operations

### Get Single Vendor

```dart
final vendor = await dbService.getVendorProfile(vendorId);
```

### Get Vendor Stream (Real-time)

```dart
final stream = dbService.getVendorProfileStream(vendorId);
stream.listen((vendor) {
  if (vendor != null) {
    // Update UI
  }
});
```

### Create/Update Vendor Profile

```dart
await dbService.createOrUpdateVendorProfile(vendorProfile);
```

### Update Location

```dart
await dbService.updateVendorLocation(
  vendorId: 'vendor123',
  latitude: 37.7749,
  longitude: -122.4194,
  geohash: 'abc123',  // Pre-computed geohash
);
```

### Toggle Active Status

```dart
await dbService.setVendorActive(vendorId, true);  // Go online
await dbService.setVendorActive(vendorId, false); // Go offline
```

---

## Menu Items

### Get Menu Items (Stream)

```dart
final stream = dbService.getMenuItemsStream(vendorId);
```

### Add Menu Item

```dart
final itemId = await dbService.addMenuItem(vendorId, menuItem);
```

### Update Menu Item

```dart
await dbService.updateMenuItem(vendorId, itemId, updatedMenuItem);
```

### Delete Menu Item

```dart
await dbService.deleteMenuItem(vendorId, itemId);
```

---

## Reviews

### Get Reviews (Stream)

```dart
final stream = dbService.getReviewsStream(vendorId);
```

### Get Paginated Reviews

```dart
final reviews = await dbService.getReviewsPaginated(
  vendorId: vendorId,
  limit: 10,
  startAfter: lastDocument,
);
```

### Get User's Review for Vendor

```dart
final stream = dbService.getUserReviewForVendorStream(vendorId, userId);
```

### Add Review

```dart
await dbService.addReview(vendorId, review);
// Automatically updates vendor's average rating
```

### Update Review

```dart
await dbService.updateReview(vendorId, reviewId, updatedReview);
// Automatically recalculates vendor's average rating
```

### Delete Review

```dart
await dbService.deleteReview(vendorId, reviewId);
// Automatically recalculates vendor's average rating
```

---

## Favorites

### Get User's Favorites (Stream)

```dart
final stream = dbService.getFavoritesStream(userId);
```

### Get Favorite Vendor IDs (Stream)

```dart
final stream = dbService.getFavoriteVendorIdsStream(userId);
// Returns Stream<List<String>> of vendor IDs
```

### Add Favorite

```dart
await dbService.addFavorite(userId, vendorId);
```

### Remove Favorite

```dart
await dbService.removeFavorite(userId, vendorId);
```

### Check if Favorited

```dart
final isFav = await dbService.isFavorite(userId, vendorId);
```

---

## Orders

### Create Order

```dart
final orderId = await dbService.createOrder(order);
```

### Get Customer Orders (Stream)

```dart
final stream = dbService.getCustomerOrdersStream(customerId);
```

### Get Vendor Orders (Stream)

```dart
final stream = dbService.getVendorOrdersStream(vendorId);
```

### Update Order Status

```dart
await dbService.updateOrderStatus(orderId, OrderStatus.preparing);
```

---

## FCM Token Storage

### Store Token

```dart
await dbService.storeFcmToken(
  userId: userId,
  token: fcmToken,
  platform: 'android',  // or 'ios'
  deviceModel: 'Pixel 7',  // optional
);
```

### Remove Token

```dart
await dbService.removeFcmToken(userId, token);
```

### Remove All Tokens

```dart
await dbService.removeAllFcmTokens(userId);
```

### Get User's Tokens

```dart
final tokens = await dbService.getUserFcmTokens(userId);
```

---

## User Preferences

### Update Notification Preferences

```dart
await dbService.updateNotificationPreferences(userId, {
  'orderUpdates': true,
  'promotions': false,
  'vendorNearby': true,
  'newVendors': false,
  'favoriteCuisines': ['Mexican', 'Thai'],
});
```

### Get Cuisine Topics for User

```dart
final topics = await dbService.getCuisineTopicsForUser(userId);
// Returns: ['cuisine_mexican', 'cuisine_thai']
```

---

## Utility Methods

### Batch Update

```dart
await dbService.batchUpdate([
  {'id': 'doc1', 'data': {'field': 'value1'}},
  {'id': 'doc2', 'data': {'field': 'value2'}},
], 'collection_name');
```

---

## Firestore Data Structure

```
firestore/
├── users/{userId}
│   ├── email, displayName, role, createdAt, phoneNumber
│   ├── notificationPreferences: { orderUpdates, promotions, ... }
│   └── fcm_tokens/{tokenId}
│       └── token, platform, deviceModel, createdAt, lastUpdatedAt
│
├── vendor_profiles/{vendorId}
│   ├── businessName, description, isActive
│   ├── latitude, longitude, geohash, locationUpdatedAt
│   ├── cuisineTags: ['Mexican', 'Tacos']
│   ├── averageRating, totalRatings
│   ├── menu_items/{itemId}
│   │   └── name, description, price, imageUrl, isAvailable
│   └── reviews/{reviewId}
│       └── customerId, customerName, rating, comment, createdAt
│
├── orders/{orderId}
│   └── customerId, vendorId, items, status, total, createdAt
│
├── favorites/{favoriteId}
│   └── customerId, vendorId, createdAt
│
└── review_rate_limits/{userId}  // For Cloud Functions
    └── timestamps: [...]
```

---

## Firestore Indexes

Required composite indexes for efficient queries:

```json
{
  "indexes": [
    {
      "collectionGroup": "orders",
      "fields": [
        { "fieldPath": "vendorId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "vendor_profiles",
      "fields": [
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "cuisineTags", "arrayConfig": "CONTAINS" }
      ]
    },
    {
      "collectionGroup": "vendor_profiles",
      "fields": [
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "businessName", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "vendor_profiles",
      "fields": [
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "locationUpdatedAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "vendor_profiles",
      "fields": [
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "geohash", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "favorites",
      "fields": [
        { "fieldPath": "customerId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

---

## Error Handling

```dart
try {
  final result = await dbService.searchVendorsPaginated(query: 'Taco');
} on FirebaseException catch (e) {
  if (e.code == 'permission-denied') {
    // Handle permission error
  } else if (e.code == 'unavailable') {
    // Handle offline/network error
  }
}
```

---

## Testing

```bash
# Run database service tests
flutter test test/services/database_service_search_test.dart
flutter test test/services/fcm_token_storage_test.dart
```
