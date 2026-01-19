import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/vendor_profile.dart';
import '../models/menu_item.dart';
import '../models/order.dart' as models;
import '../models/favorite.dart';
import '../models/review.dart';
import '../utils/geohash_utils.dart';

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

  // ============ GEOHASH-BASED QUERIES ============

  /// Get active vendors near a location using geohash-based queries
  /// This is more efficient than loading all vendors for large datasets
  Stream<List<VendorProfile>> getVendorsNearLocation(
    double latitude,
    double longitude, {
    int queryPrecision = 5, // ~5km radius
  }) {
    // Get geohash prefixes for the area (center + 8 neighbors)
    final prefixes = GeohashUtils.getQueryPrefixes(
      latitude,
      longitude,
      queryPrecision: queryPrecision,
    );

    // Query for vendors matching any of the geohash prefixes
    // We use the center geohash for the primary query
    final centerHash = prefixes.first;

    return _firestore
        .collection('vendor_profiles')
        .where('isActive', isEqualTo: true)
        .where('geohash', isGreaterThanOrEqualTo: centerHash)
        .where('geohash', isLessThan: '${centerHash}~')
        .limit(maxVendorsOnMap)
        .snapshots()
        .map((snapshot) {
      final vendors = snapshot.docs
          .map((doc) => VendorProfile.fromFirestore(doc))
          .toList();

      // Sort by distance from the query point
      vendors.sort((a, b) {
        if (a.location == null) return 1;
        if (b.location == null) return -1;

        final distA = GeohashUtils.calculateDistance(
          latitude,
          longitude,
          a.location!.latitude,
          a.location!.longitude,
        );
        final distB = GeohashUtils.calculateDistance(
          latitude,
          longitude,
          b.location!.latitude,
          b.location!.longitude,
        );
        return distA.compareTo(distB);
      });

      return vendors;
    });
  }

  /// Get vendors near a location with expanded search (queries multiple geohash cells)
  /// Use this for more comprehensive nearby searches
  Future<List<VendorProfile>> getVendorsNearLocationExpanded(
    double latitude,
    double longitude, {
    int queryPrecision = 5,
    double maxDistanceKm = 10.0,
  }) async {
    final prefixes = GeohashUtils.getQueryPrefixes(
      latitude,
      longitude,
      queryPrecision: queryPrecision,
    );

    final allVendors = <VendorProfile>[];
    final seenIds = <String>{};

    // Query each geohash prefix
    for (final prefix in prefixes) {
      final snapshot = await _firestore
          .collection('vendor_profiles')
          .where('isActive', isEqualTo: true)
          .where('geohash', isGreaterThanOrEqualTo: prefix)
          .where('geohash', isLessThan: '${prefix}~')
          .limit(maxVendorsOnMap ~/ prefixes.length + 1)
          .get();

      for (final doc in snapshot.docs) {
        if (!seenIds.contains(doc.id)) {
          seenIds.add(doc.id);
          allVendors.add(VendorProfile.fromFirestore(doc));
        }
      }
    }

    // Filter by actual distance and sort
    final filtered = allVendors.where((vendor) {
      if (vendor.location == null) return false;
      final distance = GeohashUtils.calculateDistance(
        latitude,
        longitude,
        vendor.location!.latitude,
        vendor.location!.longitude,
      );
      return distance <= maxDistanceKm;
    }).toList();

    // Sort by distance
    filtered.sort((a, b) {
      final distA = GeohashUtils.calculateDistance(
        latitude,
        longitude,
        a.location!.latitude,
        a.location!.longitude,
      );
      final distB = GeohashUtils.calculateDistance(
        latitude,
        longitude,
        b.location!.latitude,
        b.location!.longitude,
      );
      return distA.compareTo(distB);
    });

    return filtered.take(maxVendorsOnMap).toList();
  }

  /// Backfill geohash for existing vendors that have locations but no geohash
  /// Call this once during migration
  Future<int> backfillGeohashes() async {
    final snapshot = await _firestore
        .collection('vendor_profiles')
        .where('geohash', isNull: true)
        .get();

    int updated = 0;
    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final location = data['location'] as GeoPoint?;

      if (location != null) {
        final geohash = GeohashUtils.encode(
          location.latitude,
          location.longitude,
        );
        batch.update(doc.reference, {'geohash': geohash});
        updated++;
      }
    }

    if (updated > 0) {
      await batch.commit();
    }

    return updated;
  }

  // Update vendor location (for Phase 2) with geohash
  Future<void> updateVendorLocation(
    String vendorId,
    double latitude,
    double longitude,
  ) async {
    // Compute geohash for efficient proximity queries
    final geohash = GeohashUtils.encode(latitude, longitude);

    await _firestore.collection('vendor_profiles').doc(vendorId).update({
      'location': GeoPoint(latitude, longitude),
      'locationUpdatedAt': FieldValue.serverTimestamp(),
      'geohash': geohash,
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

  // ============ REVIEW OPERATIONS ============

  /// Add a review for a vendor (one review per customer per vendor)
  Future<String> addReview(String vendorId, Review review) async {
    // Check if customer already reviewed this vendor
    final existing = await _firestore
        .collection('vendor_profiles')
        .doc(vendorId)
        .collection('reviews')
        .where('customerId', isEqualTo: review.customerId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('You have already reviewed this vendor');
    }

    final docRef = await _firestore
        .collection('vendor_profiles')
        .doc(vendorId)
        .collection('reviews')
        .add(review.toFirestore());

    // Update vendor's average rating
    await _updateVendorRating(vendorId);

    return docRef.id;
  }

  /// Update an existing review
  Future<void> updateReview(
    String vendorId,
    String reviewId,
    Review review,
  ) async {
    await _firestore
        .collection('vendor_profiles')
        .doc(vendorId)
        .collection('reviews')
        .doc(reviewId)
        .update(review.toFirestore());

    // Update vendor's average rating
    await _updateVendorRating(vendorId);
  }

  /// Delete a review
  Future<void> deleteReview(String vendorId, String reviewId) async {
    await _firestore
        .collection('vendor_profiles')
        .doc(vendorId)
        .collection('reviews')
        .doc(reviewId)
        .delete();

    // Update vendor's average rating
    await _updateVendorRating(vendorId);
  }

  /// Get stream of reviews for a vendor (paginated, newest first)
  Stream<List<Review>> getVendorReviewsStream(String vendorId) {
    return _firestore
        .collection('vendor_profiles')
        .doc(vendorId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList());
  }

  /// Get a specific user's review for a vendor (if exists)
  Future<Review?> getUserReviewForVendor(
    String vendorId,
    String customerId,
  ) async {
    final snapshot = await _firestore
        .collection('vendor_profiles')
        .doc(vendorId)
        .collection('reviews')
        .where('customerId', isEqualTo: customerId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return Review.fromFirestore(snapshot.docs.first);
  }

  /// Stream a specific user's review for a vendor
  Stream<Review?> getUserReviewForVendorStream(
    String vendorId,
    String customerId,
  ) {
    return _firestore
        .collection('vendor_profiles')
        .doc(vendorId)
        .collection('reviews')
        .where('customerId', isEqualTo: customerId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return Review.fromFirestore(snapshot.docs.first);
    });
  }

  /// Recalculate and update vendor's average rating
  Future<void> _updateVendorRating(String vendorId) async {
    final snapshot = await _firestore
        .collection('vendor_profiles')
        .doc(vendorId)
        .collection('reviews')
        .get();

    if (snapshot.docs.isEmpty) {
      await _firestore.collection('vendor_profiles').doc(vendorId).update({
        'averageRating': 0.0,
        'totalRatings': 0,
      });
      return;
    }

    final reviews = snapshot.docs.map((doc) => Review.fromFirestore(doc));
    final totalRatings = reviews.length;
    final sumRatings = reviews.fold<int>(0, (sum, r) => sum + r.rating);
    final averageRating = sumRatings / totalRatings;

    await _firestore.collection('vendor_profiles').doc(vendorId).update({
      'averageRating': averageRating,
      'totalRatings': totalRatings,
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
