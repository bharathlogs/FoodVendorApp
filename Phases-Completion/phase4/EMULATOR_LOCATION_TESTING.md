# Emulator Location Testing Instructions

## Overview
Before Phase 5, here's how to test location features on Android emulator.

---

## Setting Mock Location on Android Emulator

### Method 1: Using Emulator Extended Controls (Easiest)

#### 1. Open Emulator Extended Controls
- Run your app on Android emulator
- Click the three dots (...) on the emulator toolbar (right side)
- Select "Location" from the left menu

#### 2. Set Single Location
- Enter latitude and longitude manually
- Example for Bangalore: `12.9716, 77.5946`
- Example for Chennai: `13.0827, 80.2707`
- Click "Set Location" or "Send"

#### 3. Simulate Movement (for vendor testing)
- In the Location panel, you can set a route
- Or manually change coordinates every few seconds
- This simulates a vendor moving

---

### Method 2: Using ADB Commands

```bash
# Set location via ADB
adb emu geo fix <longitude> <latitude>

# Example: Set to Bangalore
adb emu geo fix 77.5946 12.9716

# Note: ADB uses longitude first, then latitude!
```

---

### Method 3: GPX File for Routes

1. Create a GPX file with waypoints
2. In Emulator Extended Controls → Location → Load GPX/KML
3. Play the route to simulate movement

---

## Test Coordinates for India

| Location | Latitude | Longitude |
|----------|----------|-----------|
| Bangalore - MG Road | 12.9716 | 77.5946 |
| Bangalore - Koramangala | 12.9352 | 77.6245 |
| Chennai - T Nagar | 13.0418 | 80.2341 |
| Mumbai - Bandra | 19.0596 | 72.8295 |
| Delhi - Connaught Place | 28.6315 | 77.2167 |

---

## Testing Workflow

### 1. Test as Vendor

```
1. Set emulator location to Location A
2. Log in as vendor, go online
3. Verify Firestore shows correct coordinates
```

### 2. Test as Customer

```
1. Set emulator location to Location B (nearby)
2. Open customer map
3. Verify vendor marker appears
4. Verify distance calculation is reasonable
```

### 3. Test Location Updates

```
1. As vendor (online), change emulator location
2. Wait 90 seconds for heartbeat update
3. Check if Firestore location updates
4. Check if customer map shows new position
```

---

## Visual Guide

```
┌─────────────────────────────────────────────────────────────┐
│                    EMULATOR WINDOW                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                                                    ┌─────┐  │
│                                                    │ ... │◀─┼── Click here
│                                                    ├─────┤  │
│            [Your App Running]                      │  ▶  │  │
│                                                    │  ⏸  │  │
│                                                    │  📷 │  │
│                                                    │  ⋮  │  │
│                                                    └─────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              EXTENDED CONTROLS WINDOW                       │
├─────────────┬───────────────────────────────────────────────┤
│             │                                               │
│  Location   │◀─ Select this     Latitude:  [12.9716    ]   │
│  Cellular   │                   Longitude: [77.5946    ]   │
│  Battery    │                                               │
│  Camera     │                   [Set Location]              │
│  Phone      │                                               │
│  ...        │                   ─────────────────────────   │
│             │                   Routes:                     │
│             │                   [Load GPX/KML]              │
│             │                                               │
└─────────────┴───────────────────────────────────────────────┘
```

---

## Firestore Verification

After setting location, check Firestore console:

```
vendor_profiles/{vendorId}
├── location: GeoPoint(12.9716, 77.5946)
├── locationUpdatedAt: Timestamp(...)
└── isActive: true
```

---

## Common Issues

| Issue | Solution |
|-------|----------|
| Location not updating | Check if vendor is "online" (isActive=true) |
| Wrong coordinates in Firestore | Verify lat/lng order (Firestore: lat first) |
| Customer doesn't see vendor | Check freshness (locationUpdatedAt < 10 min) |
| Distance shows wrong | ADB uses lng,lat order; manual uses lat,lng |

---

## Two-Emulator Testing

For full end-to-end testing:

1. **Emulator 1 (Vendor)**
   - Set location to MG Road (12.9716, 77.5946)
   - Log in as vendor, go online

2. **Emulator 2 (Customer)**
   - Set location to Koramangala (12.9352, 77.6245)
   - Open app as guest
   - Should see vendor ~4km away

---

## Distance Reference

| From | To | Approx Distance |
|------|-----|-----------------|
| MG Road | Koramangala | ~4 km |
| MG Road | T Nagar (Chennai) | ~290 km |
| Bangalore | Mumbai | ~840 km |
