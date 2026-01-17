import 'package:cloud_firestore/cloud_firestore.dart';

class VendorProfile {
  final String vendorId;
  final String businessName;
  final String description;
  final List<String> cuisineTags;
  final bool isActive;
  final GeoPoint? location;
  final DateTime? locationUpdatedAt;
  final String? profileImageUrl;

  VendorProfile({
    required this.vendorId,
    required this.businessName,
    required this.description,
    required this.cuisineTags,
    required this.isActive,
    this.location,
    this.locationUpdatedAt,
    this.profileImageUrl,
  });

  factory VendorProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VendorProfile(
      vendorId: doc.id,
      businessName: data['businessName'] ?? '',
      description: data['description'] ?? '',
      cuisineTags: List<String>.from(data['cuisineTags'] ?? []),
      isActive: data['isActive'] ?? false,
      location: data['location'] as GeoPoint?,
      locationUpdatedAt: data['locationUpdatedAt'] != null
          ? (data['locationUpdatedAt'] as Timestamp).toDate()
          : null,
      profileImageUrl: data['profileImageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'businessName': businessName,
      'description': description,
      'cuisineTags': cuisineTags,
      'isActive': isActive,
      'location': location,
      'locationUpdatedAt': locationUpdatedAt != null
          ? Timestamp.fromDate(locationUpdatedAt!)
          : null,
      'profileImageUrl': profileImageUrl,
    };
  }
}
