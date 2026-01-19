# App Builds

This folder contains release builds of the Food Finder app.

## Folder Structure

```
app-builds/
├── README.md              (this file)
├── latest-release/        (contains the latest APK)
│   └── food-finder-v1.0.0-20260119.apk
├── v1.0.0/
│   └── README.md          (release notes, features, bug fixes)
├── v1.1.0/
│   └── README.md
└── ...
```

## Latest Release

**Version:** 1.0.0
**Date:** January 19, 2026
**File:** [latest-release/food-finder-v1.0.0-20260119.apk](latest-release/)

See [v1.0.0/README.md](v1.0.0/README.md) for release notes.

## All Versions

| Version | Date | Release Notes |
|---------|------|---------------|
| [v1.0.0](v1.0.0/) | Jan 19, 2026 | Riverpod, favorites, offline sync, profile menu |

## Naming Convention

- **APK:** `food-finder-v{VERSION}-{YYYYMMDD}.apk`
- **Version folders:** Contains only README with release notes

## Creating a New Release

1. **Build the APK:**
   ```bash
   cd FoodVendorApp
   flutter build apk --release
   ```

2. **Replace APK in latest-release:**
   ```bash
   cp build/app/outputs/flutter-apk/app-release.apk app-builds/latest-release/food-finder-v{VERSION}-{YYYYMMDD}.apk
   # Remove old APK
   rm app-builds/latest-release/food-finder-v{OLD_VERSION}*.apk
   ```

3. **Create version folder with README:**
   ```bash
   mkdir -p app-builds/v{VERSION}
   # Create README.md with release notes
   ```

4. **Update this file** with new version info

## Installation

```bash
adb install app-builds/latest-release/food-finder-v1.0.0-20260119.apk
```

Or transfer APK to device and install manually.
