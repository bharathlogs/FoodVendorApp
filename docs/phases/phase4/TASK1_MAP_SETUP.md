# Task 1: Map Setup with OpenStreetMap

## Status: Complete

## Overview
Integrate OpenStreetMap using flutter_map package for displaying the map view with vendor markers, customer location, and cuisine filtering.

---

## Dependencies Added

```yaml
# pubspec.yaml
dependencies:
  flutter_map: ^8.2.2
  latlong2: ^0.9.1
  # geolocator already installed from Phase 2
```

---

## Files Created

### 1. `lib/utils/cuisine_categories.dart`
Predefined cuisine categories for vendor tagging and filtering.

```dart
const List<String> cuisineCategories = [
  'South Indian',
  'North Indian',
  'Chinese',
  'Street Food',
  'Biryani',
  'Chaat',
  'Snacks',
  'Beverages',
  'Desserts',
  'Fast Food',
  'Momos',
  'Rolls',
  'Dosa',
  'Idli',
  'Pav Bhaji',
  'Vada Pav',
  'Samosa',
  'Juice',
  'Tea/Coffee',
  'Ice Cream',
];
```

### 2. `lib/services/customer_location_service.dart`
Customer location handling with permission dialogs and Haversine distance calculation.

**Key Methods:**
```dart
class CustomerLocationService {
  /// Get customer's current location with permission handling
  Future<Position?> getCurrentLocation(BuildContext context);

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in kilometers
  double calculateDistance(double lat1, double lon1, double lat2, double lon2);

  /// Format distance for display (e.g., "500 m" or "2.3 km")
  String formatDistance(double distanceKm);
}
```

### 3. `lib/screens/customer/map_screen.dart`
Main map screen with OpenStreetMap integration.

**Features:**
- OpenStreetMap tile layer (free, no API key required)
- Customer location marker (blue circle)
- Vendor markers (orange storefront icons)
- Cuisine filter chips (horizontal scrollable)
- Real-time vendor updates via Firestore stream
- Tap vendor marker to show bottom sheet

**Key Code:**
```dart
class MapScreen extends StatefulWidget {
  // ...
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final DatabaseService _databaseService = DatabaseService();
  final CustomerLocationService _locationService = CustomerLocationService();

  LatLng? _customerLocation;
  final Set<String> _selectedCuisines = {};

  // Default center (Bangalore, India)
  static const LatLng _defaultCenter = LatLng(12.9716, 77.5946);

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _customerLocation ?? _defaultCenter,
        initialZoom: 14.0,
        minZoom: 10.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.yourcompany.food_vendor_app',
        ),
        // Customer marker layer
        // Vendor markers layer
      ],
    );
  }
}
```

### 4. `lib/widgets/customer/vendor_bottom_sheet.dart`
Bottom sheet widget for vendor preview when marker is tapped.

**Features:**
- Vendor avatar with profile image
- Business name with "Open" badge
- Distance display (if available)
- Description (max 3 lines)
- Cuisine tags
- "View Menu" button

```dart
class VendorBottomSheet extends StatelessWidget {
  final VendorProfile vendor;
  final double? distanceKm;
  final VoidCallback onViewMenu;

  const VendorBottomSheet({
    super.key,
    required this.vendor,
    this.distanceKm,
    required this.onViewMenu,
  });
}
```

### 5. `lib/screens/customer/vendor_detail_screen.dart`
Enhanced vendor detail screen with distance display.

**Features:**
- Vendor header with profile image
- Distance badge (blue)
- Cuisine tags (scrollable)
- Menu items list (available items only)
- Bottom bar with walking distance

---

## Files Modified

### 1. `lib/screens/customer/customer_home.dart`
Added bottom navigation with List/Map tabs.

**Before:**
```dart
class CustomerHome extends StatelessWidget {
  // Single VendorListScreen in body
}
```

**After:**
```dart
class CustomerHome extends StatefulWidget {
  // ...
}

class _CustomerHomeState extends State<CustomerHome> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          VendorListScreen(),
          MapScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list), label: 'List'),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
        ],
      ),
    );
  }
}
```

---

## Features Implemented

### 1. OpenStreetMap Integration
- Free tile layer with no usage limits
- Zoom range: 10-18
- Default center: Bangalore (12.9716, 77.5946)
- User agent package name configured

### 2. Customer Location
- GPS permission handling with rationale dialogs
- Location service check with settings redirect
- Current position with high accuracy
- Blue circular marker with person icon

### 3. Vendor Markers
- Orange circular markers with storefront icon
- Real-time updates via `getActiveVendorsWithFreshnessCheck()`
- Only shows vendors with valid GeoPoint location
- Tap to show vendor bottom sheet

### 4. Cuisine Filtering
- Horizontal scrollable filter chips
- Multi-select filtering
- "Clear All" button when filters active
- Active filter count badge
- Filters applied client-side for performance

### 5. Distance Calculation
- Haversine formula for accurate great-circle distance
- Formatted output: meters (< 1km) or kilometers (>= 1km)
- Displayed in bottom sheet and detail screen

### 6. Navigation Integration
- Bottom navigation bar with List/Map tabs
- IndexedStack preserves state when switching tabs
- Dynamic app bar title based on selected tab

---

## Haversine Formula Implementation

```dart
double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371; // Earth's radius in km

  final double dLat = _toRadians(lat2 - lat1);
  final double dLon = _toRadians(lon2 - lon1);

  final double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) *
          cos(_toRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);

  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadius * c;
}
```

---

## Testing Checklist

- [x] Map displays with OpenStreetMap tiles
- [x] Map is zoomable and pannable
- [x] Default center is set to Bangalore
- [x] Customer location marker shows (blue)
- [x] Vendor markers show (orange)
- [x] Cuisine filter chips are scrollable
- [x] Filters correctly hide/show vendors
- [x] Tap vendor marker shows bottom sheet
- [x] Distance displays in bottom sheet
- [x] "View Menu" navigates to detail screen
- [x] "My Location" FAB centers map on customer
- [x] Bottom navigation switches between List/Map
- [x] State preserved when switching tabs

---

## UI Components

### Map Screen Layout
```
┌─────────────────────────────────┐
│ [Filter Chips - Horizontal Scroll] │
├─────────────────────────────────┤
│                                 │
│       OpenStreetMap             │
│                                 │
│    🔵 Customer                  │
│                                 │
│         🟠 Vendor 1             │
│                   🟠 Vendor 2   │
│                                 │
│                         [📍]    │  ← FAB: My Location
└─────────────────────────────────┘
```

### Vendor Bottom Sheet
```
┌─────────────────────────────────┐
│           ═══════               │  ← Drag handle
│                                 │
│  [Avatar]  Business Name  [Open]│
│            📍 1.2 km            │
│                                 │
│  Description text here...       │
│                                 │
│  [South Indian] [Street Food]   │
│                                 │
│  ┌─────────────────────────┐    │
│  │   🍽️  View Menu         │    │
│  └─────────────────────────┘    │
└─────────────────────────────────┘
```

---

## API Reference

### CustomerLocationService

| Method | Returns | Description |
|--------|---------|-------------|
| `getCurrentLocation(context)` | `Future<Position?>` | Get GPS location with permissions |
| `calculateDistance(lat1, lon1, lat2, lon2)` | `double` | Haversine distance in km |
| `formatDistance(distanceKm)` | `String` | "500 m" or "2.3 km" |

### Cuisine Categories

20 predefined categories suitable for Indian food vendors:
- South Indian, North Indian, Chinese, Street Food
- Biryani, Chaat, Snacks, Beverages, Desserts
- Fast Food, Momos, Rolls, Dosa, Idli
- Pav Bhaji, Vada Pav, Samosa, Juice, Tea/Coffee, Ice Cream

---

## Common Pitfalls Avoided

| Pitfall | Solution |
|---------|----------|
| Tiles not loading | `userAgentPackageName` configured |
| Map blank on first load | `_defaultCenter` set as fallback |
| Location permission denied | Rationale dialogs before request |
| Stale vendor data | Using `getActiveVendorsWithFreshnessCheck()` |
| Performance with many vendors | Client-side filtering, MarkerLayer |
