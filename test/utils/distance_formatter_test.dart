import 'package:flutter_test/flutter_test.dart';
import 'package:food_vendor_app/utils/distance_formatter.dart';

void main() {
  group('DistanceFormatter', () {
    group('format', () {
      test('returns "Unknown" for null distance', () {
        expect(DistanceFormatter.format(null), 'Unknown');
      });

      test('formats distances less than 100m in meters', () {
        expect(DistanceFormatter.format(0.05), '50 m');
        expect(DistanceFormatter.format(0.01), '10 m');
        expect(DistanceFormatter.format(0.099), '99 m');
      });

      test('formats distances 100m to 1km in meters', () {
        expect(DistanceFormatter.format(0.1), '100 m');
        expect(DistanceFormatter.format(0.5), '500 m');
        expect(DistanceFormatter.format(0.999), '999 m');
      });

      test('formats distances 1km to 10km with one decimal', () {
        expect(DistanceFormatter.format(1.0), '1.0 km');
        expect(DistanceFormatter.format(1.5), '1.5 km');
        expect(DistanceFormatter.format(5.25), '5.3 km'); // rounds to 5.3
        expect(DistanceFormatter.format(9.99), '10.0 km');
      });

      test('formats distances 10km and above without decimals', () {
        expect(DistanceFormatter.format(10.0), '10 km');
        expect(DistanceFormatter.format(15.5), '16 km');
        expect(DistanceFormatter.format(100.0), '100 km');
        expect(DistanceFormatter.format(999.9), '1000 km');
      });

      test('handles zero distance', () {
        expect(DistanceFormatter.format(0.0), '0 m');
      });

      test('handles very small distances', () {
        expect(DistanceFormatter.format(0.001), '1 m');
        expect(DistanceFormatter.format(0.0001), '0 m');
      });

      test('handles very large distances', () {
        expect(DistanceFormatter.format(1000.0), '1000 km');
        expect(DistanceFormatter.format(10000.0), '10000 km');
      });
    });

    group('walkingTime', () {
      test('returns empty string for null distance', () {
        expect(DistanceFormatter.walkingTime(null), '');
      });

      test('returns "< 1 min walk" for very short distances', () {
        // 0.01km → 0.12 min → rounds to 0 → "< 1 min walk"
        expect(DistanceFormatter.walkingTime(0.01), '< 1 min walk');
        // 0.03km → 0.36 min → rounds to 0 → "< 1 min walk"
        expect(DistanceFormatter.walkingTime(0.03), '< 1 min walk');
      });

      test('returns "1 min walk" for ~83m distance', () {
        // 83m at 5km/h = 1 minute
        expect(DistanceFormatter.walkingTime(0.083), '1 min walk');
      });

      test('calculates minutes correctly for short walks', () {
        // 5 km/h = 83.33 m/min
        // 500m should be ~6 minutes
        expect(DistanceFormatter.walkingTime(0.5), '6 min walk');

        // 1km should be 12 minutes
        expect(DistanceFormatter.walkingTime(1.0), '12 min walk');
      });

      test('calculates minutes correctly for medium walks', () {
        // 2km should be 24 minutes
        expect(DistanceFormatter.walkingTime(2.0), '24 min walk');

        // 4km should be 48 minutes
        expect(DistanceFormatter.walkingTime(4.0), '48 min walk');
      });

      test('formats walks exactly 1 hour', () {
        // 5km at 5km/h = 60 minutes = 1 hour
        expect(DistanceFormatter.walkingTime(5.0), '1 hr walk');
      });

      test('formats walks over 1 hour with hours and minutes', () {
        // 6km at 5km/h = 72 minutes = 1 hr 12 min
        expect(DistanceFormatter.walkingTime(6.0), '1 hr 12 min walk');

        // 7.5km at 5km/h = 90 minutes = 1 hr 30 min
        expect(DistanceFormatter.walkingTime(7.5), '1 hr 30 min walk');
      });

      test('formats multi-hour walks', () {
        // 10km at 5km/h = 120 minutes = 2 hr
        expect(DistanceFormatter.walkingTime(10.0), '2 hr walk');

        // 12.5km at 5km/h = 150 minutes = 2 hr 30 min
        expect(DistanceFormatter.walkingTime(12.5), '2 hr 30 min walk');
      });

      test('handles zero distance', () {
        expect(DistanceFormatter.walkingTime(0.0), '< 1 min walk');
      });

      test('walking speed assumption is 5 km/h', () {
        // Verify the 5 km/h assumption
        // Walking 5km should take exactly 60 minutes
        final walkTime5km = DistanceFormatter.walkingTime(5.0);
        expect(walkTime5km, '1 hr walk');

        // Walking 10km should take exactly 120 minutes
        final walkTime10km = DistanceFormatter.walkingTime(10.0);
        expect(walkTime10km, '2 hr walk');
      });
    });

    group('edge cases', () {
      test('format handles boundary at 0.1km', () {
        expect(DistanceFormatter.format(0.0999), '100 m');
        expect(DistanceFormatter.format(0.1001), '100 m');
      });

      test('format handles boundary at 1km', () {
        expect(DistanceFormatter.format(0.999), '999 m');
        expect(DistanceFormatter.format(1.001), '1.0 km');
      });

      test('format handles boundary at 10km', () {
        expect(DistanceFormatter.format(9.99), '10.0 km');
        expect(DistanceFormatter.format(10.01), '10 km');
      });

      test('walkingTime handles boundary at 1 minute', () {
        // Just under 1 minute (rounds to 0): 0.03km → 0.36 min → rounds to 0
        expect(DistanceFormatter.walkingTime(0.03), '< 1 min walk');
        // Just over 1 minute (rounds to 1): 0.05km → 0.6 min → rounds to 1
        expect(DistanceFormatter.walkingTime(0.05), '1 min walk');
        // 0.09km → 1.08 min → rounds to 1
        expect(DistanceFormatter.walkingTime(0.09), '1 min walk');
      });

      test('walkingTime handles boundary at 60 minutes', () {
        // Just under 60 minutes
        expect(DistanceFormatter.walkingTime(4.9), '59 min walk');
        // Exactly 60 minutes
        expect(DistanceFormatter.walkingTime(5.0), '1 hr walk');
        // Just over 60 minutes
        expect(DistanceFormatter.walkingTime(5.1), '1 hr 1 min walk');
      });
    });

    group('realistic scenarios', () {
      test('formats typical food vendor distances', () {
        // Very close vendor (50m) - 0.05km → 0.6 min → rounds to 1
        expect(DistanceFormatter.format(0.05), '50 m');
        expect(DistanceFormatter.walkingTime(0.05), '1 min walk');

        // Nearby vendor (200m)
        expect(DistanceFormatter.format(0.2), '200 m');
        expect(DistanceFormatter.walkingTime(0.2), '2 min walk');

        // Down the street (500m)
        expect(DistanceFormatter.format(0.5), '500 m');
        expect(DistanceFormatter.walkingTime(0.5), '6 min walk');

        // A few blocks (1km)
        expect(DistanceFormatter.format(1.0), '1.0 km');
        expect(DistanceFormatter.walkingTime(1.0), '12 min walk');

        // Across town (5km)
        expect(DistanceFormatter.format(5.0), '5.0 km');
        expect(DistanceFormatter.walkingTime(5.0), '1 hr walk');
      });
    });
  });
}
