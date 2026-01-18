# Task 2: Customer Location Permission

## Status: Complete (Implemented in Task 1)

## Overview
Request customer location permission and get their current position for showing nearby vendors and calculating distances.

---

## File Created

### `lib/services/customer_location_service.dart`

Location handling service with permission dialogs and distance calculation.

---

## Features Implemented

### 1. Permission Flow

```
User opens map
       │
       ▼
Check location services enabled?
       │
       ├── NO → Show "Location Services Disabled" dialog
       │              │
       │              └── "Open Settings" → Geolocator.openLocationSettings()
       │
       ▼
Check permission status
       │
       ├── denied → Show rationale dialog
       │              │
       │              └── "Allow" → requestPermission()
       │
       ├── deniedForever → Show settings dialog
       │                      │
       │                      └── "Open Settings" → Geolocator.openAppSettings()
       │
       └── granted → Get current position
```

### 2. Permission Dialogs

| Dialog | Trigger | Actions |
|--------|---------|---------|
| Location Services Disabled | GPS/Location off | Cancel, Open Settings |
| Permission Rationale | First time request | Not Now, Allow |
| Permission Required | Permanently denied | Cancel, Open Settings |

### 3. Location Retrieval

```dart
return await Geolocator.getCurrentPosition(
  locationSettings: const LocationSettings(
    accuracy: LocationAccuracy.high,
    timeLimit: Duration(seconds: 15),
  ),
);
```

**Settings:**
- Accuracy: High (best for urban areas)
- Timeout: 15 seconds (prevents indefinite waiting)

---

## API Reference

### CustomerLocationService

| Method | Returns | Description |
|--------|---------|-------------|
| `getCurrentLocation(context)` | `Future<Position?>` | Get GPS location with full permission handling |
| `calculateDistance(lat1, lon1, lat2, lon2)` | `double` | Haversine distance in kilometers |
| `formatDistance(distanceKm)` | `String` | Human-readable format ("500 m" or "2.3 km") |

---

## Haversine Formula

The service uses the Haversine formula for calculating great-circle distance between two points on Earth:

```dart
double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371; // Earth's radius in km

  final double dLat = _toRadians(lat2 - lat1);
  final double dLon = _toRadians(lon2 - lon1);

  final double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) *
          cos(_toRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);

  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadius * c;
}
```

**Why Haversine?**
- Accounts for Earth's curvature
- Accurate for distances up to hundreds of kilometers
- Simple to implement without external dependencies

---

## Distance Formatting

```dart
String formatDistance(double distanceKm) {
  if (distanceKm < 1) {
    return '${(distanceKm * 1000).round()} m';  // e.g., "500 m"
  } else {
    return '${distanceKm.toStringAsFixed(1)} km';  // e.g., "2.3 km"
  }
}
```

---

## Integration Points

### MapScreen
```dart
// In _initCustomerLocation()
final position = await _locationService.getCurrentLocation(context);
if (position != null) {
  _customerLocation = LatLng(position.latitude, position.longitude);
  _mapController.move(_customerLocation!, 15.0);
}
```

### VendorBottomSheet
```dart
// Calculate distance when showing vendor preview
if (_customerLocation != null && vendor.location != null) {
  distance = _locationService.calculateDistance(
    _customerLocation!.latitude,
    _customerLocation!.longitude,
    vendor.location!.latitude,
    vendor.location!.longitude,
  );
}
```

---

## Testing Checklist

- [x] Location permission rationale shown before request
- [x] Location services disabled dialog shown when GPS off
- [x] Permanent denial redirects to app settings
- [x] Current position retrieved with high accuracy
- [x] Timeout prevents infinite waiting (15 seconds)
- [x] Distance calculation accurate (Haversine)
- [x] Distance formatted correctly (meters < 1km, km >= 1km)
- [x] `context.mounted` checks prevent errors after navigation

---

## Common Pitfalls Avoided

| Pitfall | Solution |
|---------|----------|
| Timeout on slow GPS | `timeLimit: Duration(seconds: 15)` |
| Not handling all permission states | Separate handling for `denied` and `deniedForever` |
| Dialog shown after navigation | `context.mounted` check before showing dialogs |
| Inaccurate distance for large areas | Haversine formula accounts for Earth's curvature |

---

## Privacy Note

The rationale dialog includes: "Your location is never stored or shared."

Customer location is:
- Only used locally for distance calculation
- Not sent to any server
- Not stored in Firestore
- Refreshed each time map is opened
