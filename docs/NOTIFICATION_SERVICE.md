# Notification Service API Documentation

This document describes the push notification system implementation for FoodVendorApp.

## Overview

The notification system uses Firebase Cloud Messaging (FCM) with:
- Topic-based subscriptions for segmented notifications
- Firestore-stored FCM tokens for direct device targeting
- User preferences for notification opt-in/opt-out

---

## NotificationService

Singleton service for managing FCM interactions.

### Initialization

```dart
import 'package:food_vendor_app/services/notification_service.dart';

// In main.dart, after Firebase initialization
FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

// Initialize notification service
await NotificationService().initialize();
```

### User Authentication Integration

```dart
// After successful login
final user = FirebaseAuth.instance.currentUser;
if (user != null) {
  await NotificationService().setUserId(user.uid);
}

// On logout
await NotificationService().clearUserId();
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `fcmToken` | `String?` | Current device's FCM token |
| `onTokenRefresh` | `Stream<String>` | Stream of token refresh events |
| `onMessage` | `Stream<RemoteMessage>` | Stream of foreground messages |

---

## Topic Subscriptions

### Vendor Order Notifications

For vendors to receive new order notifications:

```dart
// Subscribe when vendor goes online
await NotificationService().subscribeVendorToOrders(vendorId);

// Unsubscribe when vendor goes offline
await NotificationService().unsubscribeVendorFromOrders(vendorId);
```

### Customer Vendor Updates

For customers to receive updates from favorite vendors:

```dart
// When customer favorites a vendor
await NotificationService().subscribeToVendorUpdates(vendorId);

// When customer unfavorites
await NotificationService().unsubscribeFromVendorUpdates(vendorId);
```

### Cuisine-Based Notifications

```dart
// Subscribe to cuisine
await NotificationService().subscribeToCuisine('Mexican');
// Creates topic: cuisine_mexican

// Unsubscribe
await NotificationService().unsubscribeFromCuisine('Mexican');

// Batch update (efficient for preference changes)
await NotificationService().updateCuisineSubscriptions(
  oldCuisines: ['Thai', 'Chinese'],
  newCuisines: ['Mexican', 'Thai'],  // Keeps Thai, removes Chinese, adds Mexican
);
```

### Global Topics

```dart
// Promotional notifications
await NotificationService().subscribeToPromotions();
await NotificationService().unsubscribeFromPromotions();

// New vendor announcements
await NotificationService().subscribeToNewVendors();
await NotificationService().unsubscribeFromNewVendors();
```

### Sync All Preferences

Convenience method to sync all subscriptions at once:

```dart
await NotificationService().syncSubscriptionsWithPreferences(
  orderUpdates: true,
  promotions: true,
  newVendors: false,
  favoriteCuisines: ['Mexican', 'Thai', 'Italian'],
  previousCuisines: ['Chinese', 'Thai'],  // Optional: for efficient unsubscribe
);
```

---

## FCM Token Storage

Tokens are stored in Firestore for server-side targeting (e.g., Cloud Functions).

### Data Structure

```
users/{userId}/fcm_tokens/{tokenId}
├── token: string           // The FCM token
├── platform: string        // 'ios' or 'android'
├── deviceModel: string?    // Optional device info
├── createdAt: timestamp    // When token was first stored
└── lastUpdatedAt: timestamp // Last update time
```

### DatabaseService Methods

```dart
final dbService = DatabaseService();

// Store token
await dbService.storeFcmToken(
  userId: 'user123',
  token: 'fcm_token_abc...',
  platform: 'android',
  deviceModel: 'Pixel 7',  // Optional
);

// Remove single token (on logout)
await dbService.removeFcmToken('user123', 'fcm_token_abc...');

// Remove all tokens (logout from all devices)
await dbService.removeAllFcmTokens('user123');

// Get all tokens for a user (for server-side notifications)
final tokens = await dbService.getUserFcmTokens('user123');
```

---

## NotificationPreferences Model

User preferences for notification types.

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `orderUpdates` | `bool` | `true` | Order status notifications |
| `promotions` | `bool` | `true` | Promotional offers |
| `vendorNearby` | `bool` | `true` | Nearby vendor alerts |
| `newVendors` | `bool` | `false` | New vendor announcements |
| `favoriteCuisines` | `List<String>` | `[]` | Preferred cuisine types |

### Usage

```dart
// Create with defaults
const prefs = NotificationPreferences();

// Create with custom values
const prefs = NotificationPreferences(
  orderUpdates: true,
  promotions: false,
  vendorNearby: true,
  newVendors: true,
  favoriteCuisines: ['Mexican', 'Thai'],
);

// Copy with modifications
final updated = prefs.copyWith(
  promotions: true,
  favoriteCuisines: ['Italian', 'French'],
);

// Serialize to/from Firestore
final map = prefs.toMap();
final restored = NotificationPreferences.fromMap(map);
```

### Integration with UserModel

```dart
final user = UserModel(
  uid: 'user123',
  email: 'user@example.com',
  role: UserRole.customer,
  displayName: 'John Doe',
  createdAt: DateTime.now(),
  notificationPreferences: const NotificationPreferences(
    promotions: true,
    favoriteCuisines: ['Mexican'],
  ),
);

// Access preferences
final wantsPromos = user.notificationPreferences.promotions;
```

---

## Firestore Security Rules

```javascript
// Users can manage their own FCM tokens
match /users/{userId}/fcm_tokens/{tokenId} {
  // Only the user can read their own tokens
  allow read: if request.auth != null && request.auth.uid == userId;

  // Create requires token and platform fields
  allow create: if request.auth != null &&
    request.auth.uid == userId &&
    request.resource.data.keys().hasAll(['token', 'platform']);

  // Update allowed for token owner
  allow update: if request.auth != null && request.auth.uid == userId;

  // Delete allowed for token owner (on logout)
  allow delete: if request.auth != null && request.auth.uid == userId;
}
```

---

## Sending Notifications (Server-Side)

Example Cloud Function to send notification to a user's devices:

```typescript
import * as admin from 'firebase-admin';

async function sendNotificationToUser(
  userId: string,
  title: string,
  body: string,
  data?: Record<string, string>
) {
  // Get all user's FCM tokens
  const tokensSnapshot = await admin.firestore()
    .collection('users')
    .doc(userId)
    .collection('fcm_tokens')
    .get();

  const tokens = tokensSnapshot.docs.map(doc => doc.data().token);

  if (tokens.length === 0) return;

  // Send to all devices
  const message: admin.messaging.MulticastMessage = {
    tokens,
    notification: { title, body },
    data,
  };

  const response = await admin.messaging().sendEachForMulticast(message);

  // Handle failed tokens (remove invalid ones)
  response.responses.forEach((resp, idx) => {
    if (!resp.success && resp.error?.code === 'messaging/invalid-registration-token') {
      // Remove invalid token
      const invalidToken = tokens[idx];
      admin.firestore()
        .collection('users')
        .doc(userId)
        .collection('fcm_tokens')
        .doc(invalidToken)
        .delete();
    }
  });
}
```

### Sending to Topics

```typescript
// Send to all users subscribed to 'promotions' topic
await admin.messaging().send({
  topic: 'promotions',
  notification: {
    title: '50% Off Today!',
    body: 'Use code HALFOFF at checkout',
  },
});

// Send to cuisine topic
await admin.messaging().send({
  topic: 'cuisine_mexican',
  notification: {
    title: 'New Mexican Restaurant!',
    body: 'Taco Palace just opened near you',
  },
  data: {
    type: 'new_vendor',
    vendor_id: 'vendor_xyz',
  },
});
```

---

## Handling Notifications

### Foreground Messages

```dart
// Listen to foreground messages
NotificationService().onMessage.listen((message) {
  // Show in-app notification
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message.notification?.title ?? '')),
  );
});
```

### Background/Terminated Handling

The `firebaseMessagingBackgroundHandler` handles messages when the app is in background:

```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message
  // Note: Cannot show UI, but can update local storage, etc.
  debugPrint('Background message: ${message.messageId}');
}
```

### Notification Tap Handling

When user taps a notification, navigate to appropriate screen:

```dart
// In notification_service.dart
void _handleNotificationTap(RemoteMessage message) {
  final data = message.data;

  switch (data['type']) {
    case 'new_order':
      // Navigate to orders screen
      navigatorKey.currentState?.pushNamed('/orders', arguments: data['order_id']);
      break;
    case 'vendor_nearby':
      // Navigate to vendor on map
      navigatorKey.currentState?.pushNamed('/vendor', arguments: data['vendor_id']);
      break;
  }
}
```

---

## Testing

### Unit Tests

```bash
flutter test test/models/notification_preferences_test.dart
flutter test test/services/fcm_token_storage_test.dart
```

### Manual Testing Checklist

1. [ ] FCM token generated on app launch
2. [ ] Token persisted to Firestore after login
3. [ ] Token removed from Firestore on logout
4. [ ] Topic subscriptions update with preferences
5. [ ] Foreground notifications show in-app
6. [ ] Background notifications appear in system tray
7. [ ] Notification tap navigates to correct screen
8. [ ] Token refresh updates Firestore

---

## Troubleshooting

### Token Not Persisting

- Verify user is logged in before calling `setUserId`
- Check Firestore rules allow write to `fcm_tokens` subcollection
- Ensure `storeFcmToken` is awaited

### Notifications Not Received

- Verify device has valid FCM token
- Check topic subscription is complete
- Ensure background handler is registered in main.dart
- Check Firebase Console for delivery status

### Duplicate Notifications

- Ensure `setUserId` is called only once per login
- Old tokens should be removed on logout
- Token refresh handler should remove old token before adding new one
