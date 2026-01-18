# Emulator Location Testing Execution

## Date: 2026-01-18

## Overview
Executed location testing workflow on Android emulator to verify Phase 4 location features.

---

## Environment Setup

### Emulator Details
| Property | Value |
|----------|-------|
| AVD Name | Medium_Phone_API_36.1 |
| Device ID | emulator-5554 |
| API Level | 36 |
| Architecture | x86_64 |

### SDK Paths
```
Flutter: /Users/equipp/flutter/bin/flutter
ADB: /Users/equipp/Library/Android/sdk/platform-tools/adb
Emulator: /Users/equipp/Library/Android/sdk/emulator/emulator
```

---

## Build Configuration Update

### Issue Encountered
Plugins required Android SDK 36, but project was configured for SDK 34.

```
Warning: The plugin geolocator_android requires Android SDK version 36 or higher.
Warning: The plugin flutter_plugin_android_lifecycle requires Android SDK version 36 or higher.
```

### Resolution
Updated `android/app/build.gradle.kts`:

```kotlin
android {
    namespace = "com.vendorapp.food_vendor_app"
    compileSdk = 36  // Changed from 34
    // ...
    defaultConfig {
        // ...
        targetSdk = 36  // Changed from 34
    }
}
```

---

## Execution Steps

### 1. Start Emulator

```bash
# List available emulators
/Users/equipp/Library/Android/sdk/emulator/emulator -list-avds
# Output: Medium_Phone_API_36.1

# Start emulator
/Users/equipp/Library/Android/sdk/emulator/emulator -avd Medium_Phone_API_36.1 -no-snapshot-load &

# Wait for boot and verify
/Users/equipp/Library/Android/sdk/platform-tools/adb devices
# Output: emulator-5554  device
```

### 2. Build and Run App

```bash
cd /Users/equipp/Documents/VendorApp/FoodVendorApp
/Users/equipp/flutter/bin/flutter run -d emulator-5554
```

**Build Output:**
```
Running Gradle task 'assembleDebug'...                             68.1s
✓ Built build/app/outputs/flutter-apk/app-debug.apk
Installing build/app/outputs/flutter-apk/app-debug.apk...        1,526ms
```

### 3. Set Mock Location

```bash
# Set location to Bangalore - MG Road
# Note: ADB uses longitude first, then latitude
/Users/equipp/Library/Android/sdk/platform-tools/adb emu geo fix 77.5946 12.9716
# Output: OK
```

### 4. Launch App

```bash
# Launch app manually
/Users/equipp/Library/Android/sdk/platform-tools/adb shell "am start -n com.vendorapp.food_vendor_app/.MainActivity"

# Verify app in foreground
/Users/equipp/Library/Android/sdk/platform-tools/adb shell "dumpsys window | grep mCurrentFocus"
# Output: mCurrentFocus=Window{...com.vendorapp.food_vendor_app/com.vendorapp.food_vendor_app.MainActivity}
```

---

## Verification Results

### App Startup Logs
```
D/FlutterGeolocator( 6659): Attaching Geolocator to activity
D/FlutterGeolocator( 6659): Creating service.
D/FlutterGeolocator( 6659): Binding to location service.
D/FlutterGeolocator( 6659): Geolocator foreground service connected
D/FlutterGeolocator( 6659): Initializing Geolocator services
D/FlutterGeolocator( 6659): Flutter engine connected. Connected engine count 1
```

### DevTools Access
```
Dart VM Service: http://127.0.0.1:53283/Ca4OzhBk1qc=/
Flutter DevTools: http://127.0.0.1:53283/Ca4OzhBk1qc=/devtools/
```

---

## Test Coordinates Reference

| Location | Latitude | Longitude | ADB Command |
|----------|----------|-----------|-------------|
| Bangalore - MG Road | 12.9716 | 77.5946 | `adb emu geo fix 77.5946 12.9716` |
| Bangalore - Koramangala | 12.9352 | 77.6245 | `adb emu geo fix 77.6245 12.9352` |
| Chennai - T Nagar | 13.0418 | 80.2341 | `adb emu geo fix 80.2341 13.0418` |
| Mumbai - Bandra | 19.0596 | 72.8295 | `adb emu geo fix 72.8295 19.0596` |
| Delhi - Connaught Place | 28.6315 | 77.2167 | `adb emu geo fix 77.2167 28.6315` |

---

## Status Summary

| Task | Status | Notes |
|------|--------|-------|
| Emulator Start | ✅ Complete | Medium_Phone_API_36.1 |
| SDK Update | ✅ Complete | Updated to SDK 36 |
| App Build | ✅ Complete | 68.1s build time |
| App Install | ✅ Complete | 1,526ms |
| Mock Location Set | ✅ Complete | Bangalore MG Road |
| Geolocator Service | ✅ Connected | Foreground service active |
| App Running | ✅ Complete | MainActivity in foreground |

---

## Manual Testing Checklist

### Vendor Flow
- [ ] Log in as vendor
- [ ] Select cuisine types
- [ ] Tap "GO ONLINE"
- [ ] Verify location appears in Firestore
- [ ] Change mock location
- [ ] Wait 90 seconds for heartbeat
- [ ] Verify Firestore location updates

### Customer Flow
- [ ] Log out / open as guest
- [ ] Grant location permission
- [ ] Verify customer location marker (blue)
- [ ] Verify vendor marker appears (orange)
- [ ] Tap vendor marker
- [ ] Verify bottom sheet shows distance
- [ ] Verify "View Menu" navigates correctly

### Filter Testing
- [ ] Select cuisine filter
- [ ] Verify vendor markers filter correctly
- [ ] Clear filters
- [ ] Verify all vendors reappear

---

## Useful Commands

### Change Location During Testing
```bash
# Move to Koramangala (~4km from MG Road)
/Users/equipp/Library/Android/sdk/platform-tools/adb emu geo fix 77.6245 12.9352

# Move to Chennai (test long distance)
/Users/equipp/Library/Android/sdk/platform-tools/adb emu geo fix 80.2341 13.0418
```

### Check App Logs
```bash
/Users/equipp/Library/Android/sdk/platform-tools/adb logcat | grep -E "(flutter|Geolocator)"
```

### Restart App
```bash
/Users/equipp/Library/Android/sdk/platform-tools/adb shell "am force-stop com.vendorapp.food_vendor_app"
/Users/equipp/Library/Android/sdk/platform-tools/adb shell "am start -n com.vendorapp.food_vendor_app/.MainActivity"
```

### Hot Reload (if flutter run is active)
Press `r` in the terminal running `flutter run`

---

## Known Issues

| Issue | Workaround |
|-------|------------|
| Skipped frames warning | Normal during debug mode startup |
| SDK 36 warnings | Informational only, app works correctly |
| Location not updating | Ensure vendor is "online" (isActive=true) |

---

## Files Modified

| File | Change |
|------|--------|
| `android/app/build.gradle.kts` | compileSdk: 34→36, targetSdk: 34→36 |
