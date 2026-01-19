import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_vendor_app/models/vendor_profile.dart';

void main() {
  group('VendorProfile', () {
    late FakeFirebaseFirestore fakeFirestore;
    late DateTime testDate;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      testDate = DateTime(2024, 4, 15, 10, 30);
    });

    group('constructor', () {
      test('creates VendorProfile with required fields only', () {
        final profile = VendorProfile(
          vendorId: 'vendor123',
          businessName: 'Taco Truck',
          description: 'Best tacos in town',
          cuisineTags: ['Mexican', 'Tacos'],
          isActive: false,
        );

        expect(profile.vendorId, 'vendor123');
        expect(profile.businessName, 'Taco Truck');
        expect(profile.description, 'Best tacos in town');
        expect(profile.cuisineTags, ['Mexican', 'Tacos']);
        expect(profile.isActive, false);
        expect(profile.location, isNull);
        expect(profile.locationUpdatedAt, isNull);
        expect(profile.profileImageUrl, isNull);
        expect(profile.averageRating, 0.0);
        expect(profile.totalRatings, 0);
        expect(profile.geohash, isNull);
        expect(profile.phoneNumber, isNull);
      });

      test('creates VendorProfile with all fields', () {
        final location = const GeoPoint(37.7749, -122.4194);

        final profile = VendorProfile(
          vendorId: 'vendor456',
          businessName: 'Pizza Palace',
          description: 'Authentic Italian pizza',
          cuisineTags: ['Italian', 'Pizza'],
          isActive: true,
          location: location,
          locationUpdatedAt: testDate,
          profileImageUrl: 'https://example.com/pizza.jpg',
          averageRating: 4.5,
          totalRatings: 120,
          geohash: '9q8yyz',
          phoneNumber: '+1234567890',
        );

        expect(profile.location, location);
        expect(profile.locationUpdatedAt, testDate);
        expect(profile.profileImageUrl, 'https://example.com/pizza.jpg');
        expect(profile.averageRating, 4.5);
        expect(profile.totalRatings, 120);
        expect(profile.geohash, '9q8yyz');
        expect(profile.phoneNumber, '+1234567890');
      });

      test('accepts empty cuisine tags list', () {
        final profile = VendorProfile(
          vendorId: 'vendor789',
          businessName: 'New Vendor',
          description: '',
          cuisineTags: [],
          isActive: false,
        );

        expect(profile.cuisineTags, isEmpty);
      });
    });

    group('fromFirestore', () {
      test('parses vendor profile with all fields', () async {
        await fakeFirestore.collection('vendor_profiles').doc('vendor123').set({
          'businessName': 'Test Restaurant',
          'description': 'Test description',
          'cuisineTags': ['Indian', 'Curry'],
          'isActive': true,
          'location': const GeoPoint(40.7128, -74.0060),
          'locationUpdatedAt': Timestamp.fromDate(testDate),
          'profileImageUrl': 'https://example.com/test.jpg',
          'averageRating': 4.2,
          'totalRatings': 50,
          'geohash': 'dr5reg',
          'phoneNumber': '+919876543210',
        });

        final doc = await fakeFirestore
            .collection('vendor_profiles')
            .doc('vendor123')
            .get();
        final profile = VendorProfile.fromFirestore(doc);

        expect(profile.vendorId, 'vendor123');
        expect(profile.businessName, 'Test Restaurant');
        expect(profile.description, 'Test description');
        expect(profile.cuisineTags, ['Indian', 'Curry']);
        expect(profile.isActive, true);
        expect(profile.location, isA<GeoPoint>());
        expect(profile.location!.latitude, 40.7128);
        expect(profile.location!.longitude, -74.0060);
        expect(profile.locationUpdatedAt, testDate);
        expect(profile.profileImageUrl, 'https://example.com/test.jpg');
        expect(profile.averageRating, 4.2);
        expect(profile.totalRatings, 50);
        expect(profile.geohash, 'dr5reg');
        expect(profile.phoneNumber, '+919876543210');
      });

      test('parses vendor profile without optional fields', () async {
        await fakeFirestore.collection('vendor_profiles').doc('vendor456').set({
          'businessName': 'Minimal Vendor',
          'description': '',
          'cuisineTags': [],
          'isActive': false,
        });

        final doc = await fakeFirestore
            .collection('vendor_profiles')
            .doc('vendor456')
            .get();
        final profile = VendorProfile.fromFirestore(doc);

        expect(profile.location, isNull);
        expect(profile.locationUpdatedAt, isNull);
        expect(profile.profileImageUrl, isNull);
        expect(profile.averageRating, 0.0);
        expect(profile.totalRatings, 0);
        expect(profile.geohash, isNull);
        expect(profile.phoneNumber, isNull);
      });

      test('handles missing fields with defaults', () async {
        await fakeFirestore
            .collection('vendor_profiles')
            .doc('vendor789')
            .set({});

        final doc = await fakeFirestore
            .collection('vendor_profiles')
            .doc('vendor789')
            .get();
        final profile = VendorProfile.fromFirestore(doc);

        expect(profile.vendorId, 'vendor789');
        expect(profile.businessName, '');
        expect(profile.description, '');
        expect(profile.cuisineTags, isEmpty);
        expect(profile.isActive, false);
        expect(profile.averageRating, 0.0);
        expect(profile.totalRatings, 0);
      });

      test('converts integer averageRating to double', () async {
        await fakeFirestore.collection('vendor_profiles').doc('vendor101').set({
          'businessName': 'Test',
          'description': '',
          'cuisineTags': [],
          'isActive': true,
          'averageRating': 4, // integer
          'totalRatings': 10,
        });

        final doc = await fakeFirestore
            .collection('vendor_profiles')
            .doc('vendor101')
            .get();
        final profile = VendorProfile.fromFirestore(doc);

        expect(profile.averageRating, isA<double>());
        expect(profile.averageRating, 4.0);
      });
    });

    group('toFirestore', () {
      test('converts vendor profile with all fields to map', () {
        final profile = VendorProfile(
          vendorId: 'vendor123',
          businessName: 'Full Profile',
          description: 'Complete vendor',
          cuisineTags: ['Chinese', 'Dim Sum'],
          isActive: true,
          location: const GeoPoint(34.0522, -118.2437),
          locationUpdatedAt: testDate,
          profileImageUrl: 'https://example.com/full.jpg',
          averageRating: 4.8,
          totalRatings: 200,
          geohash: '9q5ctr',
          phoneNumber: '+8612345678901',
        );

        final map = profile.toFirestore();

        expect(map['businessName'], 'Full Profile');
        expect(map['description'], 'Complete vendor');
        expect(map['cuisineTags'], ['Chinese', 'Dim Sum']);
        expect(map['isActive'], true);
        expect(map['location'], isA<GeoPoint>());
        expect((map['location'] as GeoPoint).latitude, 34.0522);
        expect(map['locationUpdatedAt'], isA<Timestamp>());
        expect(map['profileImageUrl'], 'https://example.com/full.jpg');
        expect(map['averageRating'], 4.8);
        expect(map['totalRatings'], 200);
        expect(map['geohash'], '9q5ctr');
        expect(map['phoneNumber'], '+8612345678901');
        expect(map.containsKey('vendorId'), isFalse);
      });

      test('converts vendor profile without optional fields to map', () {
        final profile = VendorProfile(
          vendorId: 'vendor456',
          businessName: 'Minimal',
          description: '',
          cuisineTags: [],
          isActive: false,
        );

        final map = profile.toFirestore();

        expect(map['location'], isNull);
        expect(map['locationUpdatedAt'], isNull);
        expect(map['profileImageUrl'], isNull);
        expect(map['geohash'], isNull);
        expect(map['phoneNumber'], isNull);
      });
    });

    group('round-trip serialization', () {
      test('vendor profile with all fields survives round-trip', () async {
        final originalProfile = VendorProfile(
          vendorId: 'vendor123',
          businessName: 'Round Trip Vendor',
          description: 'Testing serialization',
          cuisineTags: ['Thai', 'Vietnamese'],
          isActive: true,
          location: const GeoPoint(51.5074, -0.1278),
          locationUpdatedAt: testDate,
          profileImageUrl: 'https://example.com/roundtrip.jpg',
          averageRating: 3.9,
          totalRatings: 75,
          geohash: 'gcpvj0',
          phoneNumber: '+447700900000',
        );

        await fakeFirestore
            .collection('vendor_profiles')
            .doc(originalProfile.vendorId)
            .set(originalProfile.toFirestore());

        final doc = await fakeFirestore
            .collection('vendor_profiles')
            .doc(originalProfile.vendorId)
            .get();
        final deserializedProfile = VendorProfile.fromFirestore(doc);

        expect(deserializedProfile.vendorId, originalProfile.vendorId);
        expect(deserializedProfile.businessName, originalProfile.businessName);
        expect(deserializedProfile.description, originalProfile.description);
        expect(deserializedProfile.cuisineTags, originalProfile.cuisineTags);
        expect(deserializedProfile.isActive, originalProfile.isActive);
        expect(
            deserializedProfile.location!.latitude,
            originalProfile.location!.latitude);
        expect(
            deserializedProfile.location!.longitude,
            originalProfile.location!.longitude);
        expect(deserializedProfile.locationUpdatedAt,
            originalProfile.locationUpdatedAt);
        expect(deserializedProfile.profileImageUrl,
            originalProfile.profileImageUrl);
        expect(
            deserializedProfile.averageRating, originalProfile.averageRating);
        expect(deserializedProfile.totalRatings, originalProfile.totalRatings);
        expect(deserializedProfile.geohash, originalProfile.geohash);
        expect(deserializedProfile.phoneNumber, originalProfile.phoneNumber);
      });
    });

    group('cuisine tags', () {
      test('preserves order of cuisine tags', () async {
        final tags = ['Mexican', 'American', 'BBQ', 'Tex-Mex'];

        await fakeFirestore.collection('vendor_profiles').doc('vendor123').set({
          'businessName': 'Multi-Cuisine',
          'description': '',
          'cuisineTags': tags,
          'isActive': true,
        });

        final doc = await fakeFirestore
            .collection('vendor_profiles')
            .doc('vendor123')
            .get();
        final profile = VendorProfile.fromFirestore(doc);

        expect(profile.cuisineTags, orderedEquals(tags));
      });
    });
  });
}
