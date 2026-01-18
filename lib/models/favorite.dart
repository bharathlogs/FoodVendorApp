import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a customer's favorite vendor
class Favorite {
  final String favoriteId;
  final String customerId;
  final String vendorId;
  final DateTime createdAt;

  Favorite({
    required this.favoriteId,
    required this.customerId,
    required this.vendorId,
    required this.createdAt,
  });

  factory Favorite.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Favorite(
      favoriteId: doc.id,
      customerId: data['customerId'] ?? '',
      vendorId: data['vendorId'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'vendorId': vendorId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
