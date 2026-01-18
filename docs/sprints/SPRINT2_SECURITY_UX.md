# Sprint 2: Core Security & UX

**Status:** Completed
**Duration:** Security hardening and user experience improvements

## Overview

Sprint 2 focused on securing the Firestore database with proper security rules, implementing vendor search functionality, and adding dark mode support.

## Completed Tasks

### 1. Firestore Security Rules

**Implementation:**
- Created comprehensive security rules for all collections
- Implemented role-based access control (vendor vs customer)
- Protected user data with ownership validation
- Secured vendor profiles with proper read/write permissions
- Added validation rules for data integrity

**Key File:** `firestore.rules`

**Security Rules Structure:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - only owner can read/write
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Vendor profiles - public read, owner write
    match /vendor_profiles/{vendorId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == vendorId;

      // Menu items subcollection
      match /menu_items/{itemId} {
        allow read: if true;
        allow write: if request.auth != null && request.auth.uid == vendorId;
      }
    }

    // Orders - vendor and customer access
    match /orders/{orderId} {
      allow read: if request.auth != null &&
        (resource.data.customerId == request.auth.uid ||
         resource.data.vendorId == request.auth.uid);
      allow create: if request.auth != null;
      allow update: if request.auth != null &&
        resource.data.vendorId == request.auth.uid;
    }

    // Favorites - owner only
    match /favorites/{favoriteId} {
      allow read, write: if request.auth != null &&
        resource.data.customerId == request.auth.uid;
      allow create: if request.auth != null &&
        request.resource.data.customerId == request.auth.uid;
    }
  }
}
```

---

### 2. Vendor Search

**Implementation:**
- Added search bar to vendor list screen
- Implemented Firestore range query for prefix matching
- Added flexible case-insensitive client-side filtering
- Searches both business name and cuisine tags

**Key Methods in DatabaseService:**

```dart
/// Search vendors by business name prefix
Stream<List<VendorProfile>> searchVendorsByName(String query) {
  final searchQuery = query.trim();
  final endQuery = '$searchQuery\uf8ff';

  return _firestore
      .collection('vendor_profiles')
      .where('isActive', isEqualTo: true)
      .where('businessName', isGreaterThanOrEqualTo: searchQuery)
      .where('businessName', isLessThan: endQuery)
      .limit(maxVendorsOnMap)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => VendorProfile.fromFirestore(doc))
          .toList());
}

/// Search vendors with flexible case-insensitive matching
Stream<List<VendorProfile>> searchVendorsFlexible(String query) {
  final searchLower = query.toLowerCase().trim();

  return getActiveVendorsWithFreshnessCheck().map((vendors) {
    return vendors.where((vendor) {
      if (vendor.businessName.toLowerCase().contains(searchLower)) {
        return true;
      }
      if (vendor.cuisineTags.any(
          (tag) => tag.toLowerCase().contains(searchLower))) {
        return true;
      }
      return false;
    }).toList();
  });
}
```

**UI Components:**
- Search TextField with hint "Search vendors or cuisines..."
- Clear button appears when search query is not empty
- Real-time filtering as user types

---

### 3. Dark Mode Support

**Implementation:**
- Created `ThemeService` class extending `ChangeNotifier`
- Persists theme preference using `SharedPreferences`
- Supports three modes: Light, Dark, System
- Toggle cycles through: System -> Light -> Dark -> System
- Created comprehensive `AppTheme` with light and dark variants

**Key File:** `lib/services/theme_service.dart`

```dart
class ThemeService extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeService() {
    _loadThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _themeModeToString(mode));
  }

  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : _themeMode == ThemeMode.dark
            ? ThemeMode.system
            : ThemeMode.light;
    await setThemeMode(newMode);
  }

  String get themeModeLabel; // Returns "Light", "Dark", or "System"
  IconData get themeModeIcon; // Returns appropriate icon
}
```

**Theme Configuration in AppTheme:**
- `AppTheme.lightTheme` - Light color scheme
- `AppTheme.darkTheme` - Dark color scheme
- Consistent primary colors across both themes
- Proper contrast ratios for accessibility

**Integration in main.dart:**
```dart
final themeService = ThemeService();

MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: themeService.themeMode,
  // ...
)
```

---

## Files Created/Modified

| File | Action | Description |
|------|--------|-------------|
| `firestore.rules` | Created | Comprehensive security rules |
| `lib/services/theme_service.dart` | Created | Theme management service |
| `lib/services/database_service.dart` | Modified | Added search methods |
| `lib/screens/customer/vendor_list_screen.dart` | Modified | Added search UI |
| `lib/theme/app_theme.dart` | Modified | Added dark theme support |
| `lib/main.dart` | Modified | Integrated theme service |

## Security Considerations

1. **Authentication Required:** All write operations require authentication
2. **Owner Validation:** Users can only modify their own data
3. **Public Read:** Vendor profiles and menus are publicly readable
4. **Data Validation:** Rules validate required fields and data types

## Testing

- Security rules tested via Firebase Emulator
- Theme persistence verified across app restarts
- Search functionality tested with various queries

## Next Steps

Sprint 3: Pagination, Push Notifications (FCM), Test Coverage
