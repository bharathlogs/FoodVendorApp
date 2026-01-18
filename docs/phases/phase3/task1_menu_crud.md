# Task 1: Menu CRUD for Vendors (with 50 Item Limit)

## Status: Complete

## Overview
Implement full CRUD (Create, Read, Update, Delete) operations for menu items with a 50 item limit per vendor.

---

## Files Modified

### 1. `lib/services/database_service.dart`
Added 50 item limit validation and count method.

**Changes:**
```dart
// Get menu item count for a vendor
Future<int> getMenuItemCount(String vendorId) async {
  final snapshot = await _firestore
      .collection('vendor_profiles')
      .doc(vendorId)
      .collection('menu_items')
      .count()
      .get();
  return snapshot.count ?? 0;
}

// Add menu item (for Phase 3) with 50 item limit
static const int maxMenuItems = 50;

Future<String> addMenuItem(String vendorId, MenuItem item) async {
  // Check item limit before adding
  final currentCount = await getMenuItemCount(vendorId);
  if (currentCount >= maxMenuItems) {
    throw Exception('Menu item limit reached ($maxMenuItems items maximum)');
  }

  final docRef = await _firestore
      .collection('vendor_profiles')
      .doc(vendorId)
      .collection('menu_items')
      .add(item.toFirestore());
  return docRef.id;
}
```

### 2. `lib/screens/vendor/menu_management_screen.dart`
Updated to display item count and enforce limit in UI.

**Key Changes:**
- Moved Scaffold inside StreamBuilder to access item count
- Added item count display in AppBar bottom
- FAB changes to "Limit Reached" when at 50 items
- Snackbar notification when attempting to exceed limit

**UI Code:**
```dart
return StreamBuilder<List<MenuItem>>(
  stream: _databaseService.getMenuItemsStream(_vendorId!),
  builder: (context, snapshot) {
    final items = snapshot.data ?? [];
    final itemCount = items.length;
    final isAtLimit = itemCount >= DatabaseService.maxMenuItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Menu'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '$itemCount / ${DatabaseService.maxMenuItems} items',
              style: TextStyle(
                fontSize: 13,
                color: isAtLimit ? Colors.red.shade300 : Colors.white70,
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemForm(itemCount),
        icon: const Icon(Icons.add),
        label: Text(isAtLimit ? 'Limit Reached' : 'Add Item'),
        backgroundColor: isAtLimit ? Colors.grey : Colors.orange,
        foregroundColor: Colors.white,
      ),
    );
  },
);
```

---

## Files Created (Previously in Phase 3)

### `lib/widgets/vendor/menu_item_form.dart`
Reusable bottom sheet form widget for add/edit operations.

### `lib/screens/vendor/menu_management_screen.dart`
Menu list screen with inline availability toggles.

---

## Features Implemented

### 1. Menu Management Screen
- Real-time Firestore stream of menu items
- **Item count displayed in app bar**: "12 / 50 items"
- **Count turns red when at limit**
- Empty state with helpful guidance
- Each item displays: name, price (Rs), description
- Green/red availability indicator dot
- Inline Switch toggle for availability
- Tap item to edit via bottom sheet
- Strikethrough text for unavailable items

### 2. Menu Item Form (Bottom Sheet)
- Add new items or edit existing
- Form fields:
  - Name (required, min 2 chars)
  - Price in Rs (required, 1-10000)
  - Description (optional, max 150 chars)
- Delete button with confirmation dialog
- Input validation with error messages
- Loading state during save

### 3. 50 Item Limit Enforcement
- **Backend validation**: DatabaseService throws exception at limit
- **Frontend validation**: Checks count before showing add form
- **Visual feedback**: FAB turns grey, shows "Limit Reached"
- **User notification**: Snackbar when attempting to exceed

---

## Firestore Structure

```
vendor_profiles/{vendorId}/menu_items/{itemId}
  - name: string
  - price: number
  - description: string?
  - isAvailable: boolean
  - createdAt: timestamp
```

---

## Data Model

```dart
class MenuItem {
  final String itemId;
  final String name;
  final double price;
  final String? description;
  final String? imageUrl;      // Reserved for future use
  final bool isAvailable;
  final DateTime createdAt;
}
```

---

## Testing Checklist

- [x] Add a new menu item with all fields
- [x] Add item with only required fields
- [x] Edit existing item
- [x] Toggle availability (hide/show)
- [x] Delete item with confirmation
- [x] Verify real-time updates in list
- [x] Test form validation (empty name, invalid price)
- [x] Test price boundaries (0, 10001)
- [x] **Verify 50 item limit is enforced**
- [x] **Verify item count displays correctly**
- [x] **Verify FAB changes at limit**

---

## API Reference

### DatabaseService Methods

| Method | Description |
|--------|-------------|
| `getMenuItemsStream(vendorId)` | Real-time stream of menu items |
| `getMenuItemCount(vendorId)` | Get current item count |
| `addMenuItem(vendorId, item)` | Add item (enforces 50 limit) |
| `updateMenuItem(vendorId, itemId, data)` | Update item fields |
| `deleteMenuItem(vendorId, itemId)` | Delete item |

### Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `DatabaseService.maxMenuItems` | 50 | Maximum items per vendor |
