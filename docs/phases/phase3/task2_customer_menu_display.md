# Task 2: Menu Display for Customers

## Status: Complete

## Overview
Implement read-only menu viewing for customers. Customers can browse active vendors and view their menus, then walk to the stall to place orders.

---

## Files Created

### 1. `lib/screens/customer/vendor_list_screen.dart`
Browse active/online vendors.

**Full Implementation:**
```dart
import 'package:flutter/material.dart';
import '../../models/vendor_profile.dart';
import '../../services/database_service.dart';
import '../../docs/phase3/vendor_menu_screen.dart';

class VendorListScreen extends StatelessWidget {
  const VendorListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final databaseService = DatabaseService();

    return StreamBuilder<List<VendorProfile>>(
      stream: databaseService.getActiveVendorsWithFreshnessCheck(),
      builder: (context, snapshot) {
        // ... loading, error, empty states
        final vendors = snapshot.data ?? [];
        return ListView.builder(
          itemCount: vendors.length,
          itemBuilder: (context, index) {
            final vendor = vendors[index];
            return _buildVendorCard(context, vendor);
          },
        );
      },
    );
  }
}
```

**Features:**
- Streams active vendors using `getActiveVendorsWithFreshnessCheck()`
- Shows vendor name, description, cuisine tags
- Green "Online" badge for active vendors
- Empty state when no vendors online
- Tap vendor card to navigate to menu

### 2. `lib/screens/customer/vendor_menu_screen.dart`
View vendor menu (read-only).

**Key Implementation:**
```dart
class VendorMenuScreen extends StatelessWidget {
  final VendorProfile vendor;

  const VendorMenuScreen({super.key, required this.vendor});

  @override
  Widget build(BuildContext context) {
    final databaseService = DatabaseService();

    return Scaffold(
      appBar: AppBar(title: Text(vendor.businessName)),
      body: Column(
        children: [
          _buildVendorHeader(),
          Expanded(
            child: StreamBuilder<List<MenuItem>>(
              stream: databaseService.getMenuItemsStream(vendor.vendorId),
              builder: (context, snapshot) {
                final allItems = snapshot.data ?? [];
                // Only show available items to customers
                final items = allItems.where((item) => item.isAvailable).toList();
                // ... build list
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }
}
```

**Features:**
- Vendor header with profile info (name, description, tags)
- Lists only **available** menu items (filters out unavailable)
- Each item shows: name, description, price
- Bottom bar: "Walk to the stall to place your order"
- Read-only (no add to cart, no ordering)

---

## Files Modified

### `lib/screens/customer/customer_home.dart`
Integrated VendorListScreen as the main body.

**Changes:**
```dart
import '../../docs/phase3/vendor_list_screen.dart';

class CustomerHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Food Vendors')),
      body: const VendorListScreen(),  // Embedded vendor list
    );
  }
}
```

---

## Customer Flow

```
CustomerHome
    └── VendorListScreen (embedded)
            │
            ├── Loading state (CircularProgressIndicator)
            ├── Empty state ("No vendors online")
            │
            └── Vendor cards list
                    │
                    └── [Tap vendor] → VendorMenuScreen
                                           │
                                           ├── Vendor header (name, description, tags)
                                           ├── Menu items (available only)
                                           └── Bottom bar ("Walk to stall to order")
```

---

## UI Components

### VendorListScreen

#### Vendor Card
```
┌─────────────────────────────────────────────┐
│  [Avatar]  Business Name      [Online]      │
│            Description text...              │
│            [Tag1] [Tag2] [Tag3]        [>]  │
└─────────────────────────────────────────────┘
```

#### Empty State
```
        [Storefront Icon]

      No vendors online

    Check back later for
    available food vendors
```

### VendorMenuScreen

#### Header
```
┌─────────────────────────────────────────────┐
│  [Avatar]  Business Name                    │
│            Description...                   │
│            [Tag1] [Tag2] [Tag3]             │
└─────────────────────────────────────────────┘
```

#### Menu Item Card
```
┌─────────────────────────────────────────────┐
│  Item Name                     [Rs 150]     │
│  Description text...                        │
└─────────────────────────────────────────────┘
```

#### Bottom Bar
```
┌─────────────────────────────────────────────┐
│  [Walk Icon]  Walk to the stall to place    │
│               your order                    │
└─────────────────────────────────────────────┘
```

---

## Key Design Decisions

### 1. Available Items Only
Customers only see items where `isAvailable == true`. Unavailable items are filtered out.

```dart
final items = allItems.where((item) => item.isAvailable).toList();
```

### 2. Freshness Check
Uses `getActiveVendorsWithFreshnessCheck()` to filter vendors who haven't updated location in 10+ minutes.

### 3. No Ordering
Per requirements, no in-app ordering. Bottom bar prompts user to walk to stall.

### 4. Real-time Updates
Both vendor list and menu items use Firestore streams for real-time updates.

---

## Testing Checklist

- [x] View list of online vendors
- [x] Empty state displayed when no vendors online
- [x] Vendor card shows name, description, cuisine tags
- [x] Green "Online" badge visible
- [x] Tap vendor navigates to menu screen
- [x] Menu screen shows vendor header
- [x] Only available items displayed
- [x] Unavailable items hidden from customers
- [x] Item shows name, description, price
- [x] "Walk to stall" prompt displayed
- [x] Back navigation works correctly

---

## Dependencies

Uses existing services:
- `DatabaseService.getActiveVendorsWithFreshnessCheck()`
- `DatabaseService.getMenuItemsStream(vendorId)`

Uses existing models:
- `VendorProfile`
- `MenuItem`
