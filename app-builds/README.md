# App Builds

This folder contains release builds of the Food Finder app, organized by version.

## Folder Structure

```
app-builds/
├── README.md           (this file)
├── v1.0.0/
│   ├── food-finder-v1.0.0-20260119.apk
│   └── README.md       (release notes, bug fixes, new features)
├── v1.1.0/
│   ├── food-finder-v1.1.0-YYYYMMDD.apk
│   └── README.md
└── ...
```

## Available Versions

| Version | Date | Highlights |
|---------|------|------------|
| [v1.0.0](v1.0.0/) | Jan 19, 2026 | Riverpod, favorites, offline sync, profile menu |

## Naming Convention

- **Folder:** `v{MAJOR}.{MINOR}.{PATCH}`
- **APK:** `food-finder-v{VERSION}-{YYYYMMDD}.apk`
- **README:** Contains release notes, bug fixes, and new features

## Creating a New Release

1. **Build the APK:**
   ```bash
   cd FoodVendorApp
   flutter build apk --release
   ```

2. **Create version folder:**
   ```bash
   mkdir -p app-builds/v{VERSION}
   ```

3. **Copy APK:**
   ```bash
   cp build/app/outputs/flutter-apk/app-release.apk app-builds/v{VERSION}/food-finder-v{VERSION}-{YYYYMMDD}.apk
   ```

4. **Create README.md** in the version folder with:
   - New features
   - Bug fixes
   - Technical details
   - Installation instructions

5. **Update this file** to add the new version to the table

## Installation

To install on an Android device:

1. Enable "Install from unknown sources" in device settings
2. Transfer the APK to the device
3. Open the APK file to install

Or use ADB:
```bash
adb install app-builds/v1.0.0/food-finder-v1.0.0-20260119.apk
```
