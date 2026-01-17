import 'package:cloud_firestore/cloud_firestore.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  GeoPoint toGeoPoint() {
    return GeoPoint(latitude, longitude);
  }

  factory LocationData.fromGeoPoint(GeoPoint geoPoint, DateTime timestamp) {
    return LocationData(
      latitude: geoPoint.latitude,
      longitude: geoPoint.longitude,
      timestamp: timestamp,
    );
  }
}
