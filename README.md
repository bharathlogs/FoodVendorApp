# Food Finder

![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?style=flat&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=flat&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Backend-FFCA28?style=flat&logo=firebase&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?style=flat&logo=android&logoColor=white)

A real-time mobile application for discovering nearby food vendors. Connect hungry customers with local food vendors through an interactive map interface with live location tracking.

---

## Table of Contents

- [Overview](#overview)
- [Screenshots](#screenshots)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Firebase Setup](#firebase-setup)
  - [Running the App](#running-the-app)
- [Project Structure](#project-structure)
- [Firebase Schema](#firebase-schema)
- [Building for Release](#building-for-release)
- [Testing](#testing)
- [Known Limitations](#known-limitations)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [Security](#security)
- [License](#license)

---

## Overview

**Food Finder** bridges the gap between street food vendors and customers. Vendors can broadcast their live location while customers discover nearby food options on an interactive map - no login required to browse!

### Why Food Finder?

- **For Vendors**: Increase visibility, manage menus, and reach more customers without expensive storefronts
- **For Customers**: Discover hidden food gems, see real-time availability, and never miss your favorite vendor

---

## Screenshots

| Map View | Vendor Profile | Menu Management |
|:--------:|:--------------:|:---------------:|
| ![Map](assets/screenshots/map_view.png) | ![Profile](assets/screenshots/vendor_profile.png) | ![Menu](assets/screenshots/menu_management.png) |

> **Note**: Add your screenshots to `assets/screenshots/` directory

---

## Features

### For Vendors

- Create account and manage vendor profile
- Set cuisine types (Indian, Chinese, Mexican, Italian, etc.)
- Manage menu items with images (add, edit, delete, toggle availability)
- Go online/offline with live location sharing
- Background location updates with battery optimization
- Offline queue for location updates when network unavailable
- Phone number contact integration
- View ratings and reviews from customers

### For Customers

- Browse vendors on interactive map (no login required)
- Filter by cuisine type
- View vendor menus with images and prices
- See distance and estimated walking time
- Real-time vendor location updates
- Rate and review vendors (1-5 stars + comments)
- Save favorite vendors
- Share vendor profiles via deep links
- Quick-dial vendor phone numbers

### Security & UX

- Biometric authentication (Fingerprint/Face ID)
- Dual-role authentication (Vendor/Customer)
- Dark mode support with theme toggle
- Offline data persistence
- Smooth page transitions and animations

---

## Tech Stack

| Category | Technology |
|----------|------------|
| **Framework** | Flutter 3.10+ |
| **Language** | Dart 3.0+ |
| **State Management** | Riverpod |
| **Authentication** | Firebase Auth (Email/Password + Google Sign-In) + Biometric (local_auth) |
| **Database** | Cloud Firestore (real-time sync, offline persistence) |
| **Storage** | Firebase Storage (vendor/menu photos) |
| **Maps** | flutter_map + OpenStreetMap (free, no API key) |
| **Location** | Geolocator + Flutter Foreground Task + Geohashing |
| **Analytics** | Firebase Analytics + Crashlytics |
| **Push Notifications** | Firebase Cloud Messaging (FCM) |
| **Deep Links** | app_links + share_plus |

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.10 or higher
- [Android Studio](https://developer.android.com/studio) with Android SDK
- A [Firebase](https://firebase.google.com/) project
- Git

Verify your Flutter installation:

```bash
flutter doctor
```

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/FoodVendorApp.git
   cd FoodVendorApp
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Generate code** (for Riverpod providers)

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

### Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)

2. **Enable services:**
   - Authentication → Email/Password & Google Sign-In
   - Firestore Database (recommended region: `asia-south1`)
   - Storage
   - Analytics
   - Crashlytics
   - Cloud Messaging

3. **Download configuration:**
   - Download `google-services.json` from Firebase Console
   - Place it in `android/app/`

4. **Configure FlutterFire:**

   ```bash
   # Install FlutterFire CLI (if not installed)
   dart pub global activate flutterfire_cli

   # Configure Firebase
   flutterfire configure
   ```

5. **Deploy Firestore rules and indexes:**

   ```bash
   firebase deploy --only firestore:rules,firestore:indexes
   ```

### Running the App

```bash
# Debug mode
flutter run

# Release mode
flutter run --release
```

---

## Project Structure

```
lib/
├── main.dart                        # App entry point
├── models/                          # Data models
│   ├── user_model.dart              # User authentication model
│   ├── vendor_profile.dart          # Vendor profile model
│   ├── menu_item.dart               # Menu item model
│   ├── review.dart                  # Review model
│   ├── favorite.dart                # Favorite model
│   └── location_data.dart           # Location data model
├── screens/                         # UI screens
│   ├── auth/                        # Login, Signup, Biometric prompt
│   ├── vendor/                      # Vendor dashboard, menu management
│   ├── customer/                    # Map view, vendor details, favorites
│   └── splash/                      # App initialization
├── services/                        # Business logic
│   ├── auth_service.dart            # Firebase Auth wrapper
│   ├── database_service.dart        # Firestore operations
│   ├── biometric_service.dart       # Biometric authentication
│   ├── deep_link_service.dart       # Deep link handling
│   ├── storage_service.dart         # Firebase Storage operations
│   ├── location_manager.dart        # Location broadcasting
│   ├── notification_service.dart    # Push notifications
│   ├── analytics_service.dart       # Event tracking
│   ├── theme_service.dart           # Theme management
│   └── permission_service.dart      # Permission handling
├── providers/                       # Riverpod state management
│   └── providers.dart               # All app providers
├── widgets/                         # Reusable components
│   ├── common/                      # Shared widgets (star_rating, etc.)
│   ├── customer/                    # Customer-specific widgets
│   └── vendor/                      # Vendor-specific widgets
├── theme/                           # App theming
│   └── app_theme.dart               # Light/dark theme definitions
├── core/navigation/                 # Navigation utilities
│   └── app_transitions.dart         # Page transition animations
└── utils/                           # Helpers and constants
    ├── geohash_utils.dart           # Geohash encoding/decoding
    ├── distance_formatter.dart      # Distance formatting
    ├── validators.dart              # Input validation
    └── cuisine_categories.dart      # Cuisine type definitions
```

---

## Firebase Schema

### Collections Structure

```
users/
└── {userId}/
    ├── email: string
    ├── displayName: string
    ├── role: "vendor" | "customer"
    ├── phoneNumber: string?
    └── createdAt: timestamp

vendor_profiles/
└── {vendorId}/
    ├── businessName: string
    ├── description: string
    ├── cuisineTags: string[]
    ├── isActive: boolean
    ├── location: GeoPoint
    ├── locationUpdatedAt: timestamp
    ├── geohash: string
    ├── averageRating: number
    ├── totalRatings: number
    ├── profileImageUrl: string
    ├── phoneNumber: string?
    │
    ├── menu_items/ (subcollection)
    │   └── {itemId}/
    │       ├── name: string
    │       ├── description: string
    │       ├── price: number
    │       ├── isAvailable: boolean
    │       ├── imageUrl: string
    │       └── createdAt: timestamp
    │
    └── reviews/ (subcollection)
        └── {reviewId}/
            ├── customerId: string
            ├── customerName: string
            ├── rating: number (1-5)
            ├── comment: string
            └── createdAt: timestamp

favorites/
└── {favoriteId}/
    ├── customerId: string
    ├── vendorId: string
    └── createdAt: timestamp
```

---

## Building for Release

### 1. Create a Keystore

```bash
keytool -genkey -v -keystore ~/food-vendor-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias food-vendor
```

### 2. Configure Signing

Create `android/key.properties`:

```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=food-vendor
storeFile=/path/to/food-vendor-key.jks
```

### 3. Build APK

```bash
# Build APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

---

## Testing

### Unit Tests

```bash
flutter test
```

### Integration Tests

```bash
flutter test integration_test/
```

### Test Coverage

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

See `docs/end-to-end-test-script.md` for manual test scenarios.

---

## Known Limitations

| Limitation | Description |
|------------|-------------|
| **Platform** | Android only (iOS support planned) |
| **Payments** | No payment integration |
| **Orders** | View-only (no ordering system) |
| **Menu Items** | Maximum 50 items per vendor |
| **Location Timeout** | 10-minute inactivity = auto-offline |
| **Map Query Limit** | 50 vendors per query |
| **Review Rate Limit** | 5 reviews per hour per user |

---

## Roadmap

- [ ] iOS support
- [ ] Order placement system
- [ ] Payment integration (Stripe/Razorpay)
- [ ] Push notifications for nearby vendors
- [ ] Vendor analytics dashboard
- [ ] Multi-language support
- [ ] Scheduled operating hours
- [ ] Vendor subscription tiers

---

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Run `flutter analyze` before committing
- Ensure all tests pass with `flutter test`

---

## Security

### Sensitive Files (excluded from git)

| File | Purpose |
|------|---------|
| `google-services.json` | Firebase configuration |
| `lib/firebase_options.dart` | Firebase options |
| `android/key.properties` | Release signing credentials |
| `*.jks` / `*.keystore` | Keystore files |

> **Important**: Back up your keystore file securely. If lost, you cannot update your app on Play Store.

### Reporting Security Issues

Please report security vulnerabilities via email to [your-email@example.com] rather than public issues.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- [Flutter](https://flutter.dev/) - UI framework
- [Firebase](https://firebase.google.com/) - Backend services
- [OpenStreetMap](https://www.openstreetmap.org/) - Map tiles
- [Riverpod](https://riverpod.dev/) - State management

---

<p align="center">
  Made with Flutter
</p>
