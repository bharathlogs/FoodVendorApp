import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItem {
  final String itemId;
  final String name;
  final double price;
  final String? description;
  final String? imageUrl;
  final bool isAvailable;
  final DateTime createdAt;

  MenuItem({
    required this.itemId,
    required this.name,
    required this.price,
    this.description,
    this.imageUrl,
    required this.isAvailable,
    required this.createdAt,
  });

  factory MenuItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MenuItem(
      itemId: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      description: data['description'],
      imageUrl: data['imageUrl'],
      isAvailable: data['isAvailable'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
