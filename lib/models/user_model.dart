import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { vendor, customer }

/// Notification preferences for push notification segmentation
class NotificationPreferences {
  final bool orderUpdates;
  final bool promotions;
  final bool vendorNearby;
  final bool newVendors;
  final List<String> favoriteCuisines;

  const NotificationPreferences({
    this.orderUpdates = true,
    this.promotions = true,
    this.vendorNearby = true,
    this.newVendors = false,
    this.favoriteCuisines = const [],
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const NotificationPreferences();
    return NotificationPreferences(
      orderUpdates: data['orderUpdates'] ?? true,
      promotions: data['promotions'] ?? true,
      vendorNearby: data['vendorNearby'] ?? true,
      newVendors: data['newVendors'] ?? false,
      favoriteCuisines: List<String>.from(data['favoriteCuisines'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderUpdates': orderUpdates,
      'promotions': promotions,
      'vendorNearby': vendorNearby,
      'newVendors': newVendors,
      'favoriteCuisines': favoriteCuisines,
    };
  }

  NotificationPreferences copyWith({
    bool? orderUpdates,
    bool? promotions,
    bool? vendorNearby,
    bool? newVendors,
    List<String>? favoriteCuisines,
  }) {
    return NotificationPreferences(
      orderUpdates: orderUpdates ?? this.orderUpdates,
      promotions: promotions ?? this.promotions,
      vendorNearby: vendorNearby ?? this.vendorNearby,
      newVendors: newVendors ?? this.newVendors,
      favoriteCuisines: favoriteCuisines ?? this.favoriteCuisines,
    );
  }
}

class UserModel {
  final String uid;
  final String email;
  final UserRole role;
  final String displayName;
  final DateTime createdAt;
  final String? phoneNumber;
  final NotificationPreferences notificationPreferences;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.displayName,
    required this.createdAt,
    this.phoneNumber,
    this.notificationPreferences = const NotificationPreferences(),
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      role: data['role'] == 'vendor' ? UserRole.vendor : UserRole.customer,
      displayName: data['displayName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      phoneNumber: data['phoneNumber'],
      notificationPreferences: NotificationPreferences.fromMap(
        data['notificationPreferences'] as Map<String, dynamic>?,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'role': role == UserRole.vendor ? 'vendor' : 'customer',
      'displayName': displayName,
      'createdAt': Timestamp.fromDate(createdAt),
      'phoneNumber': phoneNumber,
      'notificationPreferences': notificationPreferences.toMap(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    UserRole? role,
    String? displayName,
    DateTime? createdAt,
    String? phoneNumber,
    NotificationPreferences? notificationPreferences,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
    );
  }
}
