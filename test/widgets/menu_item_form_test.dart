import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_vendor_app/widgets/vendor/menu_item_form.dart';
import 'package:food_vendor_app/models/menu_item.dart';

void main() {
  group('MenuItemForm', () {
    testWidgets('should display "Add Menu Item" title for new item', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuItemForm(
              onSave: (name, price, description) {},
            ),
          ),
        ),
      );

      expect(find.text('Add Menu Item'), findsOneWidget);
      expect(find.text('Add Item'), findsOneWidget);
    });

    testWidgets('should display "Edit Item" title when editing existing item', (tester) async {
      final existingItem = MenuItem(
        itemId: 'test-id',
        name: 'Test Item',
        price: 100,
        description: 'Test description',
        isAvailable: true,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuItemForm(
              existingItem: existingItem,
              onSave: (name, price, description) {},
            ),
          ),
        ),
      );

      expect(find.text('Edit Item'), findsOneWidget);
      expect(find.text('Update Item'), findsOneWidget);
    });

    testWidgets('should pre-populate fields when editing existing item', (tester) async {
      final existingItem = MenuItem(
        itemId: 'test-id',
        name: 'Masala Dosa',
        price: 50,
        description: 'Crispy crepe',
        isAvailable: true,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuItemForm(
              existingItem: existingItem,
              onSave: (name, price, description) {},
            ),
          ),
        ),
      );

      expect(find.text('Masala Dosa'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
      expect(find.text('Crispy crepe'), findsOneWidget);
    });

    testWidgets('should show delete button only when editing', (tester) async {
      // New item - no delete button
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuItemForm(
              onSave: (name, price, description) {},
            ),
          ),
        ),
      );

      expect(find.text('Delete Item'), findsNothing);

      // Editing item with onDelete - show delete button
      final existingItem = MenuItem(
        itemId: 'test-id',
        name: 'Test Item',
        price: 100,
        isAvailable: true,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuItemForm(
              existingItem: existingItem,
              onSave: (name, price, description) {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Delete Item'), findsOneWidget);
    });

    testWidgets('should validate required fields', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuItemForm(
              onSave: (name, price, description) {},
            ),
          ),
        ),
      );

      // Try to submit without filling required fields
      await tester.tap(find.text('Add Item'));
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('Item name is required'), findsOneWidget);
      expect(find.text('Price is required'), findsOneWidget);
    });

    testWidgets('should call onSave with correct values', (tester) async {
      String? savedName;
      double? savedPrice;
      String? savedDescription;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuItemForm(
              onSave: (name, price, description) {
                savedName = name;
                savedPrice = price;
                savedDescription = description;
              },
            ),
          ),
        ),
      );

      // Fill in the form
      await tester.enterText(find.byType(TextFormField).at(0), 'Masala Dosa');
      await tester.enterText(find.byType(TextFormField).at(1), '75');
      await tester.enterText(find.byType(TextFormField).at(2), 'Crispy and delicious');

      // Submit - use pump() instead of pumpAndSettle() since the form shows a loading spinner
      await tester.tap(find.text('Add Item'));
      await tester.pump();

      expect(savedName, 'Masala Dosa');
      expect(savedPrice, 75.0);
      expect(savedDescription, 'Crispy and delicious');
    });

    testWidgets('should pass null for empty description', (tester) async {
      String? savedDescription = 'initial';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuItemForm(
              onSave: (name, price, description) {
                savedDescription = description;
              },
            ),
          ),
        ),
      );

      // Fill required fields only
      await tester.enterText(find.byType(TextFormField).at(0), 'Test Item');
      await tester.enterText(find.byType(TextFormField).at(1), '100');

      // Submit - use pump() instead of pumpAndSettle() since the form shows a loading spinner
      await tester.tap(find.text('Add Item'));
      await tester.pump();

      expect(savedDescription, isNull);
    });

    testWidgets('should show delete confirmation dialog', (tester) async {
      final existingItem = MenuItem(
        itemId: 'test-id',
        name: 'Test Item',
        price: 100,
        isAvailable: true,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuItemForm(
              existingItem: existingItem,
              onSave: (name, price, description) {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Tap delete button
      await tester.tap(find.text('Delete Item'));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Delete Item?'), findsOneWidget);
      expect(find.text('Are you sure you want to delete "Test Item"?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('should close dialog on cancel', (tester) async {
      final existingItem = MenuItem(
        itemId: 'test-id',
        name: 'Test Item',
        price: 100,
        isAvailable: true,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuItemForm(
              existingItem: existingItem,
              onSave: (name, price, description) {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Open delete dialog
      await tester.tap(find.text('Delete Item'));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.text('Delete Item?'), findsNothing);
    });

    testWidgets('should have close button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuItemForm(
              onSave: (name, price, description) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('should show max length counter for name field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuItemForm(
              onSave: (name, price, description) {},
            ),
          ),
        ),
      );

      // Name field should show character counter
      await tester.enterText(find.byType(TextFormField).at(0), 'Test');
      await tester.pump();

      expect(find.text('4/100'), findsOneWidget);
    });
  });
}
