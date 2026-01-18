# Phase 4: Map View for Customers

## Status: IN PROGRESS

## Overview
Phase 4 adds a map-based discovery experience for customers to find nearby food vendors, filter by cuisine, and view distances.

**Key Features:**
| Feature | Description |
|---------|-------------|
| OpenStreetMap | Free map tiles, no API key required |
| Vendor Markers | Real-time display of active vendors |
| Customer Location | GPS with permission handling |
| Distance Calculation | Haversine formula for accuracy |
| Cuisine Filtering | Filter chips for food type selection |

---

## Tasks

| Task | Description | Status | Documentation |
|------|-------------|--------|---------------|
| 1 | Map Setup with OpenStreetMap | **Complete** | [TASK1_MAP_SETUP.md](TASK1_MAP_SETUP.md) |
| 2 | Customer Location Permission | **Complete** | [TASK2_CUSTOMER_LOCATION.md](TASK2_CUSTOMER_LOCATION.md) |
| 3 | Display Vendor Markers | **Complete** | [TASK3_VENDOR_MARKERS.md](TASK3_VENDOR_MARKERS.md) |
| 4 | Distance Calculation (Haversine) | **Complete** | [TASK4_DISTANCE_CALCULATION.md](TASK4_DISTANCE_CALCULATION.md) |
| 5 | Vendor Bottom Sheet | **Complete** | [TASK5_VENDOR_BOTTOM_SHEET.md](TASK5_VENDOR_BOTTOM_SHEET.md) |
| 6 | Cuisine Filter Chips | **Complete** | [TASK6_CUISINE_FILTER_CHIPS.md](TASK6_CUISINE_FILTER_CHIPS.md) |
| 7 | Vendor Profile Cuisine Selection | Pending | - |
| 8 | Testing & Integration | Pending | - |

---

## Quick Summary

### Task 1: Map Setup with OpenStreetMap (Complete)
- OpenStreetMap integration with flutter_map package
- Customer location with GPS permissions
- Vendor markers from Firestore stream
- Cuisine filter chips
- Bottom sheet for vendor preview
- Navigation integration (List/Map tabs)

### Task 2: Customer Location Permission (Complete)
- Permission rationale dialogs before request
- Location services disabled handling
- Permanent denial redirects to app settings
- Haversine distance calculation
- Distance formatting (meters/kilometers)

### Task 3: Display Vendor Markers (Complete)
- Orange circular markers with storefront icon
- Real-time updates via Firestore stream
- Only vendors with valid GeoPoint location
- Tap marker to show bottom sheet

### Task 4: Distance Calculation (Complete)
- Haversine formula for great-circle distance
- Returns distance in kilometers
- Formatted output: "500 m" or "2.3 km"
- Walking time estimation (5 km/h speed)
- DistanceFormatter utility class

### Task 5: Vendor Bottom Sheet (Complete)
- Vendor preview on marker tap
- Avatar, business name, "Open" badge
- Distance + walking time display
- Cuisine tags and description
- "View Menu" navigation button

### Task 6: Cuisine Filter Chips (Complete)
- 20 predefined cuisine categories
- Horizontal scrollable filter chips
- Multi-select with OR logic
- "Clear All" button when filters active
- Filter count badge
- getCuisineIcon() helper function

---

## Dependencies Added

```yaml
dependencies:
  flutter_map: ^8.2.2
  latlong2: ^0.9.1
```

---

## File Changes

### New Files
```
lib/utils/
├── cuisine_categories.dart           # 20 predefined cuisine types + icons
└── distance_formatter.dart           # Distance formatting + walking time

lib/services/
└── customer_location_service.dart    # GPS + Haversine distance

lib/screens/customer/
├── map_screen.dart                   # OpenStreetMap view
└── vendor_detail_screen.dart         # Enhanced vendor page

lib/widgets/customer/
└── vendor_bottom_sheet.dart          # Vendor preview on marker tap
```

### Modified Files
```
lib/screens/customer/customer_home.dart  # Added bottom navigation (List/Map)
pubspec.yaml                             # Added flutter_map, latlong2
```

---

## Architecture

### Customer Map Flow
```
CustomerHome
    │
    ├── [List Tab] → VendorListScreen → VendorMenuScreen
    │
    └── [Map Tab] → MapScreen
                        │
                        ├── Filter chips (cuisine)
                        ├── Customer marker (blue)
                        ├── Vendor markers (orange)
                        │       │
                        │       └── [Tap] → VendorBottomSheet
                        │                       │
                        │                       └── [View Menu] → VendorDetailScreen
                        │
                        └── [FAB] → Center on customer
```

### Data Flow
```
Firestore Stream (getActiveVendorsWithFreshnessCheck)
         │
         ▼
    MapScreen
         │
         ├── Apply cuisine filters (client-side)
         │
         ├── Filter vendors with valid location
         │
         └── Render MarkerLayer
```

---

## Key Components

### OpenStreetMap Configuration
```dart
TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.yourcompany.food_vendor_app',
  maxZoom: 19,
)
```

### Distance Calculation
```dart
// Haversine formula for great-circle distance
double calculateDistance(lat1, lon1, lat2, lon2) {
  // Returns distance in kilometers
}

String formatDistance(distanceKm) {
  // Returns "500 m" or "2.3 km"
}
```

---

## UI Preview

### Map Screen
```
┌─────────────────────────────────┐
│ [South Indian] [Chinese] [...]  │  ← Filter chips
├─────────────────────────────────┤
│                                 │
│       🗺️ OpenStreetMap          │
│                                 │
│    🔵 You                       │
│                                 │
│         🟠 Vendor               │
│                   🟠 Vendor     │
│                                 │
│                         [📍]    │  ← My Location
└─────────────────────────────────┘
│  [List]  │  [Map]  │            │  ← Bottom Nav
└─────────────────────────────────┘
```

---

## Next Steps

Remaining tasks for Phase 4:
- **Task 7**: Vendor profile cuisine selection (allow vendors to tag their stall with cuisines)
- **Task 8**: End-to-end testing
