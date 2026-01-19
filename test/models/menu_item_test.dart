import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_vendor_app/models/menu_item.dart';

void main() {
  group('MenuItem', () {
    late FakeFirebaseFirestore fakeFirestore;
    late DateTime testDate;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      testDate = DateTime(2024, 2, 10, 9, 15);
    });

    group('constructor', () {
      test('creates MenuItem with required fields', () {
        final item = MenuItem(
          itemId: 'item123',
          name: 'Tacos',
          price: 8.99,
          isAvailable: true,
          createdAt: testDate,
        );

        expect(item.itemId, 'item123');
        expect(item.name, 'Tacos');
        expect(item.price, 8.99);
        expect(item.isAvailable, true);
        expect(item.createdAt, testDate);
        expect(item.description, isNull);
        expect(item.imageUrl, isNull);
      });

      test('creates MenuItem with all optional fields', () {
        final item = MenuItem(
          itemId: 'item456',
          name: 'Burrito Supreme',
          price: 12.50,
          description: 'Large burrito with beans, rice, and meat',
          imageUrl: 'https://example.com/burrito.jpg',
          isAvailable: false,
          createdAt: testDate,
        );

        expect(item.description, 'Large burrito with beans, rice, and meat');
        expect(item.imageUrl, 'https://example.com/burrito.jpg');
        expect(item.isAvailable, false);
      });

      test('handles zero price', () {
        final item = MenuItem(
          itemId: 'item789',
          name: 'Free Sample',
          price: 0.0,
          isAvailable: true,
          createdAt: testDate,
        );

        expect(item.price, 0.0);
      });

      test('handles high precision price', () {
        final item = MenuItem(
          itemId: 'item101',
          name: 'Precise Item',
          price: 9.999,
          isAvailable: true,
          createdAt: testDate,
        );

        expect(item.price, 9.999);
      });
    });

    group('fromFirestore', () {
      test('parses menu item with all fields', () async {
        await fakeFirestore.collection('menu_items').doc('item123').set({
          'name': 'Cheese Quesadilla',
          'price': 7.50,
          'description': 'Melted cheese in a flour tortilla',
          'imageUrl': 'https://example.com/quesadilla.jpg',
          'isAvailable': true,
          'createdAt': Timestamp.fromDate(testDate),
        });

        final doc =
            await fakeFirestore.collection('menu_items').doc('item123').get();
        final item = MenuItem.fromFirestore(doc);

        expect(item.itemId, 'item123');
        expect(item.name, 'Cheese Quesadilla');
        expect(item.price, 7.50);
        expect(item.description, 'Melted cheese in a flour tortilla');
        expect(item.imageUrl, 'https://example.com/quesadilla.jpg');
        expect(item.isAvailable, true);
        expect(item.createdAt, testDate);
      });

      test('parses menu item without optional fields', () async {
        await fakeFirestore.collection('menu_items').doc('item456').set({
          'name': 'Simple Item',
          'price': 5.00,
          'isAvailable': true,
          'createdAt': Timestamp.fromDate(testDate),
        });

        final doc =
            await fakeFirestore.collection('menu_items').doc('item456').get();
        final item = MenuItem.fromFirestore(doc);

        expect(item.description, isNull);
        expect(item.imageUrl, isNull);
      });

      test('handles missing fields with defaults', () async {
        await fakeFirestore.collection('menu_items').doc('item789').set({
          'createdAt': Timestamp.fromDate(testDate),
        });

        final doc =
            await fakeFirestore.collection('menu_items').doc('item789').get();
        final item = MenuItem.fromFirestore(doc);

        expect(item.name, '');
        expect(item.price, 0.0);
        expect(item.isAvailable, true); // default to available
      });

      test('converts integer price to double', () async {
        await fakeFirestore.collection('menu_items').doc('item101').set({
          'name': 'Integer Price Item',
          'price': 10, // integer, not double
          'isAvailable': true,
          'createdAt': Timestamp.fromDate(testDate),
        });

        final doc =
            await fakeFirestore.collection('menu_items').doc('item101').get();
        final item = MenuItem.fromFirestore(doc);

        expect(item.price, isA<double>());
        expect(item.price, 10.0);
      });
    });

    group('toFirestore', () {
      test('converts menu item with all fields to map', () {
        final item = MenuItem(
          itemId: 'item123',
          name: 'Nachos',
          price: 9.99,
          description: 'Loaded nachos with toppings',
          imageUrl: 'https://example.com/nachos.jpg',
          isAvailable: true,
          createdAt: testDate,
        );

        final map = item.toFirestore();

        expect(map['name'], 'Nachos');
        expect(map['price'], 9.99);
        expect(map['description'], 'Loaded nachos with toppings');
        expect(map['imageUrl'], 'https://example.com/nachos.jpg');
        expect(map['isAvailable'], true);
        expect(map['createdAt'], isA<Timestamp>());
        expect((map['createdAt'] as Timestamp).toDate(), testDate);
        expect(map.containsKey('itemId'), isFalse);
      });

      test('converts menu item without optional fields to map', () {
        final item = MenuItem(
          itemId: 'item456',
          name: 'Basic Item',
          price: 4.99,
          isAvailable: false,
          createdAt: testDate,
        );

        final map = item.toFirestore();

        expect(map['name'], 'Basic Item');
        expect(map['price'], 4.99);
        expect(map['description'], isNull);
        expect(map['imageUrl'], isNull);
        expect(map['isAvailable'], false);
      });
    });

    group('round-trip serialization', () {
      test('menu item with all fields survives round-trip', () async {
        final originalItem = MenuItem(
          itemId: 'item123',
          name: 'Round Trip Item',
          price: 15.99,
          description: 'Test description',
          imageUrl: 'https://example.com/test.jpg',
          isAvailable: true,
          createdAt: testDate,
        );

        await fakeFirestore
            .collection('menu_items')
            .doc(originalItem.itemId)
            .set(originalItem.toFirestore());

        final doc = await fakeFirestore
            .collection('menu_items')
            .doc(originalItem.itemId)
            .get();
        final deserializedItem = MenuItem.fromFirestore(doc);

        expect(deserializedItem.itemId, originalItem.itemId);
        expect(deserializedItem.name, originalItem.name);
        expect(deserializedItem.price, originalItem.price);
        expect(deserializedItem.description, originalItem.description);
        expect(deserializedItem.imageUrl, originalItem.imageUrl);
        expect(deserializedItem.isAvailable, originalItem.isAvailable);
        expect(deserializedItem.createdAt, originalItem.createdAt);
      });

      test('menu item without optional fields survives round-trip', () async {
        final originalItem = MenuItem(
          itemId: 'item456',
          name: 'Minimal Item',
          price: 3.50,
          isAvailable: false,
          createdAt: testDate,
        );

        await fakeFirestore
            .collection('menu_items')
            .doc(originalItem.itemId)
            .set(originalItem.toFirestore());

        final doc = await fakeFirestore
            .collection('menu_items')
            .doc(originalItem.itemId)
            .get();
        final deserializedItem = MenuItem.fromFirestore(doc);

        expect(deserializedItem.name, originalItem.name);
        expect(deserializedItem.price, originalItem.price);
        expect(deserializedItem.isAvailable, false);
        expect(deserializedItem.description, isNull);
        expect(deserializedItem.imageUrl, isNull);
      });
    });
  });
}
