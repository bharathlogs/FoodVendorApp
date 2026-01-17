import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { vendor, customer }

class UserModel {
  final String uid;
  final String email;
  final UserRole role;
  final String displayName;
  final DateTime createdAt;
  final String? phoneNumber;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.displayName,
    required this.createdAt,
    this.phoneNumber,
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
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'role': role == UserRole.vendor ? 'vendor' : 'customer',
      'displayName': displayName,
      'createdAt': Timestamp.fromDate(createdAt),
      'phoneNumber': phoneNumber,
    };
  }
}
