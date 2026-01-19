# Food Finder v1.1.0

**Release Date:** January 19, 2026
**Build:** `food-finder-v1.1.0-20260119.apk`

---

## New Features

### Theme Toggle (Light/Dark Mode)
- Added theme toggle in profile menu for both Customer and Vendor home screens
- Added theme toggle button on Login screen (top-right corner)
- Added theme toggle button on Signup screen (top-right corner)
- Theme cycles through: Light -> Dark -> System -> Light
- Theme preference persists across app restarts via SharedPreferences
- Shows current theme mode icon (sun/moon/auto) and label

### Dark Mode Support
- Full dark mode theme with proper contrast ratios
- Dark mode colors defined in AppColors class:
  - `backgroundDark: #121212`
  - `surfaceDark: #1E1E1E`
  - `cardBackgroundDark: #2C2C2C`
  - `textPrimaryDark: #E1E1E1`
  - `textSecondaryDark: #B0B0B0`
- All UI components properly styled for both light and dark themes

---

## Technical Details

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/screens/customer/customer_home.dart` | Modified | Added theme toggle to profile popup menu |
| `lib/screens/vendor/vendor_home.dart` | Modified | Converted to ConsumerStatefulWidget, added theme toggle to profile menu |
| `lib/screens/auth/login_screen.dart` | Modified | Converted to ConsumerStatefulWidget, added theme toggle button |
| `lib/screens/auth/signup_screen.dart` | Modified | Converted to ConsumerStatefulWidget, added theme toggle button |

### Architecture Changes

#### Vendor Home Screen
- Converted from `StatefulWidget` to `ConsumerStatefulWidget`
- Now uses Riverpod for theme state management
- Profile menu text colors now use `Theme.of(context)` for proper dark mode support

#### Auth Screens
- Login and Signup screens converted to `ConsumerStatefulWidget`
- Theme toggle button positioned in top-right corner
- Uses `themeProvider` from Riverpod for state management

### Theme Provider Usage

```dart
// Read theme notifier
final themeNotifier = ref.read(themeProvider.notifier);

// Get current theme icon
themeNotifier.themeModeIcon  // Icons.light_mode, Icons.dark_mode, or Icons.settings_brightness

// Get current theme label
themeNotifier.themeModeLabel  // "Light", "Dark", or "System"

// Toggle theme
ref.read(themeProvider.notifier).toggleTheme();
```

### UI Components

#### Profile Menu Theme Toggle
```dart
PopupMenuItem<String>(
  value: 'theme',
  child: Row(
    children: [
      Icon(themeNotifier.themeModeIcon),
      SizedBox(width: 12),
      Text('Theme: ${themeNotifier.themeModeLabel}'),
    ],
  ),
),
```

#### Auth Screen Theme Toggle Button
```dart
Positioned(
  top: MediaQuery.of(context).padding.top + 8,
  right: 16,
  child: Container(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(12),
    ),
    child: IconButton(
      icon: Icon(themeNotifier.themeModeIcon),
      onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
    ),
  ),
),
```

---

## Dark Mode Visibility Fixes

### Text Colors
- Profile menu email text now uses `Theme.of(context).textTheme.bodyLarge?.color` instead of hardcoded `Colors.black87`
- Theme toggle menu item uses theme-aware text and icon colors
- PopupMenu items properly inherit theme colors

### Form Containers
- Login screen form container now uses `Theme.of(context).cardColor` instead of hardcoded `Colors.white`
- Signup screen form container now uses `Theme.of(context).cardColor` instead of hardcoded `Colors.white`
- Theme toggle button container uses `Theme.of(context).cardColor.withValues(alpha: 0.9)` for proper dark mode support

---

## Installation

```bash
adb install food-finder-v1.1.0-20260119.apk
```

Or transfer APK to device and install manually.
