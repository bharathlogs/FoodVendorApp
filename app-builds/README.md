# App Builds

This folder contains release builds of the Food Finder app.

## Naming Convention

`food-finder-v{VERSION}-{YYYYMMDD}.apk`

## Available Builds

| File | Version | Date | Notes |
|------|---------|------|-------|
| `food-finder-v1.0.0-20260119.apk` | 1.0.0 | Jan 19, 2026 | Sprint 4 complete with Riverpod, favorites, offline sync, profile menu, and bug fixes |

## Build Instructions

To generate a new release build:

```bash
cd FoodVendorApp
flutter build apk --release
```

The APK will be generated at:
`build/app/outputs/flutter-apk/app-release.apk`

Copy it to this folder with the versioned naming convention.

## Installation

To install on an Android device:

1. Enable "Install from unknown sources" in device settings
2. Transfer the APK to the device
3. Open the APK file to install

Or use ADB:
```bash
adb install food-finder-v1.0.0-20260119.apk
```
