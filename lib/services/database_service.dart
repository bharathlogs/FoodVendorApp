import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/vendor_profile.dart';
import '../models/menu_item.dart';
import '../models/order.dart' as models;

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============ USER OPERATIONS ============

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  // ============ VENDOR PROFILE OPERATIONS ============

  Future<VendorProfile?> getVendorProfile(String vendorId) async {
    final doc =
        await _firestore.collection('vendor_profiles').doc(vendorId).get();
    if (!doc.exists) return null;
    return VendorProfile.fromFirestore(doc);
  }

  Future<void> updateVendorProfile(
      String vendorId, Map<String, dynamic> data) async {
    await _firestore.collection('vendor_profiles').doc(vendorId).update(data);
  }

  // Maximum vendors to load on map (for performance)
  static const int maxVendorsOnMap = 50;

  // Get all active vendors (for Phase 4 map)
  Stream<List<VendorProfile>> getActiveVendorsStream() {
    return _firestore
        .collection('vendor_profiles')
        .where('isActive', isEqualTo: true)
        .limit(maxVendorsOnMap)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VendorProfile.fromFirestore(doc))
            .toList());
  }

  /// Get active vendors that have updated within the timeout window
  /// This filters out vendors that appear "active" but haven't sent updates
  Stream<List<VendorProfile>> getActiveVendorsWithFreshnessCheck() {
    final cutoffTime = DateTime.now().subtract(const Duration(minutes: 10));

    return _firestore
        .collection('vendor_profiles')
        .where('isActive', isEqualTo: true)
        .limit(maxVendorsOnMap)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => VendorProfile.fromFirestore(doc))
              .where((vendor) {
                // Filter out vendors with stale locations
                if (vendor.locationUpdatedAt == null) return false;
                return vendor.locationUpdatedAt!.isAfter(cutoffTime);
              })
              .toList();
        });
  }

  // Get vendors filtered by cuisine (for Phase 4)
  Stream<List<VendorProfile>> getVendorsByCuisineStream(String cuisineTag) {
    return _firestore
        .collection('vendor_profiles')
        .where('isActive', isEqualTo: true)
        .where('cuisineTags', arrayContains: cuisineTag)
        .limit(maxVendorsOnMap)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VendorProfile.fromFirestore(doc))
            .toList());
  }

  // Update vendor location (for Phase 2)
  Future<void> updateVendorLocation(
    String vendorId,
    double latitude,
    double longitude,
  ) async {
    await _firestore.collection('vendor_profiles').doc(vendorId).update({
      'location': GeoPoint(latitude, longitude),
      'locationUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Toggle vendor active status (for Phase 2)
  Future<void> setVendorActiveStatus(String vendorId, bool isActive) async {
    await _firestore.collection('vendor_profiles').doc(vendorId).update({
      'isActive': isActive,
    });
  }

  // ============ MENU OPERATIONS ============

  // Get all menu items for a vendor
  Stream<List<MenuItem>> getMenuItemsStream(String vendorId) {
    return _firestore
        .collection('vendor_profiles')
        .doc(vendorId)
        .collection('menu_items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MenuItem.fromFirestore(doc)).toList());
  }

  // Get menu item count for a vendor
  Future<int> getMenuItemCount(String vendorId) async {
    final snapshot = await _firestore
        .collection('vendor_profiles')
        .doc(vendorId)
        .collection('menu_items')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  // Add menu item (for Phase 3) with 50 item limit
  static const int maxMenuItems = 50;

  Future<String> addMenuItem(String vendorId, MenuItem item) async {
    // Check item limit before adding
    final currentCount = await getMenuItemCount(vendorId);
    if (currentCount >= maxMenuItems) {
      throw Exception('Menu item limit reached ($maxMenuItems items maximum)');
    }

    final docRef = await _firestore
        .collection('vendor_profiles')
        .doc(vendorId)
        .collection('menu_items')
        .add(item.toFirestore());
    return docRef.id;
  }

  // Update menu item (for Phase 3)
  Future<void> updateMenuItem(
    String vendorId,
    String itemId,
    Map<String, dynamic> data,
  ) async {
    await _firestore
        .collection('vendor_profiles')
        .doc(vendorId)
        .collection('menu_items')
        .doc(itemId)
        .update(data);
  }

  // Delete menu item (for Phase 3)
  Future<void> deleteMenuItem(String vendorId, String itemId) async {
    await _firestore
        .collection('vendor_profiles')
        .doc(vendorId)
        .collection('menu_items')
        .doc(itemId)
        .delete();
  }

  // ============ ORDER OPERATIONS ============

  // Create new order (for Phase 3)
  Future<String> createOrder(models.Order order) async {
    final docRef =
        await _firestore.collection('orders').add(order.toFirestore());
    return docRef.id;
  }

  // Get orders for a vendor (for Phase 3)
  Stream<List<models.Order>> getVendorOrdersStream(String vendorId) {
    return _firestore
        .collection('orders')
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => models.Order.fromFirestore(doc)).toList());
  }

  // Update order status (for Phase 3)
  Future<void> updateOrderStatus(String orderId, models.OrderStatus status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status.toString().split('.').last,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============ UTILITY METHODS ============

  // Batch write for multiple updates (useful for Phase 2 location batching)
  Future<void> batchUpdate(
      List<Map<String, dynamic>> updates, String collection) async {
    final batch = _firestore.batch();

    for (final update in updates) {
      final docRef = _firestore.collection(collection).doc(update['id']);
      batch.update(docRef, update['data']);
    }

    await batch.commit();
  }
}
