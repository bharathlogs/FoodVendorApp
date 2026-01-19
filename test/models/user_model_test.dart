import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_vendor_app/models/user_model.dart';

void main() {
  group('UserRole', () {
    test('has vendor and customer values', () {
      expect(UserRole.values, contains(UserRole.vendor));
      expect(UserRole.values, contains(UserRole.customer));
      expect(UserRole.values.length, 2);
    });
  });

  group('UserModel', () {
    late FakeFirebaseFirestore fakeFirestore;
    late DateTime testDate;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      testDate = DateTime(2024, 1, 15, 10, 30);
    });

    group('constructor', () {
      test('creates UserModel with required fields', () {
        final user = UserModel(
          uid: 'user123',
          email: 'test@example.com',
          role: UserRole.customer,
          displayName: 'Test User',
          createdAt: testDate,
        );

        expect(user.uid, 'user123');
        expect(user.email, 'test@example.com');
        expect(user.role, UserRole.customer);
        expect(user.displayName, 'Test User');
        expect(user.createdAt, testDate);
        expect(user.phoneNumber, isNull);
      });

      test('creates UserModel with optional phone number', () {
        final user = UserModel(
          uid: 'user123',
          email: 'test@example.com',
          role: UserRole.vendor,
          displayName: 'Test Vendor',
          createdAt: testDate,
          phoneNumber: '+1234567890',
        );

        expect(user.phoneNumber, '+1234567890');
        expect(user.role, UserRole.vendor);
      });
    });

    group('fromFirestore', () {
      test('parses customer user from Firestore document', () async {
        await fakeFirestore.collection('users').doc('user123').set({
          'email': 'customer@example.com',
          'role': 'customer',
          'displayName': 'Customer Name',
          'createdAt': Timestamp.fromDate(testDate),
          'phoneNumber': null,
        });

        final doc =
            await fakeFirestore.collection('users').doc('user123').get();
        final user = UserModel.fromFirestore(doc);

        expect(user.uid, 'user123');
        expect(user.email, 'customer@example.com');
        expect(user.role, UserRole.customer);
        expect(user.displayName, 'Customer Name');
        expect(user.createdAt, testDate);
        expect(user.phoneNumber, isNull);
      });

      test('parses vendor user from Firestore document', () async {
        await fakeFirestore.collection('users').doc('vendor456').set({
          'email': 'vendor@example.com',
          'role': 'vendor',
          'displayName': 'Vendor Business',
          'createdAt': Timestamp.fromDate(testDate),
          'phoneNumber': '+9876543210',
        });

        final doc =
            await fakeFirestore.collection('users').doc('vendor456').get();
        final user = UserModel.fromFirestore(doc);

        expect(user.uid, 'vendor456');
        expect(user.email, 'vendor@example.com');
        expect(user.role, UserRole.vendor);
        expect(user.displayName, 'Vendor Business');
        expect(user.phoneNumber, '+9876543210');
      });

      test('handles missing fields with defaults', () async {
        await fakeFirestore.collection('users').doc('user789').set({
          'createdAt': Timestamp.fromDate(testDate),
        });

        final doc =
            await fakeFirestore.collection('users').doc('user789').get();
        final user = UserModel.fromFirestore(doc);

        expect(user.uid, 'user789');
        expect(user.email, '');
        expect(user.role, UserRole.customer); // default when not 'vendor'
        expect(user.displayName, '');
        expect(user.phoneNumber, isNull);
      });

      test('defaults to customer role for unknown role value', () async {
        await fakeFirestore.collection('users').doc('user101').set({
          'email': 'test@example.com',
          'role': 'unknown',
          'displayName': 'Test',
          'createdAt': Timestamp.fromDate(testDate),
        });

        final doc =
            await fakeFirestore.collection('users').doc('user101').get();
        final user = UserModel.fromFirestore(doc);

        expect(user.role, UserRole.customer);
      });
    });

    group('toFirestore', () {
      test('converts customer user to Firestore map', () {
        final user = UserModel(
          uid: 'user123',
          email: 'test@example.com',
          role: UserRole.customer,
          displayName: 'Test User',
          createdAt: testDate,
        );

        final map = user.toFirestore();

        expect(map['email'], 'test@example.com');
        expect(map['role'], 'customer');
        expect(map['displayName'], 'Test User');
        expect(map['createdAt'], isA<Timestamp>());
        expect((map['createdAt'] as Timestamp).toDate(), testDate);
        expect(map['phoneNumber'], isNull);
        expect(map.containsKey('uid'), isFalse); // uid is doc ID, not field
      });

      test('converts vendor user to Firestore map', () {
        final user = UserModel(
          uid: 'vendor456',
          email: 'vendor@example.com',
          role: UserRole.vendor,
          displayName: 'Vendor Business',
          createdAt: testDate,
          phoneNumber: '+1234567890',
        );

        final map = user.toFirestore();

        expect(map['email'], 'vendor@example.com');
        expect(map['role'], 'vendor');
        expect(map['displayName'], 'Vendor Business');
        expect(map['phoneNumber'], '+1234567890');
      });
    });

    group('round-trip serialization', () {
      test('customer user survives round-trip', () async {
        final originalUser = UserModel(
          uid: 'user123',
          email: 'roundtrip@example.com',
          role: UserRole.customer,
          displayName: 'Round Trip User',
          createdAt: testDate,
          phoneNumber: '+1111111111',
        );

        await fakeFirestore
            .collection('users')
            .doc(originalUser.uid)
            .set(originalUser.toFirestore());

        final doc = await fakeFirestore
            .collection('users')
            .doc(originalUser.uid)
            .get();
        final deserializedUser = UserModel.fromFirestore(doc);

        expect(deserializedUser.uid, originalUser.uid);
        expect(deserializedUser.email, originalUser.email);
        expect(deserializedUser.role, originalUser.role);
        expect(deserializedUser.displayName, originalUser.displayName);
        expect(deserializedUser.createdAt, originalUser.createdAt);
        expect(deserializedUser.phoneNumber, originalUser.phoneNumber);
      });

      test('vendor user survives round-trip', () async {
        final originalUser = UserModel(
          uid: 'vendor789',
          email: 'vendor@roundtrip.com',
          role: UserRole.vendor,
          displayName: 'Round Trip Vendor',
          createdAt: testDate,
        );

        await fakeFirestore
            .collection('users')
            .doc(originalUser.uid)
            .set(originalUser.toFirestore());

        final doc = await fakeFirestore
            .collection('users')
            .doc(originalUser.uid)
            .get();
        final deserializedUser = UserModel.fromFirestore(doc);

        expect(deserializedUser.uid, originalUser.uid);
        expect(deserializedUser.email, originalUser.email);
        expect(deserializedUser.role, UserRole.vendor);
        expect(deserializedUser.displayName, originalUser.displayName);
      });
    });
  });
}
