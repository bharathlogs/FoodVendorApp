# Sprint 4: Riverpod, Customer Favorites & Offline Sync

**Status:** Completed
**Duration:** State management modernization and feature additions

## Overview

Sprint 4 focused on migrating state management to Riverpod, implementing a customer favorites feature, and enabling Firestore offline persistence.

## Completed Tasks

### 1. State Management Migration to Riverpod

**Packages Added:**
```yaml
dependencies:
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

dev_dependencies:
  riverpod_generator: ^2.4.0
```

**Implementation:**
- Created centralized providers file at `lib/providers/providers.dart`
- Migrated ThemeService from ChangeNotifier to Riverpod Notifier
- Created providers for all core services
- Wrapped app in `ProviderScope`
- Converted key widgets to ConsumerWidget/ConsumerStatefulWidget

**Key File:** `lib/providers/providers.dart`

#### Core Service Providers

```dart
/// Provides the AuthService singleton
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provides the DatabaseService singleton
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// Provides the AnalyticsService singleton
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// Provides the NotificationService singleton
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
```

#### Authentication Providers

```dart
/// Stream of Firebase auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Current user data from Firestore
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) async {
      if (user == null) return null;
      return await ref.read(authServiceProvider).getUserData(user.uid);
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Whether the current user is a vendor
final isVendorProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.valueOrNull?.role == UserRole.vendor;
});
```

#### Theme Provider (Migrated from ThemeService)

```dart
class ThemeNotifier extends Notifier<ThemeMode> {
  static const String _themeModeKey = 'theme_mode';

  @override
  ThemeMode build() {
    _loadSavedTheme();
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_themeModeKey, _themeModeToString(mode));
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.light
        ? ThemeMode.dark
        : state == ThemeMode.dark
            ? ThemeMode.system
            : ThemeMode.light;
    await setThemeMode(newMode);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});
```

#### main.dart Updates

```dart
void main() async {
  // ... Firebase initialization ...

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      themeMode: themeMode,
      // ...
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => CircularProgressIndicator(),
      error: (_, __) => LoginScreen(),
      data: (user) {
        if (user == null) return LoginScreen();
        // ... determine role and navigate
      },
    );
  }
}
```

---

### 2. Customer Favorites Feature

**Data Model:** `lib/models/favorite.dart`

```dart
class Favorite {
  final String favoriteId;
  final String customerId;
  final String vendorId;
  final DateTime createdAt;

  factory Favorite.fromFirestore(DocumentSnapshot doc) {
    // ... parse from Firestore
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'vendorId': vendorId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
```

**DatabaseService Methods:**

```dart
/// Add a vendor to customer's favorites
Future<void> addFavorite(String customerId, String vendorId) async {
  // Check if already favorited to avoid duplicates
  final existing = await _firestore
      .collection('favorites')
      .where('customerId', isEqualTo: customerId)
      .where('vendorId', isEqualTo: vendorId)
      .limit(1)
      .get();

  if (existing.docs.isNotEmpty) return;

  await _firestore.collection('favorites').add(Favorite(...).toFirestore());
}

/// Remove a vendor from customer's favorites
Future<void> removeFavorite(String customerId, String vendorId) async {
  final snapshot = await _firestore
      .collection('favorites')
      .where('customerId', isEqualTo: customerId)
      .where('vendorId', isEqualTo: vendorId)
      .get();

  for (final doc in snapshot.docs) {
    await doc.reference.delete();
  }
}

/// Get stream of customer's favorite vendor IDs
Stream<Set<String>> getFavoriteVendorIdsStream(String customerId) {
  return _firestore
      .collection('favorites')
      .where('customerId', isEqualTo: customerId)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => doc['vendorId'] as String).toSet());
}

/// Get customer's favorite vendors with full profile data
Stream<List<VendorProfile>> getFavoriteVendorsStream(String customerId) {
  // Fetches favorites and joins with vendor_profiles
  // Uses batch queries for Firestore whereIn limit (30)
}
```

**Favorites Providers:**

```dart
/// Stream of current user's favorite vendor IDs
final favoriteVendorIdsProvider = StreamProvider<Set<String>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return Stream.value(<String>{});
  return ref.read(databaseServiceProvider).getFavoriteVendorIdsStream(user.uid);
});

/// Check if a specific vendor is favorited
final isVendorFavoritedProvider = Provider.family<bool, String>((ref, vendorId) {
  final favoriteIds = ref.watch(favoriteVendorIdsProvider);
  return favoriteIds.valueOrNull?.contains(vendorId) ?? false;
});

/// Notifier for managing favorites actions
class FavoritesNotifier extends Notifier<AsyncValue<void>> {
  Future<void> toggleFavorite(String vendorId) async {
    // Toggle favorite status with optimistic updates
  }
}

final favoritesNotifierProvider = NotifierProvider<FavoritesNotifier, AsyncValue<void>>(...);
```

**UI Components:**

#### FavoritesScreen (`lib/screens/customer/favorites_screen.dart`)
- Shows list of favorited vendors with profile info
- Handles login prompt for unauthenticated users
- Empty state when no favorites
- Remove favorite button on each card
- Pull-to-refresh support

#### Favorite Button in VendorListScreen
```dart
class _FavoriteButton extends ConsumerWidget {
  final String vendorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorited = ref.watch(isVendorFavoritedProvider(vendorId));
    final isLoggedIn = ref.watch(authStateProvider).valueOrNull != null;

    return IconButton(
      onPressed: () {
        if (!isLoggedIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please login to save favorites')),
          );
          return;
        }
        ref.read(favoritesNotifierProvider.notifier).toggleFavorite(vendorId);
      },
      icon: Icon(
        isFavorited ? Icons.favorite : Icons.favorite_border,
        color: isFavorited ? Colors.red : AppColors.textHint,
      ),
    );
  }
}
```

**CustomerHome Navigation Update:**
- Added Favorites tab to bottom navigation
- Third tab after List and Map

---

### 3. Firestore Offline Persistence

**Implementation in main.dart:**

```dart
void main() async {
  // ... Firebase initialization ...

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // ...
}
```

**Benefits:**
- Automatic caching of Firestore data locally
- App works offline with cached data
- Pending writes queued and synced when online
- Unlimited cache size for comprehensive offline support

---

## Files Created/Modified

| File | Action | Description |
|------|--------|-------------|
| `pubspec.yaml` | Modified | Added Riverpod packages, flutter_launcher_icons config |
| `lib/providers/providers.dart` | Created | Centralized Riverpod providers |
| `lib/models/favorite.dart` | Created | Favorite data model |
| `lib/services/database_service.dart` | Modified | Added favorites CRUD operations |
| `lib/screens/customer/favorites_screen.dart` | Created | Favorites list UI |
| `lib/screens/customer/customer_home.dart` | Modified | Added Favorites tab, migrated to ConsumerStatefulWidget |
| `lib/screens/customer/vendor_list_screen.dart` | Modified | Added favorite button, migrated to ConsumerStatefulWidget |
| `lib/screens/auth/login_screen.dart` | Modified | Enhanced error message handling |
| `lib/main.dart` | Modified | Added ProviderScope, offline persistence, migrated to ConsumerWidget |
| `firestore.indexes.json` | Modified | Added vendor_profiles and favorites composite indexes |
| `firebase.json` | Modified | Added Firestore configuration for index deployment |

## Architecture Changes

### Before (Sprint 3)
- Global `ThemeService` instance
- Direct service instantiation in widgets
- StreamBuilder for auth state
- No centralized state management

### After (Sprint 4)
- Riverpod `ProviderScope` wrapping app
- Service access via providers
- `authStateProvider` StreamProvider
- Centralized providers for all services
- Reactive favorites state management

## Test Results

```bash
flutter analyze
# No issues found!

flutter test
# 67 tests passed!
```

## Firestore Collections

### New Collection: `favorites`

| Field | Type | Description |
|-------|------|-------------|
| `customerId` | string | User ID of customer |
| `vendorId` | string | Vendor profile ID |
| `createdAt` | timestamp | When favorited |

**Indexes Required:**
- Composite index on `customerId` + `createdAt` (descending)

---

## Bug Fixes (Post-Sprint)

### 1. Vendor List Query Index
**Issue:** "Something went wrong" error on vendor list screen when vendors are active.

**Root Cause:** The `getActiveVendorsPaginated` query combines `where('isActive', isEqualTo: true)` with `orderBy('locationUpdatedAt', descending: true)`, which requires a Firestore composite index.

**Fix:** Added composite index to `firestore.indexes.json`:
```json
{
  "collectionGroup": "vendor_profiles",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "isActive", "order": "ASCENDING" },
    { "fieldPath": "locationUpdatedAt", "order": "DESCENDING" }
  ]
}
```

### 2. Login Error Messages
**Issue:** Firebase auth errors displayed raw error strings to users.

**Fix:** Enhanced `_formatError()` in `login_screen.dart` to handle:
- `invalid-credential`
- `INVALID_LOGIN_CREDENTIALS`
- `credential is incorrect`
- `network-request-failed`

### 3. App Icon Configuration
**Issue:** App launcher icon showing default Flutter icon.

**Fix:** Added `flutter_launcher_icons` configuration to `pubspec.yaml`:
```yaml
flutter_launcher_icons:
  android: "ic_launcher"
  ios: true
  image_path: "assets/icon/app_icon.png"
  min_sdk_android: 21
  adaptive_icon_background: "#FF6B35"
  adaptive_icon_foreground: "assets/icon/app_icon.png"
```

---

## Updated Firestore Indexes

All indexes in `firestore.indexes.json`:

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
        { "fieldPath": "locationUpdatedAt", "order": "DESCENDING" }
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

**Deploy indexes with:**
```bash
firebase deploy --only firestore:indexes --project foodvendorapp2911
```

---

## Next Steps

Potential Sprint 5:
- Order system implementation
- Customer-vendor chat
- Vendor analytics dashboard
- Rating/review system
