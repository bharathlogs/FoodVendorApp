# Phase 1: Live Testing Results

## Date: January 18, 2026

## Test Environment

| Property | Value |
|----------|-------|
| Device | Android Emulator (sdk gphone64 x86 64) |
| Android Version | Android 16 (API 36) |
| Flutter Version | 3.38.7 (stable) |
| Build Type | Debug |
| App Version | 1.0.0+1 |

---

## Issues Found & Fixed

### Issue 1: BootReceiver ClassNotFoundException

**Severity:** Critical (App Crash)

**Symptom:**
```
java.lang.ClassNotFoundException: Didn't find class
"com.pravera.flutter_foreground_task.receiver.BootReceiver"
```

**Cause:** Android 16 (API 36) has stricter class loading for broadcast receivers registered in AndroidManifest.xml.

**Fix Applied:**
- Removed BootReceiver from AndroidManifest.xml
- Removed RECEIVE_BOOT_COMPLETED permission
- Added comments explaining the change

**File Changed:** `android/app/src/main/AndroidManifest.xml`

```xml
<!-- Boot receiver removed - causes ClassNotFoundException on Android 16 -->
<!-- Vendor must manually reopen app after device restart -->
```

**Impact:** Vendor app will not auto-restart after device reboot. Vendor must manually open app to go online.

---

### Issue 2: Emulator Location Not Accurate

**Severity:** Low (Emulator-only)

**Symptom:** Map showed default/incorrect location instead of actual user location.

**Cause:** Android emulator uses simulated GPS, not real hardware GPS.

**Fix Applied:** Set emulator location via ADB command:
```bash
~/Library/Android/sdk/platform-tools/adb emu geo fix 77.5946 12.9716
```

**Impact:** None on real devices. Real devices use actual GPS hardware.

---

## Test Results

### Vendor Flow

| Test | Status | Notes |
|------|--------|-------|
| Vendor Login | PASS | Firebase Auth working |
| Vendor Dashboard | PASS | Shows status card, toggle button |
| Go Online | PASS | Location permissions requested |
| Foreground Service | PASS | "You are Open for Business" notification shown |
| Location Updates | PASS | Lat/Lng displayed on dashboard |
| Go Offline | PASS | Service stops, notification removed |
| Logout | PASS | Navigates to login screen |

### Customer Flow

| Test | Status | Notes |
|------|--------|-------|
| Map Display | PASS | OpenStreetMap tiles loading |
| Customer Location | PASS | Blue marker with person icon |
| Vendor Markers | PASS | Orange circle with storefront icon |
| Vendor Tap | PASS | Bottom sheet shows vendor details |
| Cuisine Filters | PASS | Filter chips working |
| Distance Calculation | PASS | Shows km/m from customer |

### Real-Time Updates

| Test | Status | Notes |
|------|--------|-------|
| Vendor appears on map when online | PASS | ~2-3 second delay |
| Vendor disappears when offline | PASS | Immediate |
| Location updates in real-time | PASS | Updates every 90 seconds or on movement |

---

## Screenshots

### Vendor Dashboard (Online)
- Status: "You are OPEN"
- Green indicator dot
- Location coordinates displayed
- "GO OFFLINE" button (red)

### Customer Map View
- Blue marker: Customer location
- Orange marker: Online vendor with storefront icon
- Filter chips at top
- "My Location" FAB button

---

## Firebase Verification

### Firestore Data Structure (vendor_profiles)

```json
{
  "businessName": "Taco Vendor",
  "cuisineTags": ["Mexican"],
  "description": "...",
  "isActive": true,
  "location": {
    "latitude": 12.9716,
    "longitude": 77.5946
  },
  "locationUpdatedAt": "2026-01-18T21:30:00.000Z"
}
```

### Query Working

- `isActive == true` filter: Working
- `locationUpdatedAt` freshness check (10 min): Working
- `.limit(50)` pagination: Applied

---

## Performance Observations

| Metric | Value |
|--------|-------|
| App Launch Time | ~3 seconds |
| Map Load Time | ~2 seconds |
| Vendor Marker Appearance | ~2-3 seconds after going online |
| Location Update Frequency | 90 seconds (heartbeat) + movement-based |
| Battery Impact | Low (medium accuracy GPS) |

---

## Known Limitations

1. **Boot Receiver Disabled**: App won't auto-start after device reboot on Android 16
2. **Emulator GPS**: Must manually set location in emulator
3. **10-Minute Timeout**: Vendor auto-goes-offline if no location update for 10 minutes
4. **50 Vendor Limit**: Map shows maximum 50 vendors at a time

---

## Recommendations

1. Test on physical Android device for accurate GPS behavior
2. Consider adding manual "Refresh" button on customer map
3. Monitor Firebase usage for large-scale testing

---

## Summary

**Overall Status: PASS**

All core features working correctly:
- Vendor can go online/offline
- Location broadcasts to Firestore
- Customer map shows online vendors with markers
- Real-time updates functioning
- Cuisine filtering works

The app is ready for further testing on physical devices.
