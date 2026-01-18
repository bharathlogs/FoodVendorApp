# Task 4: Customer App UI Redesign

## Objective
Redesign customer-facing screens with modern, Swiggy/Zomato-inspired UI using the established theme system and common components.

## Status: ✅ COMPLETED

## Files Modified

| File | Description |
|------|-------------|
| `lib/widgets/customer/vendor_bottom_sheet.dart` | Vendor preview bottom sheet |
| `lib/screens/customer/vendor_detail_screen.dart` | Full vendor detail with menu |

---

## Vendor Bottom Sheet (`vendor_bottom_sheet.dart`)

### Overview
Modern bottom sheet displayed when a customer taps on a vendor marker on the map.

### Key Features

#### 1. Rounded Container with Handle
```dart
Container(
  decoration: const BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  child: Column(
    children: [
      // Drag handle
      Container(
        margin: const EdgeInsets.only(top: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      // Content
    ],
  ),
)
```

#### 2. Vendor Header with Gradient Icon
```dart
Row(
  children: [
    // Gradient vendor icon with shadow
    Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.storefront, color: Colors.white, size: 36),
    ),
    // Name and status
    Column(
      children: [
        Text(vendor.businessName, style: AppTextStyles.h3),
        StatusBadge(
          status: vendor.isActive ? StatusType.open : StatusType.closed,
          large: true,
        ),
      ],
    ),
  ],
)
```

#### 3. Distance & Walking Time Card
```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        AppColors.info.withValues(alpha: 0.1),
        AppColors.info.withValues(alpha: 0.05),
      ],
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
  ),
  child: Row(
    children: [
      // Distance section
      Expanded(
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.location_on, color: AppColors.info),
            ),
            Column(
              children: [
                Text(DistanceFormatter.format(distanceKm)),
                Text('away'),
              ],
            ),
          ],
        ),
      ),
      // Vertical divider
      Container(width: 1, height: 40, color: AppColors.info.withValues(alpha: 0.2)),
      // Walking time section
      Expanded(
        child: Row(
          children: [
            Icon(Icons.directions_walk),
            Column(
              children: [
                Text(_getWalkingTime()),
                Text('walk'),
              ],
            ),
          ],
        ),
      ),
    ],
  ),
)
```

**Walking Time Calculation:**
```dart
String _getWalkingTime() {
  if (distanceKm == null) return '-';
  final minutes = (distanceKm! / 5 * 60).round(); // 5 km/h walking speed
  if (minutes < 1) return '<1 min';
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  return '${hours}h ${minutes % 60}m';
}
```

#### 4. Cuisine Tags
```dart
Wrap(
  spacing: 8,
  runSpacing: 8,
  children: vendor.cuisineTags.map((tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
      ),
    );
  }).toList(),
)
```

#### 5. View Menu Button
```dart
PrimaryButton(
  text: 'View Menu',
  icon: Icons.restaurant_menu,
  onPressed: onViewMenu,
)
```

---

## Vendor Detail Screen (`vendor_detail_screen.dart`)

### Overview
Full vendor detail page with hero header, distance info, and menu items list.

### Key Features

#### 1. SliverAppBar with Hero Header
```dart
SliverAppBar(
  expandedHeight: 200,
  pinned: true,
  backgroundColor: AppColors.primary,
  flexibleSpace: FlexibleSpaceBar(
    background: Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Stack(
        children: [
          // Pattern overlay
          Positioned.fill(
            child: CustomPaint(painter: _PatternPainter()),
          ),
          // Vendor info
          Positioned(
            left: 20, right: 20, bottom: 20,
            child: Row(
              children: [
                // Vendor icon
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(...)],
                  ),
                  child: Icon(Icons.storefront, color: AppColors.primary),
                ),
                // Name and status
                Column(
                  children: [
                    Text(vendor.businessName, style: TextStyle(color: Colors.white)),
                    StatusBadge(status: vendor.isActive ? StatusType.open : StatusType.closed),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
  leading: IconButton(
    icon: Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.arrow_back, color: Colors.white),
    ),
    onPressed: () => Navigator.pop(context),
  ),
)
```

#### 2. Custom Pattern Painter
```dart
class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 10; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.3),
        50.0 + i * 20,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

#### 3. Info Cards Row
```dart
Row(
  children: [
    // Distance Card
    Expanded(
      child: _InfoCard(
        icon: Icons.location_on,
        iconColor: AppColors.info,
        title: DistanceFormatter.format(distanceKm),
        subtitle: 'Distance',
      ),
    ),
    const SizedBox(width: 12),
    // Walking Time Card
    Expanded(
      child: _InfoCard(
        icon: Icons.directions_walk,
        iconColor: AppColors.success,
        title: DistanceFormatter.walkingTime(distanceKm),
        subtitle: 'Walking',
      ),
    ),
  ],
)
```

**InfoCard Widget:**
```dart
class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          Column(
            children: [
              Text(title, style: AppTextStyles.labelLarge),
              Text(subtitle, style: AppTextStyles.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
```

#### 4. Menu Section with Shimmer Loading
```dart
// Section Header
Row(
  children: [
    Icon(Icons.restaurant_menu, color: AppColors.primary),
    const SizedBox(width: 8),
    Text('Menu', style: AppTextStyles.h3),
  ],
)

// Loading State
StreamBuilder<List<MenuItem>>(
  stream: databaseService.getMenuItemsStream(vendor.vendorId),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => const ShimmerMenuItem(),
            childCount: 4,
          ),
        ),
      );
    }
    // ...
  },
)
```

#### 5. Menu Item Card
```dart
class _MenuItemCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Food icon
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.fastfood, color: AppColors.primary),
          ),
          // Item details
          Expanded(
            child: Column(
              children: [
                Text(item.name, style: AppTextStyles.labelLarge),
                if (item.description != null)
                  Text(item.description!, style: AppTextStyles.bodySmall),
                // Price badge
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '₹${item.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

#### 6. Empty Menu State
```dart
Widget _buildEmptyMenu() {
  return Center(
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.restaurant_menu, size: 48, color: AppColors.primary),
        ),
        Text('Menu not available', style: AppTextStyles.h4),
        Text('Check back later or visit the stall', style: AppTextStyles.bodyMedium),
      ],
    ),
  );
}
```

#### 7. Bottom Navigation Bar
```dart
bottomNavigationBar: Container(
  padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
  decoration: BoxDecoration(
    color: Colors.white,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 10,
        offset: const Offset(0, -5),
      ),
    ],
  ),
  child: Row(
    children: [
      // Info text
      Expanded(
        child: Column(
          children: [
            Text('Ready to order?', style: AppTextStyles.bodySmall),
            Text('Visit the stall directly', style: AppTextStyles.labelLarge),
          ],
        ),
      ),
      // Visit Stall button
      Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.directions_walk, color: Colors.white),
                    Text('Head to the stall to place your order!'),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
          child: Row(
            children: [
              Icon(Icons.directions_walk, color: Colors.white),
              Text('Visit Stall', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    ],
  ),
)
```

---

## Component Usage Summary

| Component | Used In |
|-----------|---------|
| `AppCard` | Info cards, menu item cards |
| `StatusBadge` | Vendor status (open/closed) |
| `PrimaryButton` | View menu button |
| `ShimmerMenuItem` | Loading state |
| `AppColors` | All color references |
| `AppTextStyles` | All text styling |

---

## Private Widgets

| Widget | File | Purpose |
|--------|------|---------|
| `_InfoCard` | vendor_detail_screen.dart | Distance/walking time display |
| `_MenuItemCard` | vendor_detail_screen.dart | Menu item display |
| `_PatternPainter` | vendor_detail_screen.dart | Hero header decoration |

---

## Screen Architecture

```
lib/widgets/customer/
└── vendor_bottom_sheet.dart
    └── VendorBottomSheet (StatelessWidget)
        ├── Gradient vendor icon
        ├── StatusBadge
        ├── Distance/walking time card
        ├── Cuisine tags (Wrap)
        └── PrimaryButton

lib/screens/customer/
└── vendor_detail_screen.dart
    ├── VendorDetailScreen (StatelessWidget)
    │   ├── SliverAppBar with hero
    │   ├── Info cards row
    │   ├── Cuisine tags
    │   ├── Menu StreamBuilder
    │   └── Bottom navigation bar
    ├── _InfoCard (Private StatelessWidget)
    ├── _MenuItemCard (Private StatelessWidget)
    └── _PatternPainter (Private CustomPainter)
```

---

## Visual Elements

### Color Usage
| Element | Color |
|---------|-------|
| Vendor icon background | `AppColors.primaryGradient` |
| Distance icons | `AppColors.info` |
| Walking time icons | `AppColors.success` |
| Cuisine tags | `AppColors.primaryLight` + `AppColors.primary` |
| Price badges | `AppColors.success` |
| Shadows | Various with `alpha: 0.1-0.3` |

### Border Radius
| Element | Radius |
|---------|--------|
| Bottom sheet | 24px top |
| Cards | 16px (via AppCard) |
| Icon containers | 12-16px |
| Cuisine tags | 20px (pill shape) |
| Buttons | 12px |

---

## Commit
```
git commit -m "Redesign customer screens with modern UI"
```
