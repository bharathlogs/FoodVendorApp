# Food Finder v1.0.0

**Release Date:** January 19, 2026
**Build:** `food-finder-v1.0.0-20260119.apk`

---

## New Features

### State Management (Riverpod)
- Migrated from ChangeNotifier to Riverpod for centralized state management
- Created providers for AuthService, DatabaseService, AnalyticsService, NotificationService
- Added `authStateProvider` for reactive authentication state
- Theme management now uses `ThemeNotifier` with Riverpod

### Customer Favorites
- Added Favorites tab in customer bottom navigation
- Heart icon on vendor cards to add/remove favorites
- Favorites screen showing all saved vendors
- Real-time sync with Firestore

### Offline Support
- Enabled Firestore offline persistence
- Unlimited cache size for comprehensive offline access
- Automatic sync when connection restored

### Profile Menu
- Profile icon in app bar with popup menu
- Displays user email and role badge (Customer/Vendor)
- Logout option moved inside profile menu

---

## Bug Fixes

| ID | Issue | Fix |
|----|-------|-----|
| C2 | Vendor list shows "Something went wrong" | Added Firestore composite index for `isActive` + `locationUpdatedAt` query |
| H2 | Login error messages not user-friendly | Added handling for `invalid-credential`, `INVALID_LOGIN_CREDENTIALS` errors |
| H3 | App icon showing default Flutter icon | Added `flutter_launcher_icons` configuration |
| H4 | Favorites tab shows "can't fetch favorites" | Added Firestore security rules for `favorites` collection |
| H5 | Splash screen icon zoomed out | Applied `Transform.scale(1.25)` with `ClipRRect` |
| M2 | Logout button exposed without context | Added profile popup menu with email and role |
| M3 | Adaptive icon too small | Removed 16% inset from `ic_launcher.xml` |

---

## Technical Details

### Files Modified
- `pubspec.yaml` - Added Riverpod packages
- `lib/providers/providers.dart` - New centralized providers
- `lib/models/favorite.dart` - New Favorite model
- `lib/services/database_service.dart` - Added favorites CRUD
- `lib/screens/customer/favorites_screen.dart` - New screen
- `lib/screens/customer/customer_home.dart` - Favorites tab, profile menu
- `lib/screens/vendor/vendor_home.dart` - Profile menu
- `lib/screens/splash/splash_screen.dart` - Icon scale fix
- `lib/main.dart` - ProviderScope, offline persistence
- `firestore.rules` - Favorites security rules
- `firestore.indexes.json` - Composite indexes

### Firestore Collections
- `favorites` - Customer favorite vendors (new)

### Required Indexes
```
vendor_profiles: isActive + locationUpdatedAt
favorites: customerId + createdAt
```

---

## Installation

```bash
adb install food-finder-v1.0.0-20260119.apk
```

Or transfer APK to device and install manually.
