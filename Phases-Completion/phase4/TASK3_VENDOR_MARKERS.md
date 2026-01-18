# Task 3: Display Vendor Markers

## Status: Complete (Implemented in Task 1)

## Overview
Display active vendor locations as markers on the OpenStreetMap, with real-time updates from Firestore.

---

## Implementation

### Location: `lib/screens/customer/map_screen.dart`

### Method: `_buildVendorMarkers()`

```dart
Widget _buildVendorMarkers() {
  return StreamBuilder<List<VendorProfile>>(
    stream: _databaseService.getActiveVendorsWithFreshnessCheck(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const MarkerLayer(markers: []);
      }

      List<VendorProfile> vendors = snapshot.data!;

      // Apply cuisine filter
      if (_selectedCuisines.isNotEmpty) {
        vendors = vendors.where((vendor) {
          return vendor.cuisineTags.any(
            (tag) => _selectedCuisines.contains(tag),
          );
        }).toList();
      }

      // Filter vendors with valid location
      vendors = vendors.where((v) => v.location != null).toList();

      final markers = vendors.map((vendor) {
        return Marker(
          point: LatLng(
            vendor.location!.latitude,
            vendor.location!.longitude,
          ),
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () => _showVendorBottomSheet(vendor),
            child: _buildVendorMarkerIcon(),
          ),
        );
      }).toList();

      return MarkerLayer(markers: markers);
    },
  );
}
```

---

## Features

### 1. Real-time Updates
- Uses `StreamBuilder` with Firestore stream
- Vendors appear/disappear as they go online/offline
- No manual refresh needed

### 2. Freshness Check
- Uses `getActiveVendorsWithFreshnessCheck()` from DatabaseService
- Only shows vendors who updated location within last 10 minutes
- Prevents stale vendor locations on map

### 3. Location Validation
- Filters out vendors with `null` location
- Prevents map errors from invalid coordinates

### 4. Cuisine Filtering
- Client-side filtering for performance
- Integrates with filter chip selection
- Updates markers instantly when filters change

---

## Marker Design

### Vendor Marker (Orange)
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.orange,
    shape: BoxShape.circle,
    border: Border.all(color: Colors.white, width: 2),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: const Icon(
    Icons.storefront,
    color: Colors.white,
    size: 24,
  ),
)
```

### Customer Marker (Blue)
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.blue,
    shape: BoxShape.circle,
    border: Border.all(color: Colors.white, width: 3),
    boxShadow: [
      BoxShadow(
        color: Colors.blue.withValues(alpha: 0.3),
        blurRadius: 10,
        spreadRadius: 3,
      ),
    ],
  ),
  child: const Icon(
    Icons.person,
    color: Colors.white,
    size: 20,
  ),
)
```

---

## Visual Distinction

| Marker | Color | Icon | Size | Purpose |
|--------|-------|------|------|---------|
| Customer | Blue | `person` | 40x40 | "You are here" |
| Vendor | Orange | `storefront` | 50x50 | Food stall location |

---

## Data Flow

```
Firestore (vendor_profiles)
         │
         ▼
getActiveVendorsWithFreshnessCheck()
         │
         ▼
StreamBuilder in MapScreen
         │
         ├── Apply cuisine filters (if any)
         │
         ├── Filter vendors with valid location
         │
         └── Map to Marker widgets
                  │
                  └── Render in MarkerLayer
```

---

## Interaction

### Tap on Vendor Marker
```dart
GestureDetector(
  onTap: () => _showVendorBottomSheet(vendor),
  child: _buildVendorMarkerIcon(),
)
```

- Opens bottom sheet with vendor preview
- Shows distance if customer location available
- "View Menu" button for navigation

---

## Testing Checklist

- [x] Vendor markers appear on map
- [x] Only active/online vendors shown
- [x] Markers update in real-time
- [x] Vendors without location are filtered out
- [x] Cuisine filters affect visible markers
- [x] Tap on marker shows bottom sheet
- [x] Marker icons are visually distinct (orange vs blue)
- [x] Shadow provides depth perception

---

## Performance Considerations

| Aspect | Implementation |
|--------|----------------|
| Rendering | `MarkerLayer` efficiently handles multiple markers |
| Filtering | Client-side filtering avoids extra Firestore queries |
| Updates | Stream automatically handles add/remove |
| Memory | Markers created on-demand from vendor list |
