import 'package:flutter_test/flutter_test.dart';
import 'package:food_vendor_app/models/user_model.dart';

void main() {
  group('NotificationPreferences', () {
    group('constructor', () {
      test('creates with default values', () {
        const prefs = NotificationPreferences();

        expect(prefs.orderUpdates, true);
        expect(prefs.promotions, true);
        expect(prefs.vendorNearby, true);
        expect(prefs.newVendors, false);
        expect(prefs.favoriteCuisines, isEmpty);
      });

      test('creates with custom values', () {
        const prefs = NotificationPreferences(
          orderUpdates: false,
          promotions: false,
          vendorNearby: false,
          newVendors: true,
          favoriteCuisines: ['Mexican', 'Thai', 'Italian'],
        );

        expect(prefs.orderUpdates, false);
        expect(prefs.promotions, false);
        expect(prefs.vendorNearby, false);
        expect(prefs.newVendors, true);
        expect(prefs.favoriteCuisines, ['Mexican', 'Thai', 'Italian']);
      });
    });

    group('fromMap', () {
      test('returns defaults for null data', () {
        final prefs = NotificationPreferences.fromMap(null);

        expect(prefs.orderUpdates, true);
        expect(prefs.promotions, true);
        expect(prefs.vendorNearby, true);
        expect(prefs.newVendors, false);
        expect(prefs.favoriteCuisines, isEmpty);
      });

      test('returns defaults for empty map', () {
        final prefs = NotificationPreferences.fromMap({});

        expect(prefs.orderUpdates, true);
        expect(prefs.promotions, true);
        expect(prefs.vendorNearby, true);
        expect(prefs.newVendors, false);
        expect(prefs.favoriteCuisines, isEmpty);
      });

      test('parses complete map correctly', () {
        final prefs = NotificationPreferences.fromMap({
          'orderUpdates': false,
          'promotions': true,
          'vendorNearby': false,
          'newVendors': true,
          'favoriteCuisines': ['Chinese', 'Indian'],
        });

        expect(prefs.orderUpdates, false);
        expect(prefs.promotions, true);
        expect(prefs.vendorNearby, false);
        expect(prefs.newVendors, true);
        expect(prefs.favoriteCuisines, ['Chinese', 'Indian']);
      });

      test('handles partial map with defaults', () {
        final prefs = NotificationPreferences.fromMap({
          'promotions': false,
          'favoriteCuisines': ['BBQ'],
        });

        expect(prefs.orderUpdates, true); // default
        expect(prefs.promotions, false);
        expect(prefs.vendorNearby, true); // default
        expect(prefs.newVendors, false); // default
        expect(prefs.favoriteCuisines, ['BBQ']);
      });

      test('handles null favoriteCuisines', () {
        final prefs = NotificationPreferences.fromMap({
          'favoriteCuisines': null,
        });

        expect(prefs.favoriteCuisines, isEmpty);
      });
    });

    group('toMap', () {
      test('converts default preferences to map', () {
        const prefs = NotificationPreferences();
        final map = prefs.toMap();

        expect(map['orderUpdates'], true);
        expect(map['promotions'], true);
        expect(map['vendorNearby'], true);
        expect(map['newVendors'], false);
        expect(map['favoriteCuisines'], isEmpty);
      });

      test('converts custom preferences to map', () {
        const prefs = NotificationPreferences(
          orderUpdates: false,
          promotions: false,
          vendorNearby: true,
          newVendors: true,
          favoriteCuisines: ['Sushi', 'Ramen'],
        );
        final map = prefs.toMap();

        expect(map['orderUpdates'], false);
        expect(map['promotions'], false);
        expect(map['vendorNearby'], true);
        expect(map['newVendors'], true);
        expect(map['favoriteCuisines'], ['Sushi', 'Ramen']);
      });
    });

    group('copyWith', () {
      test('copies with no changes', () {
        const original = NotificationPreferences(
          orderUpdates: false,
          promotions: true,
          vendorNearby: false,
          newVendors: true,
          favoriteCuisines: ['Pizza'],
        );

        final copied = original.copyWith();

        expect(copied.orderUpdates, original.orderUpdates);
        expect(copied.promotions, original.promotions);
        expect(copied.vendorNearby, original.vendorNearby);
        expect(copied.newVendors, original.newVendors);
        expect(copied.favoriteCuisines, original.favoriteCuisines);
      });

      test('copies with single field change', () {
        const original = NotificationPreferences();

        final copied = original.copyWith(promotions: false);

        expect(copied.orderUpdates, true);
        expect(copied.promotions, false);
        expect(copied.vendorNearby, true);
        expect(copied.newVendors, false);
      });

      test('copies with multiple field changes', () {
        const original = NotificationPreferences();

        final copied = original.copyWith(
          orderUpdates: false,
          newVendors: true,
          favoriteCuisines: ['Tacos', 'Burritos'],
        );

        expect(copied.orderUpdates, false);
        expect(copied.promotions, true);
        expect(copied.vendorNearby, true);
        expect(copied.newVendors, true);
        expect(copied.favoriteCuisines, ['Tacos', 'Burritos']);
      });

      test('copies with all field changes', () {
        const original = NotificationPreferences();

        final copied = original.copyWith(
          orderUpdates: false,
          promotions: false,
          vendorNearby: false,
          newVendors: true,
          favoriteCuisines: ['Korean'],
        );

        expect(copied.orderUpdates, false);
        expect(copied.promotions, false);
        expect(copied.vendorNearby, false);
        expect(copied.newVendors, true);
        expect(copied.favoriteCuisines, ['Korean']);
      });
    });

    group('round-trip serialization', () {
      test('preferences survive round-trip', () {
        const original = NotificationPreferences(
          orderUpdates: false,
          promotions: true,
          vendorNearby: false,
          newVendors: true,
          favoriteCuisines: ['Vietnamese', 'French'],
        );

        final map = original.toMap();
        final restored = NotificationPreferences.fromMap(map);

        expect(restored.orderUpdates, original.orderUpdates);
        expect(restored.promotions, original.promotions);
        expect(restored.vendorNearby, original.vendorNearby);
        expect(restored.newVendors, original.newVendors);
        expect(restored.favoriteCuisines, original.favoriteCuisines);
      });

      test('default preferences survive round-trip', () {
        const original = NotificationPreferences();

        final map = original.toMap();
        final restored = NotificationPreferences.fromMap(map);

        expect(restored.orderUpdates, original.orderUpdates);
        expect(restored.promotions, original.promotions);
        expect(restored.vendorNearby, original.vendorNearby);
        expect(restored.newVendors, original.newVendors);
        expect(restored.favoriteCuisines, original.favoriteCuisines);
      });
    });
  });
}
