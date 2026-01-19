import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String reviewId;
  final String vendorId;
  final String customerId;
  final String customerName;
  final int rating; // 1-5
  final String? comment;
  final DateTime createdAt;

  Review({
    required this.reviewId,
    required this.vendorId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      reviewId: doc.id,
      vendorId: data['vendorId'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? 'Anonymous',
      rating: data['rating'] ?? 0,
      comment: data['comment'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'vendorId': vendorId,
      'customerId': customerId,
      'customerName': customerName,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Review copyWith({
    String? reviewId,
    String? vendorId,
    String? customerId,
    String? customerName,
    int? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return Review(
      reviewId: reviewId ?? this.reviewId,
      vendorId: vendorId ?? this.vendorId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
