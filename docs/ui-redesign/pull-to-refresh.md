# Pull-to-Refresh Implementation

## Overview

Pull-to-refresh was added to list screens with custom theming and staggered entrance animations for list items.

## Files

### New Components

| File | Location | Purpose |
|------|----------|---------|
| `app_refresh_indicator.dart` | `lib/widgets/common/` | Themed RefreshIndicator wrapper |
| `animated_list_item.dart` | `lib/widgets/common/` | Staggered entrance animation |

### Modified Screens

| File | Location | Changes |
|------|----------|---------|
| `vendor_list_screen.dart` | `lib/screens/customer/` | Added refresh + animations |
| `vendor_menu_screen.dart` | `lib/screens/customer/` | Added refresh + animations |

## AppRefreshIndicator

Themed wrapper around Flutter's `RefreshIndicator`:

```dart
AppRefreshIndicator(
  onRefresh: _handleRefresh,
  child: ListView.builder(...),
)
```

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `child` | Widget | required | Scrollable content |
| `onRefresh` | Future<void> Function() | required | Refresh callback |
| `color` | Color? | AppColors.primary | Spinner color |
| `backgroundColor` | Color? | Colors.white | Background |
| `displacement` | double | 60.0 | Pull distance |
| `strokeWidth` | double | 2.5 | Spinner thickness |

### Styling

```dart
RefreshIndicator(
  color: AppColors.primary,      // #FC8019 Orange
  backgroundColor: Colors.white,
  displacement: 60.0,
  strokeWidth: 2.5,
)
```

## AnimatedListItem

Staggered fade+slide entrance for list items:

```dart
ListView.builder(
  itemBuilder: (context, index) {
    return AnimatedListItem(
      index: index,
      child: MyCard(...),
    );
  },
)
```

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `child` | Widget | required | Item content |
| `index` | int | required | Item index for stagger |
| `maxAnimatedItems` | int | 5 | Max items to animate |
| `duration` | Duration | 400ms | Animation duration |
| `delayPerItem` | Duration | 50ms | Stagger delay |
| `curve` | Curve | easeOutCubic | Animation curve |

### Animation

- Items 0-4: Animated with staggered delay
- Items 5+: Appear immediately (no animation)
- Animation: Slide up (15%) + Fade in

### FadeInListItem Variant

Simpler fade-only animation:

```dart
FadeInListItem(
  index: index,
  maxAnimatedItems: 8,
  duration: Duration(milliseconds: 300),
  delayPerItem: Duration(milliseconds: 30),
  child: MyCard(...),
)
```

## VendorListScreen Implementation

### Conversion to StatefulWidget

The screen was converted from `StatelessWidget` to `StatefulWidget` to manage refresh state:

```dart
class _VendorListScreenState extends State<VendorListScreen> {
  final DatabaseService _databaseService = DatabaseService();
  late Stream<List<VendorProfile>> _vendorStream;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _vendorStream = _databaseService.getActiveVendorsWithFreshnessCheck();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _refreshKey++;
      _vendorStream = _databaseService.getActiveVendorsWithFreshnessCheck();
    });
    await Future.delayed(Duration(milliseconds: 500));
  }
}
```

### Key Pattern: Stream Recreation

The refresh works by recreating the stream and using a key to force StreamBuilder rebuild:

```dart
StreamBuilder<List<VendorProfile>>(
  key: ValueKey(_refreshKey),  // Forces rebuild on refresh
  stream: _vendorStream,
  builder: (context, snapshot) { ... },
)
```

### ListView with Refresh

```dart
AppRefreshIndicator(
  onRefresh: _handleRefresh,
  child: ListView.builder(
    physics: AlwaysScrollableScrollPhysics(),  // Enable pull when few items
    itemBuilder: (context, index) {
      return AnimatedListItem(
        index: index,
        child: _buildVendorCard(vendors[index]),
      );
    },
  ),
)
```

## VendorMenuScreen Implementation

### CustomScrollView with Slivers

Uses `CustomScrollView` to combine header and list with single scroll:

```dart
AppRefreshIndicator(
  onRefresh: _handleRefresh,
  child: CustomScrollView(
    physics: AlwaysScrollableScrollPhysics(),
    slivers: [
      // Header
      SliverToBoxAdapter(
        child: _buildVendorHeader(),
      ),

      // Menu items (StreamBuilder)
      StreamBuilder<List<MenuItem>>(
        builder: (context, snapshot) {
          return SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return AnimatedListItem(
                    index: index,
                    child: _buildMenuItemCard(items[index]),
                  );
                },
                childCount: items.length,
              ),
            ),
          );
        },
      ),

      // Bottom padding
      SliverToBoxAdapter(
        child: SizedBox(height: 100),
      ),
    ],
  ),
)
```

## Empty State with Refresh

Empty states support pull-to-refresh with hint text:

```dart
if (items.isEmpty) {
  return AppRefreshIndicator(
    onRefresh: _handleRefresh,
    child: ListView(
      physics: AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              children: [
                Icon(Icons.storefront_outlined),
                Text('No vendors online'),
                Text('Pull down to refresh'),  // Hint
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
```

## Minimum Refresh Time

A small delay ensures visual feedback even for fast operations:

```dart
Future<void> _handleRefresh() async {
  setState(() {
    _refreshKey++;
    _stream = _service.getData();
  });
  // Minimum 500ms for visual feedback
  await Future.delayed(Duration(milliseconds: 500));
}
```
