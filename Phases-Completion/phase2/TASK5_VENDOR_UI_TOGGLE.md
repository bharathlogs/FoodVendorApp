# Phase 2 - Task 5: Vendor UI - Open/Closed Toggle

**Status**: ✅ COMPLETED
**Completion Date**: 2026-01-17
**Estimated Effort**: 1.5 hours (as per guide)
**Actual Effort**: ~30 minutes

---

## Objective

Create a clean vendor dashboard with a prominent Open/Closed toggle that controls location broadcasting.

---

## Why It Matters

- **Primary Interaction Point**: This is where vendors control their visibility to customers
- **Clear Status Display**: Must clearly show current state and any errors
- **Location Confidence**: Displays last known location so vendors know it's working

---

## Completed Steps

### Step 5.1: Update Vendor Home Screen ✅

**File Modified**: [lib/screens/vendor/vendor_home.dart](../../lib/screens/vendor/vendor_home.dart)

Transformed from a simple placeholder to a fully functional vendor dashboard.

#### Key Components

**1. Status Card**
```dart
Widget _buildStatusCard() {
  final isActive = _locationManager.isActive;
  final isTransitioning =
      _locationManager.state == LocationManagerState.starting ||
          _locationManager.state == LocationManagerState.stopping;

  return Card(
    color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
    child: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isTransitioning
                  ? Colors.orange
                  : (isActive ? Colors.green : Colors.grey),
            ),
          ),
          // Status text...
        ],
      ),
    ),
  );
}
```

**Features:**
- ✅ Green indicator when OPEN
- ✅ Grey indicator when CLOSED
- ✅ Orange indicator during transitions
- ✅ Descriptive subtitle for customer visibility

**2. Toggle Button**
```dart
Widget _buildToggleButton() {
  return SizedBox(
    width: double.infinity,
    height: 80,
    child: ElevatedButton(
      onPressed: isTransitioning ? null : _toggleStatus,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.red.shade400 : Colors.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: isTransitioning
          ? const CircularProgressIndicator(color: Colors.white)
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isActive ? Icons.stop : Icons.play_arrow, size: 32),
                const SizedBox(width: 12),
                Text(isActive ? 'GO OFFLINE' : 'GO ONLINE'),
              ],
            ),
    ),
  );
}
```

**Features:**
- ✅ Large, prominent button (80px height)
- ✅ Green "GO ONLINE" when closed
- ✅ Red "GO OFFLINE" when open
- ✅ Spinner during state transitions
- ✅ Disabled during transitions to prevent race conditions

**3. Location Info Card**
```dart
Widget _buildLocationInfo() {
  final lat = _locationManager.lastLatitude;
  final lng = _locationManager.lastLongitude;
  final time = _locationManager.lastUpdateTime;

  if (lat == null || lng == null) {
    return Card(
      child: Row(
        children: [
          CircularProgressIndicator(strokeWidth: 2),
          Text('Getting your location...'),
        ],
      ),
    );
  }

  return Card(
    child: Column(
      children: [
        Text('Latitude: ${lat.toStringAsFixed(6)}'),
        Text('Longitude: ${lng.toStringAsFixed(6)}'),
        Text('Last updated: ${_formatDateTime(time)}'),
      ],
    ),
  );
}
```

**Features:**
- ✅ Shows loading state while getting initial location
- ✅ Displays coordinates with 6 decimal precision
- ✅ Shows last update timestamp
- ✅ Only visible when actively broadcasting

**4. Error Message Card**
```dart
Widget _buildErrorMessage() {
  return Card(
    color: Colors.red.shade50,
    child: Row(
      children: [
        Icon(Icons.error_outline, color: Colors.red),
        Text(_locationManager.errorMessage!),
      ],
    ),
  );
}
```

**Features:**
- ✅ Red background for visibility
- ✅ Error icon
- ✅ Displays error message from LocationManager

---

### Step 5.2: Provider Package ✅

The task suggested adding the `provider` package, but after reviewing the implementation:

**Decision**: Not needed - Using direct ChangeNotifier pattern

The `LocationManager` is already a singleton with `ChangeNotifier`, so we use the simpler `addListener`/`removeListener` pattern:

```dart
@override
void initState() {
  super.initState();
  _locationManager.addListener(_onLocationManagerUpdate);
}

void _onLocationManagerUpdate() {
  if (mounted) {
    setState(() {});
  }
}

@override
void dispose() {
  _locationManager.removeListener(_onLocationManagerUpdate);
  super.dispose();
}
```

**Benefits:**
- No additional dependencies
- Simpler code
- Works perfectly with singleton pattern
- Proper cleanup in dispose()

---

### Step 5.3: Safe Logout Handling ✅

```dart
Future<void> _handleLogout() async {
  final navigator = Navigator.of(context);
  if (_locationManager.isActive) {
    await _locationManager.stopBroadcasting();
  }
  await _authService.signOut();
  if (mounted) {
    navigator.pushReplacementNamed('/login');
  }
}
```

**Key Points:**
- ✅ Captures Navigator before async operations (avoids BuildContext warning)
- ✅ Stops broadcasting before signing out
- ✅ Checks mounted before navigation

---

## Success Criteria Checklist

- [x] Toggle button clearly shows current state (green/red colors, play/stop icons)
- [x] Transitioning state disables button and shows spinner
- [x] Location coordinates displayed when active
- [x] Error messages displayed when something fails
- [x] Logout stops broadcasting before signing out
- [x] No lint warnings or errors

---

## Common Pitfalls Avoided

| Pitfall | How We Avoided It | Verification |
|---------|-------------------|--------------|
| Toggle spam causing race conditions | Disable button during state transitions | ✅ `isTransitioning` check |
| Memory leak from listener | Remove listener in dispose() | ✅ `removeListener` in dispose |
| Logout without stopping broadcast | Always stop broadcasting before logout | ✅ In `_handleLogout` |
| BuildContext across async gaps | Capture Navigator before await | ✅ Lint passes |

---

## UI Layout

```
┌─────────────────────────────────────────────────────────────┐
│                        App Bar                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Business Name                            [Logout]   │   │
│  └──────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌────────────────────────────────────────────────────┐    │
│  │ ● You are OPEN / CLOSED                            │    │
│  │   Customers can see your location / cannot find you│    │
│  └────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌────────────────────────────────────────────────────┐    │
│  │              ▶ GO ONLINE                           │    │
│  │              ■ GO OFFLINE                          │    │
│  │              ⟳ (spinner when transitioning)        │    │
│  └────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌────────────────────────────────────────────────────┐    │
│  │ 📍 Your Location                                   │    │
│  │ Latitude: 12.971600                                │    │
│  │ Longitude: 77.594600                               │    │
│  │ Last updated: 14:30:45                             │    │
│  └────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌────────────────────────────────────────────────────┐    │
│  │ ⚠ Error message (if any)                          │    │
│  └────────────────────────────────────────────────────┘    │
│                                                             │
│                         [Spacer]                            │
│                                                             │
│  ┌────────────────────────────────────────────────────┐    │
│  │ 🍽️ Menu & Orders                                  │    │
│  │    Coming in Phase 3                               │    │
│  └────────────────────────────────────────────────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## State Machine Visualization

```
                     ┌──────────────┐
                     │    idle      │
                     │  (CLOSED)    │
                     └──────┬───────┘
                            │ User taps "GO ONLINE"
                            ▼
                     ┌──────────────┐
                     │   starting   │ ← Button disabled, spinner shown
                     │ (Updating...)│
                     └──────┬───────┘
                            │
               ┌────────────┴────────────┐
               │                         │
               ▼                         ▼
        ┌──────────────┐          ┌──────────────┐
        │    active    │          │    error     │
        │   (OPEN)     │          │ (show error) │
        └──────┬───────┘          └──────────────┘
               │ User taps "GO OFFLINE"
               ▼
        ┌──────────────┐
        │   stopping   │ ← Button disabled, spinner shown
        │ (Updating...)│
        └──────┬───────┘
               │
               ▼
        ┌──────────────┐
        │    idle      │
        │  (CLOSED)    │
        └──────────────┘
```

---

## Color Scheme

| State | Status Indicator | Button Color | Card Background |
|-------|-----------------|--------------|-----------------|
| Closed (idle) | Grey | Green | Grey shade 100 |
| Transitioning | Orange | Disabled (grey) | Current state |
| Open (active) | Green | Red | Green shade 50 |
| Error | Grey | Green | Red shade 50 |

---

## Files Modified

### [lib/screens/vendor/vendor_home.dart](../../lib/screens/vendor/vendor_home.dart)

**Changes:**
- Converted from `StatelessWidget` to `StatefulWidget`
- Added LocationManager integration with listener pattern
- Implemented status card, toggle button, location info, error message
- Added safe logout handling
- Added Phase 3 placeholder

**Line count:** 358 lines (previously 44 lines)

---

## Metrics

| Metric | Value |
|--------|-------|
| Files modified | 1 |
| Lines of code added | ~314 |
| UI components created | 5 |
| Dependencies added | 0 |
| Lint errors | 0 |

---

## Integration Points

### With LocationManager
```dart
final LocationManager _locationManager = LocationManager();

// Initialize with vendor ID
await _locationManager.initialize(uid);

// Listen for updates
_locationManager.addListener(_onLocationManagerUpdate);

// Toggle status
await _locationManager.startBroadcasting(context);
await _locationManager.stopBroadcasting();

// Read state
_locationManager.isActive
_locationManager.state
_locationManager.lastLatitude
_locationManager.lastLongitude
_locationManager.lastUpdateTime
_locationManager.errorMessage
```

### With DatabaseService
```dart
final DatabaseService _databaseService = DatabaseService();

// Load vendor profile for business name
final profile = await _databaseService.getVendorProfile(uid);
```

### With AuthService
```dart
final AuthService _authService = AuthService();

// Get current user
final uid = _authService.currentUser?.uid;

// Sign out
await _authService.signOut();
```

---

## Testing Notes

### Manual Testing Steps:

1. **Initial Load:**
   - Open app as vendor
   - Verify business name in app bar
   - Verify "You are CLOSED" status
   - Verify green "GO ONLINE" button

2. **Go Online:**
   - Tap "GO ONLINE"
   - Verify button shows spinner
   - Verify permission dialog appears
   - Approve permissions
   - Verify status changes to "You are OPEN"
   - Verify button changes to red "GO OFFLINE"
   - Verify location card appears with coordinates

3. **Go Offline:**
   - Tap "GO OFFLINE"
   - Verify spinner appears
   - Verify status changes to "You are CLOSED"
   - Verify location card disappears

4. **Error Handling:**
   - Deny permissions when going online
   - Verify error message appears
   - Verify status stays "CLOSED"

5. **Logout:**
   - While online, tap logout
   - Verify broadcasting stops before logout
   - Verify navigation to login screen

---

## Dependencies for Next Tasks

**Task 6 (Timeout Detection)** requires:
- ✅ Vendor UI showing location updates
- ✅ Timestamp display for debugging
- ✅ Error message display

**Phase 3 (Menu & Orders)** requires:
- ✅ Placeholder card ready for expansion
- ✅ Vendor profile loaded

---

**Task 5 Complete** ✅
**Ready for Phase 2 - Task 6 (Timeout Detection)** ✅
