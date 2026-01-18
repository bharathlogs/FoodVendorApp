import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/vendor_profile.dart';
import '../models/menu_item.dart';
import '../models/order.dart' as models;
import '../models/favorite.dart';

/// Result of a paginated query
class PaginatedResult<T> {
  final List<T> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  PaginatedResult({
    required this.items,
    this.lastDocument,
    required this.hasMore,
  });
}

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

  /// Search vendors by business name prefix
  /// Uses Firestore range query for "starts with" matching
  Stream<List<VendorProfile>> searchVendorsByName(String query) {
    if (query.isEmpty) {
      return getActiveVendorsWithFreshnessCheck();
    }

    final searchQuery = query.trim();
    final endQuery = '$searchQuery\uf8ff';

    return _firestore
        .collection('vendor_profiles')
        .where('isActive', isEqualTo: true)
        .where('businessName', isGreaterThanOrEqualTo: searchQuery)
        .where('businessName', isLessThan: endQuery)
        .limit(maxVendorsOnMap)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VendorProfile.fromFirestore(doc))
            .toList());
  }

  /// Search vendors with flexible case-insensitive matching
  /// Matches business name and cuisine tags (client-side filtering)
  Stream<List<VendorProfile>> searchVendorsFlexible(String query) {
    if (query.isEmpty) {
      return getActiveVendorsWithFreshnessCheck();
    }

    final searchLower = query.toLowerCase().trim();

    return getActiveVendorsWithFreshnessCheck().map((vendors) {
      return vendors.where((vendor) {
        if (vendor.businessName.toLowerCase().contains(searchLower)) {
          return true;
        }
        if (vendor.cuisineTags.any(
            (tag) => tag.toLowerCase().contains(searchLower))) {
          return true;
        }
        return false;
      }).toList();
    });
  }

  // ============ PAGINATED VENDOR OPERATIONS ============

  static const int vendorsPerPage = 10;

  /// Fetch paginated active vendors with freshness check
  /// Returns vendors that have updated within the timeout window
  Future<PaginatedResult<VendorProfile>> getActiveVendorsPaginated({
    DocumentSnapshot? startAfter,
    int limit = vendorsPerPage,
  }) async {
    final cutoffTime = DateTime.now().subtract(const Duration(minutes: 10));

    Query query = _firestore
        .collection('vendor_profiles')
        .where('isActive', isEqualTo: true)
        .orderBy('locationUpdatedAt', descending: true)
        .limit(limit + 1); // Fetch one extra to check if there are more

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final docs = snapshot.docs;

    // Check if there are more results
    final hasMore = docs.length > limit;
    final resultDocs = hasMore ? docs.sublist(0, limit) : docs;

    // Filter for freshness and convert to VendorProfile
    final vendors = resultDocs
        .map((doc) => VendorProfile.fromFirestore(doc))
        .where((vendor) {
          if (vendor.locationUpdatedAt == null) return false;
          return vendor.locationUpdatedAt!.isAfter(cutoffTime);
        })
        .toList();

    return PaginatedResult(
      items: vendors,
      lastDocument: resultDocs.isNotEmpty ? resultDocs.last : null,
      hasMore: hasMore,
    );
  }

  /// Fetch paginated vendors with flexible search
  Future<PaginatedResult<VendorProfile>> searchVendorsPaginated({
    required String query,
    DocumentSnapshot? startAfter,
    int limit = vendorsPerPage,
  }) async {
    if (query.isEmpty) {
      return getActiveVendorsPaginated(startAfter: startAfter, limit: limit);
    }

    // For search, we fetch more and filter client-side
    final result = await getActiveVendorsPaginated(
      startAfter: startAfter,
      limit: limit * 3, // Fetch more to account for filtering
    );

    final searchLower = query.toLowerCase().trim();
    final filtered = result.items.where((vendor) {
      if (vendor.businessName.toLowerCase().contains(searchLower)) {
        return true;
      }
      if (vendor.cuisineTags
          .any((tag) => tag.toLowerCase().contains(searchLower))) {
        return true;
      }
      return false;
    }).take(limit).toList();

    return PaginatedResult(
      items: filtered,
      lastDocument: result.lastDocument,
      hasMore: result.hasMore || filtered.length == limit,
    );
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

  // ============ FAVORITES OPERATIONS ============

  /// Add a vendor to customer's favorites
  Future<void> addFavorite(String customerId, String vendorId) async {
    // Check if already favorited to avoid duplicates
    final existing = await _firestore
        .collection('favorites')
        .where('customerId', isEqualTo: customerId)
        .where('vendorId', isEqualTo: vendorId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return; // Already favorited
    }

    final favorite = Favorite(
      favoriteId: '',
      customerId: customerId,
      vendorId: vendorId,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('favorites').add(favorite.toFirestore());
  }

  /// Remove a vendor from customer's favorites
  Future<void> removeFavorite(String customerId, String vendorId) async {
    final snapshot = await _firestore
        .collection('favorites')
        .where('customerId', isEqualTo: customerId)
        .where('vendorId', isEqualTo: vendorId)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  /// Check if a vendor is favorited by the customer
  Future<bool> isFavorite(String customerId, String vendorId) async {
    final snapshot = await _firestore
        .collection('favorites')
        .where('customerId', isEqualTo: customerId)
        .where('vendorId', isEqualTo: vendorId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Get stream of customer's favorite vendor IDs
  Stream<Set<String>> getFavoriteVendorIdsStream(String customerId) {
    return _firestore
        .collection('favorites')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc['vendorId'] as String).toSet());
  }

  /// Get customer's favorite vendors with full profile data
  Stream<List<VendorProfile>> getFavoriteVendorsStream(String customerId) {
    return _firestore
        .collection('favorites')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) {
        return <VendorProfile>[];
      }

      final vendorIds = snapshot.docs
          .map((doc) => doc['vendorId'] as String)
          .toList();

      // Fetch vendor profiles in batches (Firestore limit: 30 per whereIn)
      final vendors = <VendorProfile>[];
      for (var i = 0; i < vendorIds.length; i += 30) {
        final batchIds = vendorIds.skip(i).take(30).toList();
        final vendorSnapshot = await _firestore
            .collection('vendor_profiles')
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();

        vendors.addAll(
          vendorSnapshot.docs.map((doc) => VendorProfile.fromFirestore(doc)),
        );
      }

      return vendors;
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
