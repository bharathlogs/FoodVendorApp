# Phase 2 - Task 4: Offline Queue & Sync

**Status**: ✅ COMPLETED
**Completion Date**: 2026-01-17
**Estimated Effort**: 1.5 hours (as per guide)
**Actual Effort**: ~30 minutes

---

## Objective

Store location updates locally when offline and sync them when connectivity returns.

---

## Why It Matters

- **Spotty Connectivity**: Vendors in markets may have unreliable network
- **Data Preservation**: Without queuing, location updates are lost during offline periods
- **Customer Experience**: Customers see stale locations, thinking vendor has left

---

## Completed Steps

### Step 4.1: Enhance LocationQueueService ✅

**File Modified**: [lib/services/location_queue_service.dart](../../lib/services/location_queue_service.dart)

The LocationQueueService was initially created in Task 3. In Task 4, we enhanced it with:

#### Added Max Queue Size Limit

```dart
class LocationQueueService {
  static const String _queueKey = 'location_queue';
  static const int _maxQueueSize = 100; // Prevent unbounded growth

  // ... existing code ...

  /// Add a location update to the queue
  Future<void> enqueue(double latitude, double longitude, DateTime timestamp) async {
    _queue.add({
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    });

    // Trim if too large (keep most recent)
    if (_queue.length > _maxQueueSize) {
      _queue.removeRange(0, _queue.length - _maxQueueSize);
    }

    await _saveQueue();
  }
}
```

**Key Enhancement:**
- ✅ Cap queue at 100 entries to prevent unbounded memory growth
- ✅ Keep most recent entries when trimming (oldest are discarded)
- ✅ Ensures app doesn't consume excessive storage during extended offline periods

---

### Step 4.2: Add Comprehensive Unit Tests ✅

**File Created**: [test/services/location_queue_service_test.dart](../../test/services/location_queue_service_test.dart)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_vendor_app/services/location_queue_service.dart';

void main() {
  group('LocationQueueService', () {
    late LocationQueueService queueService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      queueService = LocationQueueService();
      await queueService.init();
    });

    test('should start with empty queue', () async {
      expect(queueService.queueLength, 0);
      expect(queueService.isEmpty, true);
    });

    test('should enqueue location updates', () async {
      await queueService.enqueue(12.9716, 77.5946, DateTime.now());
      expect(queueService.queueLength, 1);

      await queueService.enqueue(12.9720, 77.5950, DateTime.now());
      expect(queueService.queueLength, 2);
    });

    test('should limit queue size to 100 entries', () async {
      // Add 105 entries
      for (int i = 0; i < 105; i++) {
        await queueService.enqueue(12.0 + i * 0.001, 77.0 + i * 0.001, DateTime.now());
      }

      // Should be capped at 100
      expect(queueService.queueLength, 100);

      // Should keep most recent (last 100)
      final all = await queueService.getAll();
      expect(all[0]['latitude'], closeTo(12.005, 0.0001));
    });

    // ... additional tests ...
  });
}
```

**Test Coverage:**
| Test | Purpose |
|------|---------|
| Empty queue | Verify initial state |
| Enqueue updates | Basic queue functionality |
| Return all items | Retrieval works correctly |
| Most recent update | Last item retrieval |
| Null for empty mostRecent | Edge case handling |
| Clear queue | Cleanup functionality |
| **Queue size limit** | Prevents unbounded growth |
| Persistence | Survives reinitialization |
| ISO8601 timestamp | Correct date formatting |

**Test Results:**
```
00:10 +9: All tests passed!
```

---

### Step 4.3: Commit Changes ✅

**Files Modified/Created:**
- `lib/services/location_queue_service.dart` (enhanced)
- `test/services/location_queue_service_test.dart` (new)

---

## Success Criteria Checklist

- [x] Queue persists location updates to SharedPreferences
- [x] Queue size limited to 100 entries to prevent memory issues
- [x] Most recent update retrievable for sync
- [x] Clear function works correctly
- [x] Comprehensive unit tests pass

---

## Common Pitfalls Avoided

| Pitfall | How We Avoided It | Verification |
|---------|-------------------|--------------|
| Unbounded queue growth | Cap at 100 entries, keep most recent | ✅ Test confirms limit |
| JSON parse errors | Wrap in try-catch, clear if corrupted | ✅ Existing error handling |
| Not initializing SharedPreferences | Call init() before any operation | ✅ Guard clauses in methods |
| Losing newest data | Remove oldest entries, keep newest | ✅ Test confirms order |

---

## Architecture: Queue Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Location Update Flow                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐                                           │
│  │   Geolocator  │                                           │
│  │   Position    │                                           │
│  └──────┬───────┘                                           │
│         │                                                    │
│         ▼                                                    │
│  ┌──────────────────┐                                       │
│  │ LocationManager   │                                       │
│  │ _handleLocation() │                                       │
│  └────────┬─────────┘                                       │
│           │                                                  │
│     ┌─────┴─────┐                                           │
│     │           │                                           │
│  Online?     Offline?                                       │
│     │           │                                           │
│     ▼           ▼                                           │
│ ┌────────┐  ┌─────────────────┐                             │
│ │Firebase │  │LocationQueueSvc │                             │
│ │ Update  │  │   .enqueue()    │                             │
│ └────────┘  └────────┬────────┘                             │
│                      │                                       │
│                      ▼                                       │
│              ┌───────────────┐                              │
│              │ SharedPrefs    │                              │
│              │ JSON Storage   │                              │
│              └───────────────┘                              │
│                      │                                       │
│                      │ On reconnect                         │
│                      ▼                                       │
│              ┌───────────────┐                              │
│              │ _flushQueue() │                              │
│              │ Most recent → │────────────▶ Firebase        │
│              │ Clear queue   │                              │
│              └───────────────┘                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Queue Size Limit Behavior

```
Initial state (< 100 items):
┌─────────────────────────────────────────────┐
│ [loc1] [loc2] [loc3] ... [loc50]            │
└─────────────────────────────────────────────┘
Queue length: 50  ✓ Under limit

After many offline updates (> 100 items):
┌─────────────────────────────────────────────┐
│ [loc6] [loc7] [loc8] ... [loc105]           │
│  ↑                        ↑                  │
│  Oldest kept             Most recent        │
└─────────────────────────────────────────────┘
Queue length: 100  ✓ Capped at limit
[loc1-loc5] discarded (oldest)
```

---

## Integration with LocationManager

The queue is used by LocationManager in two scenarios:

### 1. When Offline
```dart
// In LocationManager._handleLocationUpdate()
if (!_isOnline) {
  await _queueService.enqueue(latitude, longitude, timestamp);
  await _foregroundService.updateNotification(
    'Offline - ${_queueService.queueLength} updates pending',
  );
}
```

### 2. When Coming Back Online
```dart
// In LocationManager._flushQueue()
final queuedUpdates = await _queueService.getAll();
if (queuedUpdates.isEmpty) return;

// Only send the most recent update
final mostRecent = queuedUpdates.last;
await _databaseService.updateVendorLocation(
  _vendorId!,
  mostRecent['latitude'] as double,
  mostRecent['longitude'] as double,
);

await _queueService.clear();
```

---

## Files Modified/Created

### 1. [lib/services/location_queue_service.dart](../../lib/services/location_queue_service.dart)

**Changes:**
- Added `_maxQueueSize` constant (100)
- Modified `enqueue()` to trim queue when exceeding limit

**Line count:** 77 lines

### 2. [test/services/location_queue_service_test.dart](../../test/services/location_queue_service_test.dart) (NEW)

**Test Groups:**
- LocationQueueService (9 tests)

**Line count:** 96 lines

---

## Metrics

| Metric | Value |
|--------|-------|
| Files modified | 1 |
| Files created | 1 |
| Lines of code added | ~105 |
| Unit tests added | 9 |
| Test pass rate | 100% |

---

## Testing Commands

```bash
# Run queue service tests
flutter test test/services/location_queue_service_test.dart

# Run all tests
flutter test
```

---

## Data Persistence Format

The queue is stored in SharedPreferences as JSON:

```json
[
  {
    "latitude": 12.9716,
    "longitude": 77.5946,
    "timestamp": "2026-01-17T10:30:00.000"
  },
  {
    "latitude": 12.9720,
    "longitude": 77.5950,
    "timestamp": "2026-01-17T10:30:30.000"
  }
]
```

**Key:** `location_queue`

---

## Edge Cases Handled

| Edge Case | Handling |
|-----------|----------|
| Empty queue | Returns empty list, null for mostRecent |
| Corrupted JSON | Clears queue, returns empty |
| Queue overflow | Discards oldest, keeps 100 most recent |
| App restart | Loads persisted queue on init() |
| Multiple rapid updates | Each queued with unique timestamp |

---

## Dependencies

- `shared_preferences: ^2.5.3` - Local storage for queue
- `flutter_test` - Unit testing framework

---

**Task 4 Complete** ✅
**Ready for Phase 2 - Task 5 (Vendor UI Toggle)** ✅
