import 'package:dart_geohash/dart_geohash.dart';

/// Utility class for geohash operations
class GeohashUtils {
  static final _geoHasher = GeoHasher();

  /// Default precision for geohash encoding
  /// Precision 7 gives approximately 153m x 153m accuracy
  static const int defaultPrecision = 7;

  /// Encode latitude and longitude to a geohash string
  static String encode(double latitude, double longitude,
      {int precision = defaultPrecision}) {
    return _geoHasher.encode(longitude, latitude, precision: precision);
  }

  /// Decode a geohash string to latitude and longitude
  static ({double latitude, double longitude}) decode(String geohash) {
    final decoded = _geoHasher.decode(geohash);
    return (latitude: decoded[1], longitude: decoded[0]);
  }

  /// Get neighboring geohashes for a given geohash
  /// Returns all 8 neighbors plus the center geohash (9 total)
  static List<String> getNeighborsWithCenter(String geohash) {
    final neighbors = _geoHasher.neighbors(geohash);
    return [
      geohash, // Center
      neighbors['top']!,
      neighbors['topRight']!,
      neighbors['right']!,
      neighbors['bottomRight']!,
      neighbors['bottom']!,
      neighbors['bottomLeft']!,
      neighbors['left']!,
      neighbors['topLeft']!,
    ];
  }

  /// Get query prefixes for searching vendors near a location
  /// Uses a shorter precision to cover a larger area, then gets neighbors
  static List<String> getQueryPrefixes(
    double latitude,
    double longitude, {
    int queryPrecision = 5, // ~5km x 5km area
  }) {
    final centerHash = encode(latitude, longitude, precision: queryPrecision);
    return getNeighborsWithCenter(centerHash);
  }

  /// Get geohash bounds (min/max lat/lng)
  static ({
    double minLat,
    double maxLat,
    double minLng,
    double maxLng,
  }) getBounds(String geohash) {
    // Decode to get center point
    final center = decode(geohash);

    // Calculate approximate bounds based on precision
    // Each character adds about 5 bits of precision
    final precision = geohash.length;

    // Approximate cell sizes at different precisions (at equator)
    // Precision 1: ~5,000km, 2: ~1,250km, 3: ~156km, 4: ~39km
    // 5: ~5km, 6: ~1.2km, 7: ~153m, 8: ~38m
    final latError = _getLatError(precision);
    final lngError = _getLngError(precision);

    return (
      minLat: center.latitude - latError,
      maxLat: center.latitude + latError,
      minLng: center.longitude - lngError,
      maxLng: center.longitude + lngError,
    );
  }

  static double _getLatError(int precision) {
    const latErrors = <int, double>{
      1: 23.0,
      2: 2.8,
      3: 0.7,
      4: 0.087,
      5: 0.022,
      6: 0.0027,
      7: 0.00068,
      8: 0.000085,
    };
    return latErrors[precision] ?? 0.00068;
  }

  static double _getLngError(int precision) {
    const lngErrors = <int, double>{
      1: 23.0,
      2: 5.6,
      3: 0.7,
      4: 0.18,
      5: 0.022,
      6: 0.0055,
      7: 0.00068,
      8: 0.00017,
    };
    return lngErrors[precision] ?? 0.00068;
  }

  /// Calculate distance between two points in kilometers (Haversine formula)
  static double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371.0; // Earth's radius in kilometers
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) *
            _cos(_toRadians(lat2)) *
            _sin(dLng / 2) *
            _sin(dLng / 2);

    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * 3.14159265359 / 180;
  static double _sin(double x) => _taylorSin(x);
  static double _cos(double x) => _taylorCos(x);
  static double _sqrt(double x) => _babylonianSqrt(x);
  static double _atan2(double y, double x) => _approximateAtan2(y, x);

  // Simple Taylor series approximations for trig functions
  static double _taylorSin(double x) {
    // Normalize to [-pi, pi]
    while (x > 3.14159265359) x -= 2 * 3.14159265359;
    while (x < -3.14159265359) x += 2 * 3.14159265359;

    double result = x;
    double term = x;
    for (int n = 1; n <= 10; n++) {
      term *= -x * x / ((2 * n) * (2 * n + 1));
      result += term;
    }
    return result;
  }

  static double _taylorCos(double x) {
    // Normalize to [-pi, pi]
    while (x > 3.14159265359) x -= 2 * 3.14159265359;
    while (x < -3.14159265359) x += 2 * 3.14159265359;

    double result = 1;
    double term = 1;
    for (int n = 1; n <= 10; n++) {
      term *= -x * x / ((2 * n - 1) * (2 * n));
      result += term;
    }
    return result;
  }

  static double _babylonianSqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  static double _approximateAtan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.14159265359;
    if (x < 0 && y < 0) return _atan(y / x) - 3.14159265359;
    if (x == 0 && y > 0) return 3.14159265359 / 2;
    if (x == 0 && y < 0) return -3.14159265359 / 2;
    return 0;
  }

  static double _atan(double x) {
    // For small x, use Taylor series
    if (x.abs() <= 1) {
      double result = x;
      double term = x;
      for (int n = 1; n <= 20; n++) {
        term *= -x * x;
        result += term / (2 * n + 1);
      }
      return result;
    }
    // For large x, use identity: atan(x) = pi/2 - atan(1/x)
    return (x > 0 ? 3.14159265359 / 2 : -3.14159265359 / 2) - _atan(1 / x);
  }
}
