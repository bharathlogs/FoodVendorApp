# Task 2: Network & Edge Case Testing

**Status**: ✅ Complete
**Date**: 2026-01-18

---

## Objective
Test app behavior under poor network conditions and edge cases to ensure graceful degradation and proper error handling.

---

## Test Scenarios

### Network Tests (4 Tests)

| ID | Scenario | Description |
|----|----------|-------------|
| N1 | Vendor Goes Online with No Internet | Airplane mode, try to go online |
| N2 | Vendor Loses Internet While Online | Go online, then lose connection |
| N3 | Customer Opens Map with No Internet | Airplane mode on customer device |
| N4 | Slow Network (2G Simulation) | GSM speed simulation |

### Edge Case Tests (10 Tests)

| ID | Scenario | Description |
|----|----------|-------------|
| E1 | Vendor Timeout (10 minutes) | Location services disabled while online |
| E2 | Location Permission Revoked | Revoke permission while online |
| E3 | Very Far Distance | Delhi to Chennai (~2000 km) |
| E4 | Same Location (Zero Distance) | Customer and vendor at same coordinates |
| E5 | Empty Menu | Vendor with no menu items |
| E6 | No Active Vendors | Customer map with no online vendors |
| E7 | 50 Menu Items Limit | Maximum item count enforcement |
| E8 | App Killed While Online | Force close during active session |
| E9 | Multiple Filter Selection | All 10+ cuisine filters selected |
| E10 | Special Characters in Names | Unicode and special chars in text |

---

## Network Test Details

### Test N1: Vendor Goes Online with No Internet
**Purpose**: Verify error handling when network unavailable

**Steps:**
1. Enable airplane mode on device
2. Try to "GO ONLINE"
3. Verify error message displayed
4. Verify status stays offline

**Expected Results:**
- Error message: "No internet connection" or similar
- Button remains "GO ONLINE"
- Firestore `isActive` remains `false`

---

### Test N2: Vendor Loses Internet While Online
**Purpose**: Verify location queue and offline notification

**Steps:**
1. Go online with good connection
2. Enable airplane mode
3. Wait 30 seconds
4. Check notification
5. Disable airplane mode
6. Verify sync recovery

**Expected Results:**
- Notification shows "Offline - X updates pending"
- LocationQueueService queues location updates
- On reconnect: "Back online - location synced"
- Firestore receives queued update

---

### Test N3: Customer Opens Map with No Internet
**Purpose**: Verify customer map graceful degradation

**Steps:**
1. Enable airplane mode
2. Open customer map
3. Observe map behavior
4. Disable airplane mode
5. Verify recovery

**Expected Results:**
- Map tiles may not load (cached tiles may show)
- Error shown for vendor loading failure
- On reconnect: map loads, vendors appear

---

### Test N4: Slow Network (2G Simulation)
**Purpose**: Verify app works on slow connections

**Setup**: Android emulator → Settings → Network → Speed: GSM

**Steps:**
1. Go online as vendor
2. Check if location updates succeed
3. Open customer map
4. Check if vendors load

**Expected Results:**
- Operations complete but slower
- No crashes or timeouts
- Loading indicators shown during wait

---

## Edge Case Test Details

### Test E1: Vendor Timeout (10 minutes)
**Purpose**: Verify timeout mechanism

**Steps:**
1. Go online as vendor
2. Disable location services (Settings → Location → Off)
3. Wait 10+ minutes
4. Check app status

**Expected Results:**
- App auto-goes offline due to timeout
- Firestore `isActive` = `false`
- `lastLocationUpdate` > 10 minutes old

---

### Test E2: Location Permission Revoked While Online
**Purpose**: Verify graceful permission handling

**Steps:**
1. Go online as vendor
2. Settings → Apps → Food Vendor App → Permissions
3. Revoke location permission
4. Return to app

**Expected Results:**
- Graceful handling (goes offline or shows error)
- No crash
- User informed of permission issue

---

### Test E3: Very Far Distance
**Purpose**: Verify distance calculation at extreme ranges

**Setup:**
- Vendor: Delhi (28.6315, 77.2167)
- Customer: Chennai (13.0827, 80.2707)

**Expected Results:**
- Distance shows ~2000+ km
- Walking time shows appropriate estimate
- No overflow or display issues

---

### Test E4: Same Location (Zero Distance)
**Purpose**: Verify zero distance handling

**Setup:**
- Set vendor and customer to same coordinates

**Expected Results:**
- Shows "0 m" or "< 1 min walk"
- No division by zero errors
- Display looks reasonable

---

### Test E5: Empty Menu
**Purpose**: Verify empty menu display

**Steps:**
1. Create new vendor with no menu items
2. Go online
3. View as customer

**Expected Results:**
- Menu section shows "No menu items available"
- No crash or empty screen
- Vendor still visible on map

---

### Test E6: No Active Vendors
**Purpose**: Verify empty vendor list handling

**Steps:**
1. Ensure no vendors are online
2. Open customer map

**Expected Results:**
- Map shows without markers
- No error shown
- Empty state message: "No vendors nearby"

---

### Test E7: 50 Menu Items Limit
**Purpose**: Verify maximum item enforcement

**Steps:**
1. Add 50 menu items
2. Try to add 51st item

**Expected Results:**
- Error message "Maximum 50 menu items"
- FAB color is grey (disabled)
- Cannot add more items

---

### Test E8: App Killed While Vendor Online
**Purpose**: Verify cleanup on force close

**Steps:**
1. Go online as vendor
2. Force close app (swipe from recent apps)
3. Wait 10 minutes

**Expected Results:**
- Foreground service may continue briefly
- Timeout triggers, goes offline
- Firestore `isActive` = `false` after timeout

---

### Test E9: Multiple Filter Selection
**Purpose**: Verify filter logic with many selections

**Steps:**
1. Select all cuisine filters (10+)
2. Observe vendor filtering

**Expected Results:**
- All vendors shown (OR logic)
- Badge shows "X filters active"
- Clear All button visible
- No performance issues

---

### Test E10: Special Characters in Names
**Purpose**: Verify Unicode handling

**Test Data:**
- Menu item: "Idli & Vada (2 pcs)"
- Vendor name: "Ram's Tiffin Center"
- With emoji: "Best Dosa 🍕"

**Expected Results:**
- Characters display correctly
- No Firestore errors
- Search/filter works correctly

---

## Test Results Template

### Network Tests

| ID | Test | Pass | Fail | Notes |
|----|------|------|------|-------|
| N1 | Vendor Online - No Internet | [ ] | [ ] | |
| N2 | Vendor Loses Internet | [ ] | [ ] | |
| N3 | Customer Map - No Internet | [ ] | [ ] | |
| N4 | Slow Network (2G) | [ ] | [ ] | |

### Edge Case Tests

| ID | Test | Pass | Fail | Notes |
|----|------|------|------|-------|
| E1 | Vendor Timeout | [ ] | [ ] | |
| E2 | Permission Revoked | [ ] | [ ] | |
| E3 | Very Far Distance | [ ] | [ ] | |
| E4 | Same Location | [ ] | [ ] | |
| E5 | Empty Menu | [ ] | [ ] | |
| E6 | No Active Vendors | [ ] | [ ] | |
| E7 | 50 Items Limit | [ ] | [ ] | |
| E8 | App Killed Online | [ ] | [ ] | |
| E9 | Multiple Filters | [ ] | [ ] | |
| E10 | Special Characters | [ ] | [ ] | |

---

## Key Code Locations

### Network Handling
| Feature | File |
|---------|------|
| Location Queue | `lib/services/location_queue_service.dart` |
| Connectivity Check | Network state monitoring |
| Offline Notification | `lib/services/background_location_service.dart` |

### Edge Case Handling
| Feature | File |
|---------|------|
| Menu Item Limit | `lib/screens/vendor/menu_management_screen.dart` |
| Distance Calculation | `lib/utils/distance_formatter.dart` |
| Empty States | Various screen widgets |
| Mounted Checks | `lib/screens/customer/map_screen.dart` |

---

## Success Criteria

- [x] All 4 network tests documented
- [x] All 10 edge case tests documented
- [x] Test result template created
- [x] Key code locations identified
- [x] Documentation committed to git

---

## Files Created

| File | Purpose |
|------|---------|
| `Phases-Completion/phase5/TASK2_NETWORK_EDGE_CASES.md` | This documentation |
| `docs/test-results.md` (updated) | Added network and edge case test sections |
