# Task 2: Common UI Components

## Objective
Create reusable UI components used across the app for consistent design.

## Status: ✅ COMPLETED

## Files Created

| File | Components |
|------|------------|
| `lib/widgets/common/app_card.dart` | AppCard, GradientCard |
| `lib/widgets/common/status_badge.dart` | StatusBadge, StatusType enum |
| `lib/widgets/common/app_button.dart` | PrimaryButton, SecondaryButton, IconActionButton |
| `lib/widgets/common/cuisine_chip.dart` | CuisineChip, CuisineFilterBar |
| `lib/widgets/common/shimmer_loading.dart` | ShimmerLoading, ShimmerCard, ShimmerList, ShimmerMenuItem |

---

## Component Details

### 1. AppCard (`app_card.dart`)

#### AppCard
Standard card container with customizable properties.

```dart
AppCard(
  child: Widget,
  padding: EdgeInsets?,       // Default: 16 all sides
  margin: EdgeInsets?,        // Default: bottom 12
  onTap: VoidCallback?,
  backgroundColor: Color?,    // Default: cardBackground
  boxShadow: List<BoxShadow>?, // Default: AppShadows.small
  border: Border?,
)
```

#### GradientCard
Card with gradient background for highlighted content.

```dart
GradientCard(
  child: Widget,
  gradient: Gradient,         // Default: AppColors.primaryGradient
  padding: EdgeInsets?,
  margin: EdgeInsets?,
  onTap: VoidCallback?,
)
```

**Features:**
- 16px border radius
- Material InkWell for tap feedback
- Configurable shadows and borders

---

### 2. StatusBadge (`status_badge.dart`)

Animated status indicator with pulsing dot.

```dart
StatusBadge(
  status: StatusType,   // Required
  showIcon: bool,       // Default: true (shows animated dot)
  large: bool,          // Default: false
)
```

#### StatusType Enum

| Status | Color | Background | Text |
|--------|-------|------------|------|
| `open` | Success green | 12% opacity | "Open Now" |
| `closed` | Error red | 12% opacity | "Closed" |
| `preparing` | Primary orange | 12% opacity | "Preparing" |
| `ready` | Success green | 12% opacity | "Ready" |
| `newOrder` | Info blue | 12% opacity | "New" |

**Features:**
- Animated pulsing dot (1.5s cycle)
- Color-coded backgrounds
- Two sizes (normal/large)

---

### 3. AppButton (`app_button.dart`)

#### PrimaryButton
Main action button with gradient background.

```dart
PrimaryButton(
  text: String,           // Required
  onPressed: VoidCallback?,
  isLoading: bool,        // Default: false
  expanded: bool,         // Default: true (full width)
  icon: IconData?,
)
```

**Features:**
- Primary gradient background
- Shadow when enabled
- Loading spinner state
- Optional leading icon
- Disabled state (grey)

#### SecondaryButton
Outlined button for secondary actions.

```dart
SecondaryButton(
  text: String,
  onPressed: VoidCallback?,
  isLoading: bool,
  expanded: bool,
  icon: IconData?,
)
```

**Features:**
- White background
- Primary color border (1.5px)
- Loading spinner state
- Optional leading icon

#### IconActionButton
Circular icon button for toolbar actions.

```dart
IconActionButton(
  icon: IconData,         // Required
  onPressed: VoidCallback?,
  backgroundColor: Color?, // Default: surface
  iconColor: Color?,       // Default: textPrimary
  size: double,            // Default: 48
)
```

**Features:**
- Circular shape
- Small shadow
- Customizable colors and size

---

### 4. CuisineChip (`cuisine_chip.dart`)

#### CuisineChip
Selectable filter chip with animation.

```dart
CuisineChip(
  label: String,          // Required
  isSelected: bool,       // Default: false
  onTap: VoidCallback?,
  icon: IconData?,
)
```

**Features:**
- Animated container (200ms)
- Selected: Primary background, white text, checkmark
- Unselected: White background, border, dark text
- Optional leading icon

#### CuisineFilterBar
Horizontal scrolling filter bar.

```dart
CuisineFilterBar(
  cuisines: List<String>,           // Required
  selectedCuisines: Set<String>,    // Required
  onCuisineToggle: Function(String), // Required
  onClearAll: VoidCallback?,
)
```

**Features:**
- Horizontal scroll
- Clear all button (when selections exist)
- Maps cuisines to CuisineChip widgets

---

### 5. ShimmerLoading (`shimmer_loading.dart`)

#### ShimmerLoading
Base shimmer effect wrapper.

```dart
ShimmerLoading(
  child: Widget,  // Required
)
```

**Features:**
- Animated gradient (1.5s cycle)
- Sliding gradient transform
- Works with any child widget

#### Pre-built Shimmer Widgets

**ShimmerCard**
```dart
ShimmerCard(
  height: double,  // Default: 100
)
```

**ShimmerList**
```dart
ShimmerList(
  itemCount: int,      // Default: 5
  itemHeight: double,  // Default: 80
)
```

**ShimmerMenuItem**
```dart
ShimmerMenuItem()  // Fixed layout: image + text rows
```

---

## Usage Examples

### Card with Status Badge
```dart
AppCard(
  onTap: () => navigateToVendor(),
  child: Column(
    children: [
      Text('Vendor Name', style: AppTextStyles.h4),
      StatusBadge(status: StatusType.open),
    ],
  ),
)
```

### Loading State
```dart
isLoading
  ? ShimmerList(itemCount: 3)
  : ListView.builder(...)
```

### Filter Bar
```dart
CuisineFilterBar(
  cuisines: ['All', 'Indian', 'Chinese', 'Italian'],
  selectedCuisines: _selected,
  onCuisineToggle: (cuisine) => setState(() {
    _selected.contains(cuisine)
      ? _selected.remove(cuisine)
      : _selected.add(cuisine);
  }),
  onClearAll: () => setState(() => _selected.clear()),
)
```

### Action Buttons
```dart
Column(
  children: [
    PrimaryButton(
      text: 'Place Order',
      icon: Icons.shopping_cart,
      isLoading: _isSubmitting,
      onPressed: _submitOrder,
    ),
    SizedBox(height: 12),
    SecondaryButton(
      text: 'Cancel',
      onPressed: () => Navigator.pop(context),
    ),
  ],
)
```

---

## Commit
```
git commit -m "Add common UI components"
```

## Component Architecture

```
lib/widgets/common/
├── app_card.dart         # Card containers
├── app_button.dart       # Button variants
├── status_badge.dart     # Status indicators
├── cuisine_chip.dart     # Filter chips
└── shimmer_loading.dart  # Loading skeletons
```

All components:
- Import from `../../theme/app_theme.dart`
- Use `AppColors`, `AppTextStyles`, `AppShadows`
- Follow Material 3 patterns
- Support customization via parameters
