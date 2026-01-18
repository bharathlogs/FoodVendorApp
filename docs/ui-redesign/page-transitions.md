# Page Transition Animations

## Overview

Custom page transitions provide smooth, consistent navigation throughout the app. Different transition types are used based on the navigation context.

## Files

| File | Location | Purpose |
|------|----------|---------|
| `app_transitions.dart` | `lib/core/navigation/` | Reusable transition builders |
| `app_page_route.dart` | `lib/core/navigation/` | Custom PageRouteBuilder wrapper |
| `navigation_extensions.dart` | `lib/core/navigation/` | Context extension methods |
| `main.dart` | `lib/` | Route configuration with transitions |

## Transition Types

### Available Transitions

| Type | Animation | Use Case |
|------|-----------|----------|
| `fade` | Opacity 0→1 | Auth screens, subtle transitions |
| `slideRight` | Slide from right | Detail screens, forward navigation |
| `slideLeft` | Slide from left | Reverse navigation feel |
| `slideUp` | Slide from bottom | Modal-like screens, signup |
| `slideDown` | Slide from top | Dismissing modals |
| `scale` | Scale 0→1 | Emphasis transitions |
| `fadeScale` | Fade + Scale 0.92→1 | Home screens, branded feel |

### Route Assignments

```dart
'/login'        → fade transition
'/signup'       → slideUp transition
'/vendor-home'  → fadeScale transition
'/customer-home' → fadeScale transition
```

## Usage

### Using Named Routes (Automatic)

```dart
Navigator.pushReplacementNamed(context, '/vendor-home');
// Automatically uses fadeScale transition
```

### Using AppPageRoute Directly

```dart
Navigator.push(
  context,
  AppPageRoute(
    page: VendorMenuScreen(vendor: vendor),
    transitionType: AppTransitionType.slideRight,
  ),
);
```

### Using Navigation Extensions

```dart
import 'core/navigation/navigation_extensions.dart';

// Push with transition
context.pushWithTransition(
  MyScreen(),
  transition: AppTransitionType.slideRight,
);

// Push replacement with transition
context.pushReplacementWithTransition(
  HomeScreen(),
  transition: AppTransitionType.fadeScale,
);
```

## Implementation Details

### AppTransitions Class

Provides static transition builder methods:

```dart
class AppTransitions {
  static const Duration defaultDuration = Duration(milliseconds: 300);
  static const Curve defaultCurve = Curves.easeInOutCubic;

  static Widget fadeTransition(...) { ... }
  static Widget slideRightTransition(...) { ... }
  static Widget fadeScaleTransition(...) { ... }
  // ... other transitions
}
```

### AppPageRoute Class

Custom `PageRouteBuilder` that applies transitions:

```dart
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({
    required Widget page,
    AppTransitionType transitionType = AppTransitionType.slideRight,
    Duration? customDuration,
    RouteSettings? settings,
  });
}
```

### onGenerateRoute Integration

In `main.dart`, transitions are applied via `onGenerateRoute`:

```dart
MaterialApp(
  onGenerateRoute: _onGenerateRoute,
  // ...
);

Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/login':
      return AppPageRoute(
        page: LoginScreen(),
        transitionType: AppTransitionType.fade,
      );
    // ... other routes
  }
}
```

## Animation Timing

| Property | Value |
|----------|-------|
| Duration | 300ms |
| Curve | easeInOutCubic |
| FadeScale range | 0.92 → 1.0 |

## Customization

### Custom Duration

```dart
AppPageRoute(
  page: MyScreen(),
  transitionType: AppTransitionType.fade,
  customDuration: Duration(milliseconds: 500),
);
```

### Adding New Transitions

1. Add enum value to `AppTransitionType`
2. Add transition builder method to `AppTransitions`
3. Update `getTransitionBuilder` switch statement
