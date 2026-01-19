import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_vendor_app/models/favorite.dart';

void main() {
  group('Favorite', () {
    late FakeFirebaseFirestore fakeFirestore;
    late DateTime testDate;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      testDate = DateTime(2024, 5, 1, 12, 0);
    });

    group('constructor', () {
      test('creates Favorite with all required fields', () {
        final favorite = Favorite(
          favoriteId: 'fav123',
          customerId: 'customer456',
          vendorId: 'vendor789',
          createdAt: testDate,
        );

        expect(favorite.favoriteId, 'fav123');
        expect(favorite.customerId, 'customer456');
        expect(favorite.vendorId, 'vendor789');
        expect(favorite.createdAt, testDate);
      });
    });

    group('fromFirestore', () {
      test('parses favorite from Firestore document', () async {
        await fakeFirestore.collection('favorites').doc('fav123').set({
          'customerId': 'customer456',
          'vendorId': 'vendor789',
          'createdAt': Timestamp.fromDate(testDate),
        });

        final doc =
            await fakeFirestore.collection('favorites').doc('fav123').get();
        final favorite = Favorite.fromFirestore(doc);

        expect(favorite.favoriteId, 'fav123');
        expect(favorite.customerId, 'customer456');
        expect(favorite.vendorId, 'vendor789');
        expect(favorite.createdAt, testDate);
      });

      test('handles missing fields with defaults', () async {
        await fakeFirestore.collection('favorites').doc('fav456').set({
          'createdAt': Timestamp.fromDate(testDate),
        });

        final doc =
            await fakeFirestore.collection('favorites').doc('fav456').get();
        final favorite = Favorite.fromFirestore(doc);

        expect(favorite.favoriteId, 'fav456');
        expect(favorite.customerId, '');
        expect(favorite.vendorId, '');
      });

      test('defaults to current time when createdAt is null', () async {
        final beforeTest = DateTime.now().subtract(const Duration(seconds: 1));

        await fakeFirestore.collection('favorites').doc('fav789').set({
          'customerId': 'customer',
          'vendorId': 'vendor',
        });

        final doc =
            await fakeFirestore.collection('favorites').doc('fav789').get();
        final favorite = Favorite.fromFirestore(doc);

        expect(favorite.createdAt.isAfter(beforeTest), isTrue);
      });
    });

    group('toFirestore', () {
      test('converts favorite to Firestore map', () {
        final favorite = Favorite(
          favoriteId: 'fav123',
          customerId: 'customer456',
          vendorId: 'vendor789',
          createdAt: testDate,
        );

        final map = favorite.toFirestore();

        expect(map['customerId'], 'customer456');
        expect(map['vendorId'], 'vendor789');
        expect(map['createdAt'], isA<Timestamp>());
        expect((map['createdAt'] as Timestamp).toDate(), testDate);
        expect(map.containsKey('favoriteId'), isFalse);
      });
    });

    group('round-trip serialization', () {
      test('favorite survives round-trip', () async {
        final originalFavorite = Favorite(
          favoriteId: 'fav123',
          customerId: 'customer456',
          vendorId: 'vendor789',
          createdAt: testDate,
        );

        await fakeFirestore
            .collection('favorites')
            .doc(originalFavorite.favoriteId)
            .set(originalFavorite.toFirestore());

        final doc = await fakeFirestore
            .collection('favorites')
            .doc(originalFavorite.favoriteId)
            .get();
        final deserializedFavorite = Favorite.fromFirestore(doc);

        expect(deserializedFavorite.favoriteId, originalFavorite.favoriteId);
        expect(deserializedFavorite.customerId, originalFavorite.customerId);
        expect(deserializedFavorite.vendorId, originalFavorite.vendorId);
        expect(deserializedFavorite.createdAt, originalFavorite.createdAt);
      });
    });

    group('multiple favorites', () {
      test('can store multiple favorites per customer', () async {
        final favorite1 = Favorite(
          favoriteId: 'fav1',
          customerId: 'customer123',
          vendorId: 'vendor1',
          createdAt: testDate,
        );

        final favorite2 = Favorite(
          favoriteId: 'fav2',
          customerId: 'customer123',
          vendorId: 'vendor2',
          createdAt: testDate.add(const Duration(hours: 1)),
        );

        await fakeFirestore
            .collection('favorites')
            .doc(favorite1.favoriteId)
            .set(favorite1.toFirestore());

        await fakeFirestore
            .collection('favorites')
            .doc(favorite2.favoriteId)
            .set(favorite2.toFirestore());

        final querySnapshot = await fakeFirestore
            .collection('favorites')
            .where('customerId', isEqualTo: 'customer123')
            .get();

        expect(querySnapshot.docs.length, 2);
      });
    });
  });
}
