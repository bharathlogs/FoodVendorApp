# Task 8: Testing & Integration

## Status: Complete

## Overview
Verify all Phase 4 features work correctly together. This task covers final integration, the customer home map display, and comprehensive testing checklist.

---

## Customer Home Implementation

### Status: Already Complete

The customer home already integrates the map with a List/Map tab navigation, which provides better UX than embedding the map directly.

### Location: `lib/screens/customer/customer_home.dart`

```dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'vendor_list_screen.dart';
import 'map_screen.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = _authService.currentUser != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Find Food Vendors' : 'Nearby Vendors'),
        actions: [
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await _authService.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            )
          else
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: const Text('Login'),
            ),
        ],
      ),
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
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list),
            selectedIcon: Icon(Icons.list_alt),
            label: 'List',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
        ],
      ),
    );
  }
}
```

### Design Decision: Tab Navigation vs Direct Embed

| Approach | Pros | Cons |
|----------|------|------|
| **Tab Navigation** (Current) | Users can choose view preference, list view for detailed info | Extra navigation step |
| Direct Map Embed | Immediate map view | No list alternative |

The tab navigation was chosen for better UX flexibility.

---

## Phase 4 Test Checklist

### Map Display
- [x] Map loads with OpenStreetMap tiles
- [x] Map is zoomable (pinch to zoom)
- [x] Map is pannable (drag to move)
- [x] Default center is reasonable location

### Customer Location
- [x] Location permission requested with rationale
- [x] Customer location shown as blue marker
- [x] "My Location" FAB centers map on customer
- [x] Location error shows retry option
- [x] Permission denied shows settings dialog

### Vendor Markers
- [x] Active vendors appear as orange markers
- [x] Inactive/closed vendors NOT shown
- [x] Stale vendors (no update in 10 min) NOT shown
- [x] Markers update in real-time when vendor goes online
- [x] Tapping marker shows bottom sheet

### Bottom Sheet
- [x] Shows vendor name
- [x] Shows Open/Closed status
- [x] Shows distance (if customer location available)
- [x] Shows walking time estimate
- [x] Shows cuisine tags
- [x] "View Menu" navigates to VendorDetailScreen
- [x] VendorDetailScreen shows correct menu items

### Cuisine Filters
- [x] All cuisine chips displayed
- [x] Chips horizontally scrollable
- [x] Tapping chip toggles selection
- [x] Multiple chips can be selected
- [x] "Clear All" appears when filters active
- [x] Map markers filter correctly
- [x] Filter count badge shows correct number

### Vendor Cuisine Selection
- [x] Vendor can access cuisine selection from home
- [x] Grid shows all 20 categories
- [x] Can select up to 5 cuisines
- [x] Cannot select more than 5 (shows message)
- [x] "Save" updates Firestore
- [x] Saved cuisines display on vendor home

### Distance Calculation
- [x] Distance shows in meters if < 1km
- [x] Distance shows in km if >= 1km
- [x] Walking time estimate reasonable (~12 min/km)

### Firestore Verification
- [x] `vendor_profiles/{id}/cuisineTags` array exists
- [x] Filtering uses `cuisineTags` correctly

---

## End-to-End Test Flow

### 1. Vendor Setup

```
1. Log in as vendor
2. Select 2-3 cuisines (e.g., "South Indian", "Beverages")
3. Add 2-3 menu items
4. Toggle "Go Online" (from Phase 2)
```

### 2. Customer Discovery

```
1. Log out (or use different device/emulator)
2. Open app as guest (customer home)
3. Grant location permission
4. Verify vendor marker appears on map
5. Tap marker → bottom sheet appears
6. Verify distance shown
7. Tap "View Menu" → see menu items
```

### 3. Filter Testing

```
1. Select "South Indian" filter → vendor still visible
2. Select "Chinese" filter (if vendor doesn't have it) → vendor disappears
3. Clear filters → vendor reappears
```

---

## Files Created/Modified in Phase 4

```
lib/
├── utils/
│   ├── cuisine_categories.dart (Task 6)
│   └── distance_formatter.dart (Task 4)
├── services/
│   └── customer_location_service.dart (Task 2)
├── widgets/
│   └── customer/
│       └── vendor_bottom_sheet.dart (Task 5)
├── screens/
│   ├── vendor/
│   │   ├── vendor_home.dart (Modified - Task 7)
│   │   └── cuisine_selection_screen.dart (Task 7)
│   └── customer/
│       ├── customer_home.dart (Already complete)
│       └── map_screen.dart (Task 1)
```

---

## Phase 4 Summary

### Task Completion Status

| Task | Description | Status |
|------|-------------|--------|
| 1 | Map Setup | Complete |
| 2 | Customer Location | Complete |
| 3 | Vendor Markers | Complete |
| 4 | Distance Calculation | Complete |
| 5 | Vendor Bottom Sheet | Complete |
| 6 | Cuisine Filter Chips | Complete |
| 7 | Vendor Cuisine Selection | Complete |
| 8 | Testing & Integration | Complete |

---

## End-of-Phase 4 Checklist

- [x] Map displays with OpenStreetMap tiles
- [x] Customer location shown on map
- [x] Active vendors appear as markers
- [x] Markers update in real-time
- [x] Bottom sheet shows vendor info on marker tap
- [x] Distance and walking time displayed
- [x] Cuisine filter chips work correctly
- [x] Vendors can select their cuisines
- [x] "View Menu" navigates to menu screen
- [x] Guest access works (no login required for browsing)

---

## MVP Complete!

After completing Phase 4, the app has a working MVP with:

### Vendor Features
- Account creation with role selection
- Go Online/Offline toggle with location broadcasting
- Background location updates
- Menu management (add/edit/delete items)
- Cuisine category selection

### Customer Features
- Browse vendors on map without login
- See real-time vendor locations
- Filter by cuisine type
- View vendor menus with prices
- See distance and walking time

---

## Integration Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        VENDOR FLOW                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────┐    ┌──────────────┐    ┌────────────────────┐    │
│  │  Login   │───▶│  Vendor Home │───▶│ Cuisine Selection  │    │
│  └──────────┘    └──────────────┘    └────────────────────┘    │
│                         │                                       │
│                         ▼                                       │
│                  ┌──────────────┐                               │
│                  │ Menu Manage  │                               │
│                  └──────────────┘                               │
│                         │                                       │
│                         ▼                                       │
│                  ┌──────────────┐                               │
│                  │  Go Online   │──────────────────────┐       │
│                  └──────────────┘                      │       │
│                                                        │       │
└────────────────────────────────────────────────────────│───────┘
                                                         │
                              ┌───────────────────────────┘
                              │ Location + Status
                              ▼ to Firestore
┌─────────────────────────────────────────────────────────────────┐
│                       CUSTOMER FLOW                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────┐    ┌──────────────┐    ┌────────────────────┐    │
│  │  Guest   │───▶│ Customer Home│───▶│    Map Screen      │    │
│  │  Access  │    │  (List/Map)  │    │ (Filter + Markers) │    │
│  └──────────┘    └──────────────┘    └────────────────────┘    │
│                                               │                 │
│                                               ▼                 │
│                                      ┌────────────────────┐    │
│                                      │  Bottom Sheet      │    │
│                                      │ (Vendor Info)      │    │
│                                      └────────────────────┘    │
│                                               │                 │
│                                               ▼                 │
│                                      ┌────────────────────┐    │
│                                      │  Vendor Detail     │    │
│                                      │  (Menu Items)      │    │
│                                      └────────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Troubleshooting Common Issues

| Issue | Solution |
|-------|----------|
| Map tiles not loading | Check internet connection, verify OSM URL |
| Location permission denied | Show settings dialog, explain benefits |
| Vendor not appearing on map | Check isActive=true, locationUpdatedAt < 10min |
| Filters not working | Verify vendor has cuisineTags array |
| Distance showing wrong | Check Haversine calculation, coordinate order |
| Bottom sheet not appearing | Verify marker onTap callback |
