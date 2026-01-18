/// Utility class for formatting distances and estimating travel times
class DistanceFormatter {
  /// Format distance for display
  /// Shows meters if < 1km, otherwise km with appropriate precision
  static String format(double? distanceKm) {
    if (distanceKm == null) return 'Unknown';

    if (distanceKm < 0.1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)} m';
    } else if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)} m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceKm.toStringAsFixed(0)} km';
    }
  }

  /// Get walking time estimate (assuming 5 km/h walking speed)
  static String walkingTime(double? distanceKm) {
    if (distanceKm == null) return '';

    final minutes = (distanceKm / 5 * 60).round();

    if (minutes < 1) return '< 1 min walk';
    if (minutes == 1) return '1 min walk';
    if (minutes < 60) return '$minutes min walk';

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '$hours hr walk';
    }
    return '$hours hr $remainingMinutes min walk';
  }
}
