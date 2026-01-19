import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_vendor_app/models/review.dart';

void main() {
  group('Review', () {
    late FakeFirebaseFirestore fakeFirestore;
    late DateTime testDate;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      testDate = DateTime(2024, 3, 20, 14, 45);
    });

    group('constructor', () {
      test('creates Review with required fields', () {
        final review = Review(
          reviewId: 'review123',
          vendorId: 'vendor456',
          customerId: 'customer789',
          customerName: 'John Doe',
          rating: 5,
          createdAt: testDate,
        );

        expect(review.reviewId, 'review123');
        expect(review.vendorId, 'vendor456');
        expect(review.customerId, 'customer789');
        expect(review.customerName, 'John Doe');
        expect(review.rating, 5);
        expect(review.comment, isNull);
        expect(review.createdAt, testDate);
      });

      test('creates Review with optional comment', () {
        final review = Review(
          reviewId: 'review123',
          vendorId: 'vendor456',
          customerId: 'customer789',
          customerName: 'Jane Doe',
          rating: 4,
          comment: 'Great food, friendly service!',
          createdAt: testDate,
        );

        expect(review.comment, 'Great food, friendly service!');
      });

      test('accepts ratings from 1 to 5', () {
        for (int i = 1; i <= 5; i++) {
          final review = Review(
            reviewId: 'review$i',
            vendorId: 'vendor',
            customerId: 'customer',
            customerName: 'Customer',
            rating: i,
            createdAt: testDate,
          );
          expect(review.rating, i);
        }
      });
    });

    group('fromFirestore', () {
      test('parses review with all fields', () async {
        await fakeFirestore.collection('reviews').doc('review123').set({
          'vendorId': 'vendor456',
          'customerId': 'customer789',
          'customerName': 'Test Customer',
          'rating': 4,
          'comment': 'Delicious tacos!',
          'createdAt': Timestamp.fromDate(testDate),
        });

        final doc =
            await fakeFirestore.collection('reviews').doc('review123').get();
        final review = Review.fromFirestore(doc);

        expect(review.reviewId, 'review123');
        expect(review.vendorId, 'vendor456');
        expect(review.customerId, 'customer789');
        expect(review.customerName, 'Test Customer');
        expect(review.rating, 4);
        expect(review.comment, 'Delicious tacos!');
        expect(review.createdAt, testDate);
      });

      test('parses review without comment', () async {
        await fakeFirestore.collection('reviews').doc('review456').set({
          'vendorId': 'vendor789',
          'customerId': 'customer101',
          'customerName': 'Silent Reviewer',
          'rating': 3,
          'createdAt': Timestamp.fromDate(testDate),
        });

        final doc =
            await fakeFirestore.collection('reviews').doc('review456').get();
        final review = Review.fromFirestore(doc);

        expect(review.comment, isNull);
        expect(review.rating, 3);
      });

      test('handles missing fields with defaults', () async {
        await fakeFirestore.collection('reviews').doc('review789').set({
          'createdAt': Timestamp.fromDate(testDate),
        });

        final doc =
            await fakeFirestore.collection('reviews').doc('review789').get();
        final review = Review.fromFirestore(doc);

        expect(review.vendorId, '');
        expect(review.customerId, '');
        expect(review.customerName, 'Anonymous');
        expect(review.rating, 0);
      });
    });

    group('toFirestore', () {
      test('converts review with comment to map', () {
        final review = Review(
          reviewId: 'review123',
          vendorId: 'vendor456',
          customerId: 'customer789',
          customerName: 'Test User',
          rating: 5,
          comment: 'Amazing!',
          createdAt: testDate,
        );

        final map = review.toFirestore();

        expect(map['vendorId'], 'vendor456');
        expect(map['customerId'], 'customer789');
        expect(map['customerName'], 'Test User');
        expect(map['rating'], 5);
        expect(map['comment'], 'Amazing!');
        expect(map['createdAt'], isA<Timestamp>());
        expect((map['createdAt'] as Timestamp).toDate(), testDate);
        expect(map.containsKey('reviewId'), isFalse);
      });

      test('converts review without comment to map', () {
        final review = Review(
          reviewId: 'review123',
          vendorId: 'vendor456',
          customerId: 'customer789',
          customerName: 'Test User',
          rating: 3,
          createdAt: testDate,
        );

        final map = review.toFirestore();

        expect(map['comment'], isNull);
      });
    });

    group('copyWith', () {
      test('creates copy with updated rating', () {
        final original = Review(
          reviewId: 'review123',
          vendorId: 'vendor456',
          customerId: 'customer789',
          customerName: 'Test User',
          rating: 3,
          comment: 'Good',
          createdAt: testDate,
        );

        final updated = original.copyWith(rating: 5);

        expect(updated.rating, 5);
        expect(updated.reviewId, original.reviewId);
        expect(updated.vendorId, original.vendorId);
        expect(updated.customerId, original.customerId);
        expect(updated.customerName, original.customerName);
        expect(updated.comment, original.comment);
        expect(updated.createdAt, original.createdAt);
      });

      test('creates copy with updated comment', () {
        final original = Review(
          reviewId: 'review123',
          vendorId: 'vendor456',
          customerId: 'customer789',
          customerName: 'Test User',
          rating: 4,
          comment: 'Original comment',
          createdAt: testDate,
        );

        final updated = original.copyWith(comment: 'Updated comment');

        expect(updated.comment, 'Updated comment');
        expect(updated.rating, original.rating);
      });

      test('creates copy with multiple updates', () {
        final original = Review(
          reviewId: 'review123',
          vendorId: 'vendor456',
          customerId: 'customer789',
          customerName: 'Test User',
          rating: 2,
          createdAt: testDate,
        );

        final newDate = DateTime(2024, 4, 1);
        final updated = original.copyWith(
          rating: 5,
          comment: 'Changed my mind!',
          createdAt: newDate,
        );

        expect(updated.rating, 5);
        expect(updated.comment, 'Changed my mind!');
        expect(updated.createdAt, newDate);
      });

      test('returns unchanged copy when no arguments provided', () {
        final original = Review(
          reviewId: 'review123',
          vendorId: 'vendor456',
          customerId: 'customer789',
          customerName: 'Test User',
          rating: 4,
          comment: 'Nice!',
          createdAt: testDate,
        );

        final copy = original.copyWith();

        expect(copy.reviewId, original.reviewId);
        expect(copy.vendorId, original.vendorId);
        expect(copy.customerId, original.customerId);
        expect(copy.customerName, original.customerName);
        expect(copy.rating, original.rating);
        expect(copy.comment, original.comment);
        expect(copy.createdAt, original.createdAt);
      });
    });

    group('round-trip serialization', () {
      test('review survives round-trip', () async {
        final originalReview = Review(
          reviewId: 'review123',
          vendorId: 'vendor456',
          customerId: 'customer789',
          customerName: 'Round Trip Reviewer',
          rating: 4,
          comment: 'Excellent food!',
          createdAt: testDate,
        );

        await fakeFirestore
            .collection('reviews')
            .doc(originalReview.reviewId)
            .set(originalReview.toFirestore());

        final doc = await fakeFirestore
            .collection('reviews')
            .doc(originalReview.reviewId)
            .get();
        final deserializedReview = Review.fromFirestore(doc);

        expect(deserializedReview.reviewId, originalReview.reviewId);
        expect(deserializedReview.vendorId, originalReview.vendorId);
        expect(deserializedReview.customerId, originalReview.customerId);
        expect(deserializedReview.customerName, originalReview.customerName);
        expect(deserializedReview.rating, originalReview.rating);
        expect(deserializedReview.comment, originalReview.comment);
        expect(deserializedReview.createdAt, originalReview.createdAt);
      });
    });
  });
}
