# Food Finder

A mobile app for discovering nearby food vendors in real-time.

## Features

### For Vendors
- Create account and manage profile
- Set cuisine types (Indian, Chinese, Mexican, etc.)
- Manage menu items (add, edit, delete, toggle availability)
- Go online/offline with live location sharing
- Background location updates with battery optimization
- Offline queue for location updates when network unavailable

### For Customers
- Browse vendors on interactive map (no login required)
- Filter by cuisine type
- View vendor menus and prices
- See distance and estimated walking time
- Real-time vendor location updates

## Tech Stack

- **Framework**: Flutter 3.10+
- **Authentication**: Firebase Auth (Email/Password)
- **Database**: Cloud Firestore (real-time sync)
- **Storage**: Firebase Storage (vendor photos)
- **Maps**: flutter_map + OpenStreetMap (free, no API key)
- **Location**: Geolocator + Flutter Foreground Task

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
│   ├── location_data.dart    # Location data model
│   └── order.dart            # Order model (future)
├── screens/                  # UI screens
│   ├── auth/                 # Login, Signup
│   ├── vendor/               # Vendor dashboard, menu management
│   └── customer/             # Map view, vendor details
├── services/                 # Business logic
│   ├── auth_service.dart     # Firebase Auth wrapper
│   ├── database_service.dart # Firestore operations
│   ├── location_manager.dart # Location broadcasting
│   └── permission_service.dart # Permission handling
├── widgets/                  # Reusable components
└── utils/                    # Helpers and constants
```

## Firebase Collections

```
users/
  {userId}/
    - email: string
    - role: "vendor" | "customer"
    - createdAt: timestamp

vendorProfiles/
  {vendorId}/
    - businessName: string
    - cuisineTypes: string[]
    - isActive: boolean
    - latitude: number
    - longitude: number
    - lastUpdated: timestamp

menuItems/
  {menuItemId}/
    - vendorId: string
    - name: string
    - price: number
    - isAvailable: boolean
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
- No push notifications
- No image upload for menu items (vendor photo only)
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
