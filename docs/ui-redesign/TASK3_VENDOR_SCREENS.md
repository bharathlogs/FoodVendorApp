# Task 3: Vendor App UI Redesign

## Objective
Redesign vendor screens with modern, Swiggy/Zomato-inspired UI using the established theme system and common components.

## Status: ✅ COMPLETED

## Files Modified

| File | Description |
|------|-------------|
| `lib/screens/vendor/vendor_home.dart` | Main vendor dashboard with status toggle |
| `lib/screens/vendor/menu_management_screen.dart` | Menu CRUD operations with modern forms |

---

## Vendor Home Screen (`vendor_home.dart`)

### Overview
Complete redesign of the vendor dashboard featuring SliverAppBar, animated status card, and modern navigation cards.

### Key Features

#### 1. SliverAppBar with FlexibleSpaceBar
```dart
SliverAppBar(
  expandedHeight: 120,
  floating: false,
  pinned: true,
  backgroundColor: AppColors.surface,
  flexibleSpace: FlexibleSpaceBar(
    titlePadding: EdgeInsets.only(left: 16, bottom: 16),
    title: Column(
      children: [
        Text('Welcome back!'),
        Text(vendorProfile?.businessName ?? 'Vendor'),
      ],
    ),
  ),
  actions: [
    IconActionButton(icon: Icons.notifications_outlined),
    IconActionButton(icon: Icons.logout),
  ],
)
```

**Features:**
- 120px expanded height with pinned behavior
- Welcome greeting with business name
- Action buttons using `IconActionButton` component

#### 2. Animated Status Card with Pulse Effect
```dart
AnimatedBuilder(
  animation: _pulseAnimation,
  builder: (context, child) {
    return Transform.scale(
      scale: isActive ? _pulseAnimation.value : 1.0,
      child: GradientCard(
        gradient: isActive
            ? AppColors.successGradient
            : LinearGradient(colors: [Color(0xFF6B7280), Color(0xFF4B5563)]),
        // Status card content
      ),
    );
  },
)
```

**Animation Setup:**
```dart
_pulseController = AnimationController(
  duration: const Duration(seconds: 2),
  vsync: this,
)..repeat(reverse: true);

_pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
  CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
);
```

**States:**
| State | Gradient | Icon | Text |
|-------|----------|------|------|
| Online | Success gradient | `Icons.storefront` | "You're Online!" |
| Offline | Grey gradient | `Icons.store_outlined` | "You're Offline" |
| Transitioning | Current gradient | Loading spinner | "Updating..." |

#### 3. Location Stats Card
```dart
AppCard(
  child: Row(
    children: [
      // Location icon with info background
      Container(
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.location_on, color: AppColors.info),
      ),
      // Coordinates display
      Text('${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'),
      // Last update time
      Text(_formatTime(time)),
    ],
  ),
)
```

#### 4. Navigation Cards (Menu & Cuisine)
Both cards use `AppCard` with consistent structure:
```dart
AppCard(
  onTap: () => Navigator.push(...),
  child: Row(
    children: [
      // Gradient/colored icon container
      Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.restaurant_menu, color: Colors.white),
      ),
      // Title and subtitle
      Column(
        children: [
          Text('Manage Menu', style: AppTextStyles.h4),
          Text('Add, edit, or remove items', style: AppTextStyles.bodySmall),
        ],
      ),
      // Arrow indicator
      Icon(Icons.arrow_forward_ios, color: AppColors.textHint),
    ],
  ),
)
```

#### 5. Error Message Display
```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.error.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
  ),
  child: Row(
    children: [
      Icon(Icons.error_outline, color: AppColors.error),
      Text(errorMessage, style: TextStyle(color: AppColors.error)),
    ],
  ),
)
```

### State Management
Uses `TickerProviderStateMixin` for animations and `LocationManager` listener pattern:

```dart
class _VendorHomeState extends State<VendorHome> with TickerProviderStateMixin {
  @override
  void initState() {
    _initializeVendor();
    _setupAnimations();
  }

  @override
  void dispose() {
    _locationManager.removeListener(_onLocationManagerUpdate);
    _pulseController.dispose();
  }
}
```

---

## Menu Management Screen (`menu_management_screen.dart`)

### Overview
Modern menu management with shimmer loading, styled cards, and bottom sheet forms.

### Key Features

#### 1. AppBar with Item Counter
```dart
AppBar(
  title: Text('Menu'),
  actions: [
    Container(
      decoration: BoxDecoration(
        color: count >= _maxMenuItems
            ? AppColors.error.withValues(alpha: 0.1)
            : AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count/$_maxMenuItems',
        style: TextStyle(
          color: count >= _maxMenuItems ? AppColors.error : AppColors.primary,
        ),
      ),
    ),
  ],
)
```

#### 2. Shimmer Loading State
```dart
if (snapshot.connectionState == ConnectionState.waiting) {
  return const ShimmerList(itemCount: 5, itemHeight: 100);
}
```

#### 3. Empty State
```dart
Column(
  children: [
    Container(
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.restaurant_menu, color: AppColors.primary),
    ),
    Text('No menu items yet', style: AppTextStyles.h3),
    Text('Start building your menu...', style: AppTextStyles.bodyMedium),
    PrimaryButton(
      text: 'Add Your First Item',
      icon: Icons.add,
      onPressed: () => _showAddItemForm(0),
    ),
  ],
)
```

#### 4. Menu Item Card with Availability
```dart
AppCard(
  onTap: () => _showEditItemForm(item),
  child: Row(
    children: [
      // Food icon with availability indicator
      Stack(
        children: [
          Container(
            color: item.isAvailable ? AppColors.primaryLight : Colors.grey.shade200,
            child: Icon(Icons.fastfood),
          ),
          Positioned(
            right: 0, bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: item.isAvailable ? AppColors.success : AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
      // Item details with strikethrough when unavailable
      Column(
        children: [
          Text(
            item.name,
            style: TextStyle(
              decoration: item.isAvailable ? null : TextDecoration.lineThrough,
            ),
          ),
          Text('₹${item.price}', style: AppTextStyles.priceSmall),
        ],
      ),
      // Availability toggle
      Switch(
        value: item.isAvailable,
        activeThumbColor: AppColors.success,
        activeTrackColor: AppColors.success.withValues(alpha: 0.3),
      ),
    ],
  ),
)
```

#### 5. Modern Bottom Sheet Form
```dart
showModalBottomSheet(
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (context) => _ModernMenuItemForm(...),
);

// Form structure
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  child: Column(
    children: [
      // Drag handle
      Container(width: 40, height: 4, color: Colors.grey.shade300),
      // Form title
      Text(isEditing ? 'Edit Item' : 'Add New Item', style: AppTextStyles.h3),
      // Form fields with InputDecoration theme
      TextFormField(
        decoration: InputDecoration(
          labelText: 'Item Name',
          prefixIcon: Icon(Icons.fastfood_outlined),
        ),
      ),
      // Save button
      PrimaryButton(text: 'Add Item', isLoading: _isSaving),
    ],
  ),
)
```

#### 6. Success/Error Snackbars
```dart
SnackBar(
  content: Row(
    children: [
      Icon(Icons.check_circle, color: Colors.white),
      Text(message),
    ],
  ),
  backgroundColor: AppColors.success,
  behavior: SnackBarBehavior.floating,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
)
```

#### 7. Limit Reached Dialog
```dart
AlertDialog(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  title: Row(
    children: [
      Container(
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.warning_amber, color: AppColors.warning),
      ),
      Text('Menu Full'),
    ],
  ),
  content: Text('You\'ve reached the maximum of 50 menu items.'),
)
```

---

## Component Usage Summary

| Component | Used In |
|-----------|---------|
| `AppCard` | Menu cards, location stats, navigation cards |
| `GradientCard` | Status toggle card |
| `PrimaryButton` | Empty state, form save |
| `IconActionButton` | AppBar actions |
| `ShimmerList` | Loading state |
| `AppColors` | All color references |
| `AppTextStyles` | All text styling |

---

## Animations

| Animation | Duration | Curve | Usage |
|-----------|----------|-------|-------|
| Pulse | 2 seconds | easeInOut | Status card when online |
| Transform.scale | - | - | 1.0 → 1.05 scale factor |

---

## Screen Architecture

```
lib/screens/vendor/
├── vendor_home.dart
│   ├── _VendorHomeState (StatefulWidget with TickerProviderStateMixin)
│   ├── _buildAppBar() → SliverAppBar
│   ├── _buildStatusCard() → AnimatedBuilder + GradientCard
│   ├── _buildLocationStats() → AppCard
│   ├── _buildMenuCard() → AppCard
│   ├── _buildCuisineCard() → AppCard
│   └── _buildErrorMessage() → Container
│
└── menu_management_screen.dart
    ├── _MenuManagementScreenState (StatefulWidget)
    ├── _buildEmptyState() → Column
    ├── _buildMenuItemCard() → AppCard
    └── _ModernMenuItemForm (Private StatefulWidget)
        ├── Form with validation
        └── PrimaryButton for save
```

---

## Commit
```
git commit -m "Redesign vendor screens with modern UI"
```
