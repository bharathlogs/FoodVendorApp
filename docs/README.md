# Food Finder App Documentation

## Overview

Food Finder is a Flutter application that connects customers with nearby food vendors in real-time. This documentation covers the complete development journey from initial setup through enhancement sprints.

## Documentation Structure

```
docs/
├── README.md                    # This file - documentation index
├── phases/                      # Original development phases (1-5)
│   ├── phase1/                  # Project setup, models, Firebase, auth
│   ├── phase2/                  # Location tracking, foreground service
│   ├── phase3/                  # Menu CRUD, customer views
│   ├── phase4/                  # Map integration, markers, filters
│   └── phase5/                  # Testing, optimization, release
├── sprints/                     # Enhancement sprints
│   ├── SPRINT1_QUICK_WINS.md    # Image caching, analytics, crashlytics, validation
│   ├── SPRINT2_SECURITY_UX.md   # Firestore rules, search, dark mode
│   ├── SPRINT3_PAGINATION_FCM_TESTING.md  # Pagination, push notifications, tests
│   └── SPRINT4_RIVERPOD_FAVORITES_OFFLINE.md  # Riverpod, favorites, offline sync
├── testing/                     # Testing documentation
│   ├── EMULATOR_LOCATION_TESTING_EXECUTION.md
│   └── PHASE1_LIVE_TESTING.md
├── ui-redesign/                 # UI/UX documentation
│   ├── README.md
│   ├── auth-screens.md
│   ├── page-transitions.md
│   ├── pull-to-refresh.md
│   └── splash-screen.md
├── bugs.md                      # Bug tracking
├── end-to-end-test-script.md    # E2E test procedures
├── test-results.md              # Test execution results
└── ui-polish-checklist.md       # UI polish items
```

---

## Development Phases

### Phase 1: Foundation
**Status:** Complete

- Flutter project initialization
- Data models (User, Vendor, MenuItem, Order)
- Firebase configuration (Auth, Firestore, Storage)
- User authentication (email/password)
- DatabaseService for Firestore operations

[View Phase 1 Documentation](./phases/phase1/README.md)

### Phase 2: Vendor Location Tracking
**Status:** Complete

- Location permissions handling
- Android foreground service for background location
- Location manager with periodic updates
- Offline queue for location data
- Vendor active/inactive toggle
- Timeout detection for stale vendors

[View Phase 2 Documentation](./phases/phase2/README.md)

### Phase 3: Menu Management
**Status:** Complete

- Vendor menu CRUD operations
- Menu item form with validation
- Customer menu viewing interface
- 50 item limit per vendor

[View Phase 3 Documentation](./phases/phase3/README.md)

### Phase 4: Map Integration
**Status:** Complete

- flutter_map integration
- Customer location display
- Vendor markers on map
- Distance calculation
- Vendor detail bottom sheet
- Cuisine filter chips

[View Phase 4 Documentation](./phases/phase4/README.md)

### Phase 5: Polish & Release
**Status:** Complete

- End-to-end testing
- Network edge case handling
- Bug fixes
- Performance optimization
- App icon and branding
- Release APK build
- Pre-launch checklist

[View Phase 5 Documentation](./phases/phase5/README.md)

---

## Enhancement Sprints

### Sprint 1: Quick Wins
**Status:** Complete

- Image caching with `cached_network_image`
- Firebase Analytics integration
- Firebase Crashlytics error tracking
- Input validation with XSS protection

[View Sprint 1 Documentation](./sprints/SPRINT1_QUICK_WINS.md)

### Sprint 2: Security & UX
**Status:** Complete

- Firestore security rules
- Vendor search (name + cuisine)
- Dark mode support with persistence

[View Sprint 2 Documentation](./sprints/SPRINT2_SECURITY_UX.md)

### Sprint 3: Pagination, FCM & Testing
**Status:** Complete

- Cursor-based Firestore pagination
- Firebase Cloud Messaging setup
- 67 unit/widget tests

[View Sprint 3 Documentation](./sprints/SPRINT3_PAGINATION_FCM_TESTING.md)

### Sprint 4: Riverpod, Favorites & Offline
**Status:** Complete

- State management migration to Riverpod
- Customer favorites feature
- Firestore offline persistence

[View Sprint 4 Documentation](./sprints/SPRINT4_RIVERPOD_FAVORITES_OFFLINE.md)

---

## Key Technical Decisions

| Area | Technology | Rationale |
|------|------------|-----------|
| Framework | Flutter 3.10+ | Cross-platform, single codebase |
| Backend | Firebase | Real-time sync, serverless |
| State Management | Riverpod | Compile-safe, testable |
| Maps | flutter_map + OpenStreetMap | Free, no API key required |
| Location | Geolocator + Foreground Task | Battery-efficient background tracking |
| Image Caching | cached_network_image | Disk + memory caching |
| Notifications | Firebase Cloud Messaging | Cross-platform push |

---

## Quick Reference

### Run Tests
```bash
flutter test
```

### Run Analyzer
```bash
flutter analyze
```

### Build Release APK
```bash
flutter build apk --release
```

### Generate App Icons
```bash
dart run flutter_launcher_icons
```

### Deploy Firestore Indexes
```bash
firebase deploy --only firestore:indexes --project foodvendorapp2911
```

### Project Dependencies
See [pubspec.yaml](../pubspec.yaml) for complete dependency list.

---

## Firestore Indexes

Required composite indexes (defined in `firestore.indexes.json`):

| Collection | Fields | Purpose |
|------------|--------|---------|
| `orders` | `vendorId` (ASC), `createdAt` (DESC) | Vendor order queries |
| `vendor_profiles` | `isActive` (ASC), `cuisineTags` (CONTAINS) | Cuisine filter queries |
| `vendor_profiles` | `isActive` (ASC), `locationUpdatedAt` (DESC) | Paginated vendor list |
| `favorites` | `customerId` (ASC), `createdAt` (DESC) | Customer favorites queries |

---

## Architecture Overview

```
lib/
├── main.dart                 # App entry point with ProviderScope
├── core/
│   └── navigation/           # Page routes and transitions
├── models/                   # Data models
│   ├── user_model.dart
│   ├── vendor_profile.dart
│   ├── menu_item.dart
│   ├── order.dart
│   ├── favorite.dart
│   └── location_data.dart
├── providers/                # Riverpod providers
│   └── providers.dart        # All app providers
├── services/                 # Business logic
│   ├── auth_service.dart
│   ├── database_service.dart
│   ├── analytics_service.dart
│   ├── notification_service.dart
│   ├── theme_service.dart
│   └── location_foreground_service.dart
├── screens/                  # UI screens
│   ├── auth/
│   ├── customer/
│   ├── vendor/
│   └── splash/
├── widgets/                  # Reusable components
├── theme/                    # App theming
│   └── app_theme.dart
└── utils/                    # Utilities
    └── validators.dart
```

---

## Contributing

1. Follow existing code style and patterns
2. Add tests for new features
3. Update documentation for significant changes
4. Run `flutter analyze` before committing
