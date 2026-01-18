# Task 5: Vendor Bottom Sheet

## Status: Complete (Implemented in Task 1)

## Overview
Display a bottom sheet preview when a vendor marker is tapped on the map, showing key vendor information and a "View Menu" action.

---

## File Created

### `lib/widgets/customer/vendor_bottom_sheet.dart`

---

## Implementation

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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          _buildDragHandle(),
          const SizedBox(height: 16),

          // Vendor header
          _buildHeader(context),
          const SizedBox(height: 12),

          // Description
          if (vendor.description != null && vendor.description!.isNotEmpty)
            _buildDescription(),

          // Cuisine tags
          if (vendor.cuisineTags.isNotEmpty) _buildCuisineTags(),

          const SizedBox(height: 16),

          // View Menu button
          _buildViewMenuButton(context),
        ],
      ),
    );
  }
}
```

---

## UI Components

### 1. Drag Handle
```dart
Widget _buildDragHandle() {
  return Container(
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}
```

### 2. Vendor Header
```dart
Widget _buildHeader(BuildContext context) {
  return Row(
    children: [
      // Avatar
      CircleAvatar(
        radius: 28,
        backgroundColor: Colors.orange.shade100,
        backgroundImage: vendor.profileImageUrl != null
            ? NetworkImage(vendor.profileImageUrl!)
            : null,
        child: vendor.profileImageUrl == null
            ? Icon(Icons.storefront, color: Colors.orange.shade700)
            : null,
      ),
      const SizedBox(width: 12),

      // Name and distance
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business name with "Open" badge
            Row(
              children: [
                Flexible(
                  child: Text(
                    vendor.businessName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildOpenBadge(),
              ],
            ),

            // Distance
            if (distanceKm != null) ...[
              const SizedBox(height: 4),
              _buildDistanceRow(),
            ],
          ],
        ),
      ),
    ],
  );
}
```

### 3. Open Badge
```dart
Widget _buildOpenBadge() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.green,
      borderRadius: BorderRadius.circular(4),
    ),
    child: const Text(
      'Open',
      style: TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
```

### 4. Distance Row with Walking Time
```dart
// Uses DistanceFormatter utility class
Row(
  children: [
    Icon(Icons.directions_walk, size: 16, color: Colors.grey.shade600),
    const SizedBox(width: 4),
    Text(
      '${DistanceFormatter.format(distanceKm!)} · ${DistanceFormatter.walkingTime(distanceKm!)}',
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w500,
      ),
    ),
  ],
)
// Example output: "1.2 km · 14 min walk"
```

### 5. Description
```dart
Widget _buildDescription() {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      vendor.description!,
      style: TextStyle(
        color: Colors.grey.shade700,
        fontSize: 14,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    ),
  );
}
```

### 6. Cuisine Tags
```dart
Widget _buildCuisineTags() {
  return Wrap(
    spacing: 6,
    runSpacing: 6,
    children: vendor.cuisineTags.map((tag) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Text(
          tag,
          style: TextStyle(
            color: Colors.orange.shade800,
            fontSize: 12,
          ),
        ),
      );
    }).toList(),
  );
}
```

### 7. View Menu Button
```dart
Widget _buildViewMenuButton(BuildContext context) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: onViewMenu,
      icon: const Icon(Icons.restaurant_menu),
      label: const Text('View Menu'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
}
```

---

## Visual Layout

```
┌─────────────────────────────────────┐
│              ═══════                │  ← Drag handle
│                                     │
│  ┌────┐  Business Name      [Open]  │  ← Avatar + Name + Badge
│  │ 🏪 │  📍 1.2 km                  │  ← Distance
│  └────┘                             │
│                                     │
│  Delicious South Indian food...     │  ← Description (max 3 lines)
│                                     │
│  [South Indian] [Dosa] [Idli]       │  ← Cuisine tags
│                                     │
│  ┌─────────────────────────────┐    │
│  │    🍽️  View Menu            │    │  ← Action button
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

---

## Triggering the Bottom Sheet

### In MapScreen

```dart
void _showVendorBottomSheet(VendorProfile vendor) {
  double? distance;
  if (_customerLocation != null && vendor.location != null) {
    distance = _locationService.calculateDistance(
      _customerLocation!.latitude,
      _customerLocation!.longitude,
      vendor.location!.latitude,
      vendor.location!.longitude,
    );
  }

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => VendorBottomSheet(
      vendor: vendor,
      distanceKm: distance,
      onViewMenu: () {
        Navigator.pop(context); // Close bottom sheet
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VendorDetailScreen(
              vendor: vendor,
              distanceKm: distance,
            ),
          ),
        );
      },
    ),
  );
}
```

---

## Navigation Flow

```
Map Screen
     │
     └── Tap vendor marker
              │
              ▼
        VendorBottomSheet
              │
              ├── Swipe down → Dismiss
              │
              └── Tap "View Menu"
                       │
                       ├── Close bottom sheet
                       │
                       └── Navigate to VendorDetailScreen
```

---

## Props

| Prop | Type | Required | Description |
|------|------|----------|-------------|
| `vendor` | `VendorProfile` | Yes | Vendor data to display |
| `distanceKm` | `double?` | No | Distance in km (null if unavailable) |
| `onViewMenu` | `VoidCallback` | Yes | Action when "View Menu" tapped |

---

## Conditional Rendering

| Element | Condition |
|---------|-----------|
| Distance row | `distanceKm != null` |
| Description | `vendor.description != null && vendor.description!.isNotEmpty` |
| Cuisine tags | `vendor.cuisineTags.isNotEmpty` |
| Profile image | `vendor.profileImageUrl != null` (else shows icon) |

---

## Testing Checklist

- [x] Bottom sheet opens on marker tap
- [x] Drag handle visible at top
- [x] Vendor avatar displays (image or fallback icon)
- [x] Business name shown (truncates if long)
- [x] "Open" badge visible
- [x] Distance displayed when available
- [x] Description shows (max 3 lines with ellipsis)
- [x] Cuisine tags wrap correctly
- [x] "View Menu" button spans full width
- [x] Tap "View Menu" navigates to detail screen
- [x] Swipe down dismisses bottom sheet
- [x] Rounded corners at top
