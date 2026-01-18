# Task 6: Cuisine Filter Chips

## Status: Complete (Implemented in Task 1)

## Overview
Implement horizontal scrollable filter chips for filtering vendors by cuisine type on the map view.

---

## Files

### Created: `lib/utils/cuisine_categories.dart`
### Modified: `lib/screens/customer/map_screen.dart`

---

## Cuisine Categories

### Location: `lib/utils/cuisine_categories.dart`

```dart
import 'package:flutter/material.dart';

/// Predefined cuisine categories for vendor tagging and filtering
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

/// Get icon for cuisine category
IconData getCuisineIcon(String cuisine) {
  switch (cuisine) {
    case 'South Indian':
      return Icons.rice_bowl;
    case 'North Indian':
      return Icons.lunch_dining;
    case 'Chinese':
      return Icons.ramen_dining;
    case 'Street Food':
      return Icons.fastfood;
    case 'Biryani':
      return Icons.rice_bowl;
    case 'Chaat':
      return Icons.tapas;
    case 'Snacks':
      return Icons.cookie;
    case 'Beverages':
      return Icons.local_cafe;
    case 'Desserts':
      return Icons.cake;
    case 'Fast Food':
      return Icons.lunch_dining;
    case 'Momos':
      return Icons.set_meal;
    case 'Rolls':
      return Icons.wrap_text;
    case 'Dosa':
      return Icons.rice_bowl;
    case 'Idli':
      return Icons.breakfast_dining;
    case 'Pav Bhaji':
      return Icons.dinner_dining;
    case 'Vada Pav':
      return Icons.lunch_dining;
    case 'Samosa':
      return Icons.bakery_dining;
    case 'Juice':
      return Icons.local_drink;
    case 'Tea/Coffee':
      return Icons.coffee;
    case 'Ice Cream':
      return Icons.icecream;
    default:
      return Icons.restaurant;
  }
}
```

### Category Selection Rationale

| Category | Popular Items |
|----------|---------------|
| South Indian | Dosa, Idli, Vada, Uttapam |
| North Indian | Paratha, Chole, Rajma |
| Chinese | Noodles, Manchurian, Fried Rice |
| Street Food | Mixed snacks, Chaat |
| Biryani | Chicken/Mutton/Veg Biryani |
| Chaat | Pani Puri, Bhel, Sev Puri |
| Snacks | Pakora, Bhaji, Cutlet |
| Beverages | Lassi, Buttermilk, Shakes |
| Desserts | Jalebi, Gulab Jamun, Kulfi |
| Fast Food | Burgers, Pizza, Fries |
| Momos | Veg/Chicken Momos |
| Rolls | Kathi Rolls, Frankie |
| Dosa | Specialty dosa stalls |
| Idli | Specialty idli stalls |
| Pav Bhaji | Mumbai style |
| Vada Pav | Mumbai style |
| Samosa | Samosa specialists |
| Juice | Fresh fruit juices |
| Tea/Coffee | Chai, Filter Coffee |
| Ice Cream | Kulfi, Softy, Scoops |

---

## Filter Implementation

### State Management

```dart
class _MapScreenState extends State<MapScreen> {
  // Filter state - using Set for O(1) contains check
  final Set<String> _selectedCuisines = {};

  void _toggleCuisineFilter(String cuisine) {
    setState(() {
      if (_selectedCuisines.contains(cuisine)) {
        _selectedCuisines.remove(cuisine);
      } else {
        _selectedCuisines.add(cuisine);
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCuisines.clear();
    });
  }
}
```

### Filter Chips UI

```dart
Widget _buildFilterChips() {
  return Positioned(
    top: MediaQuery.of(context).padding.top + 8,
    left: 0,
    right: 0,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter chips
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              // Clear all button (only show when filters active)
              if (_selectedCuisines.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: const Text('Clear All'),
                    avatar: const Icon(Icons.clear, size: 18),
                    onPressed: _clearFilters,
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),

              // Cuisine filter chips
              ...cuisineCategories.map((cuisine) {
                final isSelected = _selectedCuisines.contains(cuisine);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cuisine),
                    selected: isSelected,
                    onSelected: (_) => _toggleCuisineFilter(cuisine),
                    selectedColor: Colors.orange.shade200,
                    checkmarkColor: Colors.orange.shade800,
                    backgroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: Colors.black26,
                  ),
                );
              }),
            ],
          ),
        ),

        // Active filter count badge
        if (_selectedCuisines.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: _buildFilterCountBadge(),
          ),
      ],
    ),
  );
}
```

### Filter Count Badge

```dart
Widget _buildFilterCountBadge() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.orange,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      '${_selectedCuisines.length} filter${_selectedCuisines.length > 1 ? 's' : ''} active',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
```

---

## Applying Filters to Vendors

### In `_buildVendorMarkers()`

```dart
Widget _buildVendorMarkers() {
  return StreamBuilder<List<VendorProfile>>(
    stream: _databaseService.getActiveVendorsWithFreshnessCheck(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const MarkerLayer(markers: []);
      }

      List<VendorProfile> vendors = snapshot.data!;

      // Apply cuisine filter (client-side)
      if (_selectedCuisines.isNotEmpty) {
        vendors = vendors.where((vendor) {
          return vendor.cuisineTags.any(
            (tag) => _selectedCuisines.contains(tag),
          );
        }).toList();
      }

      // Filter vendors with valid location
      vendors = vendors.where((v) => v.location != null).toList();

      // Build markers...
    },
  );
}
```

### Filter Logic

- **No filters selected**: Show all vendors
- **One+ filters selected**: Show vendors matching ANY selected cuisine (OR logic)
- Uses `any()` for inclusive matching

---

## Visual Layout

```
┌─────────────────────────────────────────────────────────────┐
│ [Clear All] [South Indian] [Chinese] [Street Food] [→ more] │
│                                                             │
│ 🟠 2 filters active                                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                        MAP VIEW                             │
│                                                             │
│                   (filtered vendors only)                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Chip States

### Unselected
```dart
FilterChip(
  selected: false,
  backgroundColor: Colors.white,
  elevation: 2,
)
```
- White background
- Subtle shadow
- Default text color

### Selected
```dart
FilterChip(
  selected: true,
  selectedColor: Colors.orange.shade200,
  checkmarkColor: Colors.orange.shade800,
)
```
- Orange background
- Checkmark icon
- Orange text

---

## Conditional UI Elements

| Element | When Shown |
|---------|------------|
| "Clear All" chip | At least 1 filter selected |
| Filter count badge | At least 1 filter selected |
| Checkmark on chip | Chip is selected |

---

## Performance

### Why Client-Side Filtering?

| Approach | Pros | Cons |
|----------|------|------|
| **Client-side** | Instant response, no network calls | More data transferred initially |
| Server-side | Less data transferred | Latency on each filter change |

For a typical map view with < 100 vendors, client-side filtering provides the best UX.

### Optimization

- `Set<String>` for O(1) contains check
- Filtering happens in `StreamBuilder` builder (not a separate stream)
- Uses `setState` only on filter change

---

## Testing Checklist

- [x] Filter chips scroll horizontally
- [x] Chips are tappable
- [x] Selected chips show checkmark
- [x] Selected chips have orange background
- [x] "Clear All" appears when filters active
- [x] "Clear All" removes all selections
- [x] Filter count badge shows correct count
- [x] Badge shows "filter" vs "filters" correctly
- [x] Vendor markers update immediately on filter change
- [x] Multiple filters work with OR logic
- [x] No filters shows all vendors

---

## Usage with VendorProfile

### VendorProfile.cuisineTags

```dart
class VendorProfile {
  // ...
  final List<String> cuisineTags;
  // ...
}
```

Vendors must have `cuisineTags` populated to be filterable. Empty tags means the vendor won't match any filter.

---

## Future Considerations

| Enhancement | Description |
|-------------|-------------|
| Popular filters | Show most-used cuisines first |
| Recent filters | Remember user's filter preferences |
| Distance + Cuisine | Combine with distance sorting |
| Search | Text search across cuisines |
