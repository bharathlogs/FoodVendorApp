# Food Finder

A mobile app for discovering nearby food vendors in real-time.

## Features

### For Vendors
- Create account and manage profile
- Set cuisine types (Indian, Chinese, Mexican, etc.)
- Manage menu items with images (add, edit, delete, toggle availability)
- Go online/offline with live location sharing
- Background location updates with battery optimization
- Offline queue for location updates when network unavailable

### For Customers
- Browse vendors on interactive map (no login required)
- Filter by cuisine type
- View vendor menus with images and prices
- See distance and estimated walking time
- Real-time vendor location updates
- Rate and review vendors (1-5 stars + comments)
- Save favorite vendors
- Share vendor profiles via deep links

### Security & UX
- Biometric authentication (fingerprint/Face ID)
- Dark mode support
- Offline data persistence

## Tech Stack

- **Framework**: Flutter 3.10+
- **State Management**: Riverpod
- **Authentication**: Firebase Auth (Email/Password) + Biometric (local_auth)
- **Database**: Cloud Firestore (real-time sync, offline persistence)
- **Storage**: Firebase Storage (vendor/menu photos)
- **Maps**: flutter_map + OpenStreetMap (free, no API key)
- **Location**: Geolocator + Flutter Foreground Task + Geohashing
- **Analytics**: Firebase Analytics + Crashlytics
- **Deep Links**: app_links + share_plus

## Setup

### Prerequisites
- Flutter SDK 3.10+
- Android Studio with Android SDK
- Firebase project

### Installation

1. Clone the repository
   ```bash
   git clone <repository-url>
   cd FoodVendorApp
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Firebase Setup
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable Email/Password authentication
   - Create Firestore database (recommended: asia-south1)
   - Download `google-services.json` and place in `android/app/`
   - Run FlutterFire CLI:
     ```bash
     flutterfire configure
     ```

4. Run the app
   ```bash
   flutter run
   ```

### Release Build

1. Create a keystore (if not exists):
   ```bash
   keytool -genkey -v -keystore ~/food-vendor-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias food-vendor
   ```

2. Create `android/key.properties`:
   ```properties
   storePassword=<your-password>
   keyPassword=<your-password>
   keyAlias=food-vendor
   storeFile=/path/to/food-vendor-key.jks
   ```

3. Build release APK:
   ```bash
   flutter build apk --release
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user_model.dart       # User authentication model
│   ├── vendor_profile.dart   # Vendor profile model
│   ├── menu_item.dart        # Menu item model
│   ├── review.dart           # Review model
│   ├── favorite.dart         # Favorite model
│   └── location_data.dart    # Location data model
├── screens/                  # UI screens
│   ├── auth/                 # Login, Signup, Biometric prompt
│   ├── vendor/               # Vendor dashboard, menu management
│   └── customer/             # Map view, vendor details, favorites
├── services/                 # Business logic
│   ├── auth_service.dart     # Firebase Auth wrapper
│   ├── database_service.dart # Firestore operations
│   ├── biometric_service.dart # Biometric authentication
│   ├── deep_link_service.dart # Deep link handling
│   ├── storage_service.dart  # Firebase Storage operations
│   ├── location_manager.dart # Location broadcasting
│   └── permission_service.dart # Permission handling
├── providers/                # Riverpod state management
│   └── providers.dart        # All app providers
├── widgets/                  # Reusable components
│   ├── common/               # Shared widgets (star_rating, etc.)
│   ├── customer/             # Customer-specific (review_form, etc.)
│   └── vendor/               # Vendor-specific widgets
└── utils/                    # Helpers and constants
    ├── geohash_utils.dart    # Geohash encoding/decoding
    └── validators.dart       # Input validation
```

## Firebase Collections

```
users/
  {userId}/
    - email: string
    - displayName: string
    - role: "vendor" | "customer"
    - createdAt: timestamp

vendor_profiles/
  {vendorId}/
    - businessName: string
    - description: string
    - cuisineTags: string[]
    - isActive: boolean
    - location: GeoPoint
    - locationUpdatedAt: timestamp
    - geohash: string
    - averageRating: number
    - totalRatings: number
    - profileImageUrl: string

    menu_items/ (subcollection)
      {itemId}/
        - name: string
        - description: string
        - price: number
        - isAvailable: boolean
        - imageUrl: string
        - createdAt: timestamp

    reviews/ (subcollection)
      {reviewId}/
        - customerId: string
        - customerName: string
        - rating: number (1-5)
        - comment: string
        - createdAt: timestamp

favorites/
  {favoriteId}/
    - customerId: string
    - vendorId: string
    - createdAt: timestamp
```

## Testing

Run unit tests:
```bash
flutter test
```

See `docs/end-to-end-test-script.md` for manual test scenarios.

## Known Limitations

- Android only (iOS support can be added with minor changes)
- No payment integration
- No order system (view only)
- Maximum 50 menu items per vendor
- 10-minute location timeout (auto-offline)
- 50 vendor limit per map query

## Security Notes

The following files contain sensitive data and are excluded from git:
- `google-services.json` - Firebase configuration
- `lib/firebase_options.dart` - Firebase options
- `android/key.properties` - Release signing credentials
- `*.jks` / `*.keystore` - Keystore files

**Important**: Back up your keystore file securely. If lost, you cannot update your app on Play Store.

## License

[Your License]
