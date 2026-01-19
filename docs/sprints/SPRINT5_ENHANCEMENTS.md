# Sprint 5: Feature Enhancements

**Date:** January 2026
**Status:** Complete

## Overview

This sprint implements five key feature enhancements to improve user experience, security, and app functionality.

## Features Implemented

### 1. Biometric Authentication

**Goal:** Add fingerprint/Face ID authentication as a security layer after login.

**Dependencies Added:**
```yaml
local_auth: ^2.3.0
```

**Files Created:**
- `lib/services/biometric_service.dart` - Device capability checks, authentication prompts
- `lib/screens/auth/biometric_prompt_screen.dart` - Biometric gate screen with animations

**Files Modified:**
- `lib/providers/providers.dart` - Added `BiometricState`, `BiometricNotifier`, `biometricServiceProvider`, `biometricProvider`
- `lib/main.dart` - Modified `AuthWrapper` to show biometric gate
- `lib/screens/auth/login_screen.dart` - Store credential flag after successful login
- `lib/screens/customer/customer_home.dart` - Added biometric toggle in menu
- `lib/screens/vendor/vendor_home.dart` - Added biometric toggle in menu
- `android/app/src/main/AndroidManifest.xml` - Added `USE_BIOMETRIC` permission

**Flow:**
1. User logs in with Firebase credentials
2. User enables biometric in settings (stored in SharedPreferences)
3. On next app launch, biometric prompt appears before home screen
4. User can authenticate or fall back to password

---

### 2. Menu Item Images

**Goal:** Allow vendors to upload images for menu items and display them to customers.

**No New Dependencies** - Uses existing `firebase_storage`, `image_picker`, `cached_network_image`

**Files Modified:**
- `lib/services/storage_service.dart` - Added `uploadMenuItemPhoto()` and `deleteMenuItemPhoto()`
- `lib/screens/vendor/menu_management_screen.dart` - Added image picker to form, preview display, upload on save
- `lib/screens/customer/vendor_detail_screen.dart` - Display menu item images in `_MenuItemCard`

**Storage Path:**
```
vendor_photos/{vendorId}/menu_items/{itemId}.jpg
```

---

### 3. Reviews & Ratings

**Goal:** Allow customers to rate and review vendors, display aggregate ratings.

**No New Dependencies** - Uses existing Firebase packages

**Files Created:**
- `lib/models/review.dart` - Review model with Firestore serialization
- `lib/widgets/common/star_rating.dart` - Reusable star display widget, `RatingBadge` component
- `lib/widgets/customer/review_form.dart` - Submit/edit review form
- `lib/widgets/customer/review_list.dart` - Paginated reviews display

**Files Modified:**
- `lib/models/vendor_profile.dart` - Added `averageRating`, `totalRatings` fields
- `lib/services/database_service.dart` - Added review CRUD operations:
  - `addReview()` - Creates review (one per customer per vendor)
  - `updateReview()` - Updates existing review
  - `deleteReview()` - Removes review
  - `getVendorReviewsStream()` - Real-time reviews list
  - `getUserReviewForVendor()` - Check if user already reviewed
  - `getUserReviewForVendorStream()` - Stream user's review
  - `_updateVendorRating()` - Recalculates average on changes
- `lib/providers/providers.dart` - Added `vendorReviewsProvider`, `userReviewProvider`, `ReviewNotifier`, `reviewNotifierProvider`
- `lib/screens/customer/vendor_detail_screen.dart` - Show rating in header, reviews section, add/edit review

**Firestore Structure:**
```
vendor_profiles/{vendorId}/reviews/{reviewId}
  - customerId: string
  - customerName: string
  - rating: number (1-5)
  - comment: string (optional)
  - createdAt: timestamp
```

---

### 4. Geohashing

**Goal:** Enable efficient proximity-based vendor queries using geohash encoding.

**Dependencies Added:**
```yaml
dart_geohash: ^2.0.0
```

**Files Created:**
- `lib/utils/geohash_utils.dart` - Utility class with:
  - `encode()` - Convert lat/lng to geohash
  - `decode()` - Convert geohash to lat/lng
  - `getNeighborsWithCenter()` - Get 9 geohash cells
  - `getQueryPrefixes()` - Generate search prefixes
  - `calculateDistance()` - Haversine distance calculation

**Files Modified:**
- `lib/models/vendor_profile.dart` - Added `geohash` field
- `lib/services/database_service.dart` - Updated methods:
  - `updateVendorLocation()` - Now computes and stores geohash automatically
  - `getVendorsNearLocation()` - Stream of vendors near a point using geohash queries
  - `getVendorsNearLocationExpanded()` - Expanded search across multiple cells
  - `backfillGeohashes()` - Migration method for existing vendors

**Geohash Precision:**
- Default precision 7: ~153m x 153m accuracy
- Query precision 5: ~5km search radius

---

### 5. Deep Link Sharing

**Goal:** Enable sharing vendor profiles via links that open directly in the app.

**Dependencies Added:**
```yaml
app_links: ^6.3.2
share_plus: ^10.1.4
```

**Files Created:**
- `lib/services/deep_link_service.dart` - Deep link handling:
  - `initialize()` - Setup link listeners
  - `_parseUri()` - Parse incoming URLs
  - `generateVendorLink()` - Create shareable URL
  - `shareVendor()` - Share via system sheet
  - `shareVendorWithLocation()` - Share with distance context

**Files Modified:**
- `lib/main.dart` - Changed `MyApp` to `ConsumerStatefulWidget`:
  - Added `_navigatorKey` for programmatic navigation
  - `_initDeepLinks()` - Initialize on startup
  - `_handleDeepLink()` - Route to appropriate screen
  - `_navigateToVendor()` - Open vendor detail from link
  - Listen to `pendingDeepLinkProvider` for deferred links
- `lib/providers/providers.dart` - Added:
  - `deepLinkServiceProvider`
  - `deepLinkStreamProvider`
  - `pendingDeepLinkProvider`
- `lib/screens/customer/vendor_detail_screen.dart` - Added share button in app bar
- `android/app/src/main/AndroidManifest.xml` - Added intent-filters:
  - Custom scheme: `foodfinder://vendor/{vendorId}`
  - HTTPS App Links: `https://foodfinder.app/vendor/{vendorId}`

**URL Patterns:**
```
Custom Scheme: foodfinder://vendor/{vendorId}
HTTPS:         https://foodfinder.app/vendor/{vendorId}
```

---

## Summary of Changes

### Dependencies Added to pubspec.yaml

```yaml
# Biometric Authentication
local_auth: ^2.3.0

# Geohashing
dart_geohash: ^2.0.0

# Deep Linking & Sharing
app_links: ^6.3.2
share_plus: ^10.1.4
```

### New Files Created

| Feature | Files |
|---------|-------|
| Biometric Auth | `biometric_service.dart`, `biometric_prompt_screen.dart` |
| Reviews | `review.dart`, `star_rating.dart`, `review_form.dart`, `review_list.dart` |
| Geohashing | `geohash_utils.dart` |
| Deep Links | `deep_link_service.dart` |

### Files Modified

| File | Features |
|------|----------|
| `pubspec.yaml` | All features |
| `lib/main.dart` | Biometric, Deep Links |
| `lib/providers/providers.dart` | Biometric, Reviews, Deep Links |
| `lib/services/storage_service.dart` | Menu Images |
| `lib/services/database_service.dart` | Reviews, Geohashing |
| `lib/models/vendor_profile.dart` | Reviews, Geohashing |
| `lib/screens/vendor/menu_management_screen.dart` | Menu Images |
| `lib/screens/customer/vendor_detail_screen.dart` | Menu Images, Reviews, Deep Links |
| `lib/screens/customer/customer_home.dart` | Biometric |
| `lib/screens/vendor/vendor_home.dart` | Biometric |
| `lib/screens/auth/login_screen.dart` | Biometric |
| `android/app/src/main/AndroidManifest.xml` | Biometric, Deep Links |

---

## Verification

### Biometric Auth
- Enable biometric in settings
- Close and reopen app
- Biometric prompt should appear

### Menu Item Images
- Vendor adds menu item with image
- Image uploads to Firebase Storage
- Image displays in customer vendor detail view

### Reviews & Ratings
- Customer submits review (1-5 stars + optional comment)
- Vendor average rating updates automatically
- Review appears in vendor detail screen
- Customer can edit/delete their own review

### Geohashing
- Vendor updates location
- Geohash is computed and stored automatically
- `getVendorsNearLocation()` returns nearby vendors

### Deep Link Sharing
- Tap share button on vendor detail
- Share sheet opens with link
- Opening link navigates to vendor detail screen

---

## Sprint 5.1: Additional Enhancements

**Date:** January 2026
**Status:** Complete

### 6. Vendor Phone Number & Call Functionality

**Goal:** Collect phone numbers from vendors during signup and allow customers to call vendors directly from the map.

**Dependencies Added:**
```yaml
url_launcher: ^6.2.6
```

**Files Modified:**

| File | Changes |
|------|---------|
| `lib/models/vendor_profile.dart` | Added `phoneNumber` field |
| `lib/screens/auth/signup_screen.dart` | Made phone number **required** for vendors (optional for customers) |
| `lib/services/auth_service.dart` | Store phone number in vendor profile during registration |
| `lib/widgets/customer/vendor_bottom_sheet.dart` | Added green call button with url_launcher integration |
| `pubspec.yaml` | Added `url_launcher: ^6.2.6` |

**Flow:**
1. Vendor registers → must provide phone number (required field)
2. Phone number stored in `vendor_profiles` collection
3. Customer taps vendor marker on map → bottom sheet shows
4. If vendor has phone number, green call button appears
5. Tapping call button opens device dialer with vendor's number

**Validation:**
- Uses `Validators.phoneRequired` for vendors
- Uses `Validators.phoneOptional` for customers
- Regex pattern: `^\+?[0-9]{10,15}$`

---

### 7. Real-time Vendor Movement with Smooth Animations

**Goal:** When vendors move in real-time, animate their marker positions smoothly on the customer's map instead of snapping.

**No New Dependencies**

**Files Created:**
- `lib/widgets/customer/animated_vendor_marker.dart` - Animation tracking system:
  - `VendorPositionTracker` - Tracks vendor positions and manages animation state
  - `VendorAnimationData` - Stores previous/target positions for interpolation
  - `AnimatedMarkerLayer` - Widget that rebuilds at 60fps during active animations

**Files Modified:**

| File | Changes |
|------|---------|
| `lib/screens/customer/map_screen.dart` | Added `SingleTickerProviderStateMixin`, `VendorPositionTracker`, wrapped markers in `AnimatedMarkerLayer` |

**Animation Details:**
- Duration: 800ms per position change
- Easing: `Curves.easeInOutCubic` for smooth acceleration/deceleration
- Frame rate: 60fps using Flutter `Ticker`
- Battery efficient: Ticker stops when no active animations

**How It Works:**
1. Firebase streams new vendor location via `getActiveVendorsWithFreshnessCheck()`
2. Position tracker detects position change for vendor
3. Stores previous position and starts animation
4. `AnimatedMarkerLayer` rebuilds at 60fps, interpolating lat/lng
5. Marker smoothly glides from old position to new position
6. Animation completes, ticker stops until next update

**Technical Implementation:**
```dart
// Position interpolation
final lat = previousPosition.latitude +
    (targetPosition.latitude - previousPosition.latitude) * easedProgress;
final lng = previousPosition.longitude +
    (targetPosition.longitude - previousPosition.longitude) * easedProgress;
```

---

## Updated Summary

### All Dependencies in pubspec.yaml

```yaml
# Biometric Authentication
local_auth: ^2.3.0

# Geohashing
dart_geohash: ^2.0.0

# Deep Linking & Sharing
app_links: ^6.3.2
share_plus: ^10.1.4

# URL Launcher (for phone dialer)
url_launcher: ^6.2.6
```

### All New Files Created

| Feature | Files |
|---------|-------|
| Biometric Auth | `biometric_service.dart`, `biometric_prompt_screen.dart` |
| Reviews | `review.dart`, `star_rating.dart`, `review_form.dart`, `review_list.dart` |
| Geohashing | `geohash_utils.dart` |
| Deep Links | `deep_link_service.dart` |
| Animated Markers | `animated_vendor_marker.dart` |

### Verification for New Features

### Phone Number & Call
- Register as vendor → phone number is required
- Customer views vendor on map → call button appears if phone available
- Tap call button → device dialer opens with vendor's number

### Real-time Animations
- Vendor goes online and moves location
- Customer watching map sees marker glide smoothly to new position
- No sudden "jumping" of markers
