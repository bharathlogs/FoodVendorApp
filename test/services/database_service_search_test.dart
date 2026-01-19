import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('DatabaseService Search Functionality', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    group('Server-side search by business name prefix', () {
      Future<void> seedVendors() async {
        final vendors = [
          {
            'businessName': 'Taco Palace',
            'cuisineTags': ['Mexican', 'Tacos'],
            'isActive': true,
            'locationUpdatedAt': Timestamp.now(),
          },
          {
            'businessName': 'Taco Express',
            'cuisineTags': ['Mexican', 'Fast Food'],
            'isActive': true,
            'locationUpdatedAt': Timestamp.now(),
          },
          {
            'businessName': 'Thai Kitchen',
            'cuisineTags': ['Thai', 'Asian'],
            'isActive': true,
            'locationUpdatedAt': Timestamp.now(),
          },
          {
            'businessName': 'Inactive Vendor',
            'cuisineTags': ['Mexican'],
            'isActive': false,
            'locationUpdatedAt': Timestamp.now(),
          },
          {
            'businessName': "Bob's Burgers",
            'cuisineTags': ['American', 'Burgers'],
            'isActive': true,
            'locationUpdatedAt': Timestamp.now(),
          },
        ];

        for (var i = 0; i < vendors.length; i++) {
          await fakeFirestore
              .collection('vendor_profiles')
              .doc('vendor_$i')
              .set(vendors[i]);
        }
      }

      test('finds vendors by business name prefix', () async {
        await seedVendors();

        final snapshot = await fakeFirestore
            .collection('vendor_profiles')
            .where('isActive', isEqualTo: true)
            .where('businessName', isGreaterThanOrEqualTo: 'Taco')
            .where('businessName', isLessThan: 'Taco\uf8ff')
            .get();

        expect(snapshot.docs.length, 2);
        expect(
          snapshot.docs.map((d) => d['businessName']),
          containsAll(['Taco Palace', 'Taco Express']),
        );
      });

      test('returns empty for non-matching prefix', () async {
        await seedVendors();

        final snapshot = await fakeFirestore
            .collection('vendor_profiles')
            .where('isActive', isEqualTo: true)
            .where('businessName', isGreaterThanOrEqualTo: 'Pizza')
            .where('businessName', isLessThan: 'Pizza\uf8ff')
            .get();

        expect(snapshot.docs.length, 0);
      });

      test('excludes inactive vendors from search', () async {
        await seedVendors();

        final snapshot = await fakeFirestore
            .collection('vendor_profiles')
            .where('isActive', isEqualTo: true)
            .get();

        final inactiveVendors = snapshot.docs
            .where((d) => d['businessName'] == 'Inactive Vendor')
            .toList();

        expect(inactiveVendors.length, 0);
      });
    });

    group('Server-side search by cuisine tag', () {
      Future<void> seedVendors() async {
        final vendors = [
          {
            'businessName': 'Taco Palace',
            'cuisineTags': ['Mexican', 'Tacos'],
            'isActive': true,
          },
          {
            'businessName': 'Thai Kitchen',
            'cuisineTags': ['Thai', 'Asian'],
            'isActive': true,
          },
          {
            'businessName': 'Asian Fusion',
            'cuisineTags': ['Asian', 'Chinese', 'Japanese'],
            'isActive': true,
          },
          {
            'businessName': 'Inactive Asian',
            'cuisineTags': ['Asian'],
            'isActive': false,
          },
        ];

        for (var i = 0; i < vendors.length; i++) {
          await fakeFirestore
              .collection('vendor_profiles')
              .doc('vendor_$i')
              .set(vendors[i]);
        }
      }

      test('finds vendors by cuisine tag using arrayContains', () async {
        await seedVendors();

        final snapshot = await fakeFirestore
            .collection('vendor_profiles')
            .where('isActive', isEqualTo: true)
            .where('cuisineTags', arrayContains: 'Asian')
            .get();

        expect(snapshot.docs.length, 2);
        expect(
          snapshot.docs.map((d) => d['businessName']),
          containsAll(['Thai Kitchen', 'Asian Fusion']),
        );
      });

      test('finds vendors with exact cuisine match', () async {
        await seedVendors();

        final snapshot = await fakeFirestore
            .collection('vendor_profiles')
            .where('isActive', isEqualTo: true)
            .where('cuisineTags', arrayContains: 'Mexican')
            .get();

        expect(snapshot.docs.length, 1);
        expect(snapshot.docs.first['businessName'], 'Taco Palace');
      });

      test('returns empty for non-matching cuisine', () async {
        await seedVendors();

        final snapshot = await fakeFirestore
            .collection('vendor_profiles')
            .where('isActive', isEqualTo: true)
            .where('cuisineTags', arrayContains: 'Italian')
            .get();

        expect(snapshot.docs.length, 0);
      });

      test('excludes inactive vendors from cuisine search', () async {
        await seedVendors();

        final snapshot = await fakeFirestore
            .collection('vendor_profiles')
            .where('isActive', isEqualTo: true)
            .where('cuisineTags', arrayContains: 'Asian')
            .get();

        final inactiveVendors = snapshot.docs
            .where((d) => d['businessName'] == 'Inactive Asian')
            .toList();

        expect(inactiveVendors.length, 0);
      });
    });

    group('Search result merging and deduplication', () {
      test('merges results from multiple queries', () async {
        // Seed a vendor that matches both name and cuisine search
        await fakeFirestore.collection('vendor_profiles').doc('vendor_1').set({
          'businessName': 'Thai Food Express',
          'cuisineTags': ['Thai', 'Asian'],
          'isActive': true,
        });

        // Simulate parallel queries
        final nameResults = await fakeFirestore
            .collection('vendor_profiles')
            .where('isActive', isEqualTo: true)
            .where('businessName', isGreaterThanOrEqualTo: 'Thai')
            .where('businessName', isLessThan: 'Thai\uf8ff')
            .get();

        final cuisineResults = await fakeFirestore
            .collection('vendor_profiles')
            .where('isActive', isEqualTo: true)
            .where('cuisineTags', arrayContains: 'Thai')
            .get();

        // Merge and dedupe
        final seenIds = <String>{};
        final allVendors = <DocumentSnapshot>[];

        for (final doc in nameResults.docs) {
          if (!seenIds.contains(doc.id)) {
            seenIds.add(doc.id);
            allVendors.add(doc);
          }
        }

        for (final doc in cuisineResults.docs) {
          if (!seenIds.contains(doc.id)) {
            seenIds.add(doc.id);
            allVendors.add(doc);
          }
        }

        // Should have only one result (deduplicated)
        expect(allVendors.length, 1);
        expect(allVendors.first['businessName'], 'Thai Food Express');
      });
    });

    group('Pagination', () {
      test('limits results to specified count', () async {
        // Seed multiple vendors
        for (var i = 0; i < 10; i++) {
          await fakeFirestore
              .collection('vendor_profiles')
              .doc('vendor_$i')
              .set({
            'businessName': 'Vendor $i',
            'cuisineTags': ['Food'],
            'isActive': true,
          });
        }

        final snapshot = await fakeFirestore
            .collection('vendor_profiles')
            .where('isActive', isEqualTo: true)
            .limit(5)
            .get();

        expect(snapshot.docs.length, 5);
      });
    });
  });
}
