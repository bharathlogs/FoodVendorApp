import 'package:flutter_test/flutter_test.dart';
import 'package:food_vendor_app/utils/validators.dart';

void main() {
  group('Validators', () {
    group('email', () {
      test('returns error for null value', () {
        expect(Validators.email(null), 'Email is required');
      });

      test('returns error for empty value', () {
        expect(Validators.email(''), 'Email is required');
      });

      test('returns error for invalid email format', () {
        expect(Validators.email('   '), 'Please enter a valid email address');
        expect(Validators.email('notanemail'), 'Please enter a valid email address');
        expect(Validators.email('missing@domain'), 'Please enter a valid email address');
        expect(Validators.email('@nodomain.com'), 'Please enter a valid email address');
      });

      test('returns null for valid email', () {
        expect(Validators.email('test@example.com'), isNull);
        expect(Validators.email('user.name@domain.co.uk'), isNull);
        expect(Validators.email('user+tag@example.org'), isNull);
      });
    });

    group('password', () {
      test('returns error for null value', () {
        expect(Validators.password(null), 'Password is required');
      });

      test('returns error for empty value', () {
        expect(Validators.password(''), 'Password is required');
      });

      test('returns error for short password', () {
        expect(Validators.password('12345'), 'Password must be at least 6 characters');
      });

      test('returns null for valid password', () {
        expect(Validators.password('123456'), isNull);
        expect(Validators.password('securepassword'), isNull);
      });
    });

    group('businessName', () {
      test('returns error for null value', () {
        expect(Validators.businessName(null), 'Business name is required');
      });

      test('returns error for empty value', () {
        expect(Validators.businessName(''), 'Business name is required');
        expect(Validators.businessName('   '), 'Business name is required');
      });

      test('returns error for short name', () {
        expect(Validators.businessName('A'), 'Business name must be at least 2 characters');
      });

      test('returns error for name exceeding max length', () {
        final longName = 'A' * 101;
        expect(Validators.businessName(longName), 'Business name must be under 100 characters');
      });

      test('returns error for HTML/script injection', () {
        expect(Validators.businessName('<script>alert("xss")</script>'), 'Invalid characters detected');
        expect(Validators.businessName('Test<div>'), 'Invalid characters detected');
        expect(Validators.businessName('onclick=alert(1)'), 'Invalid characters detected');
      });

      test('returns null for valid business name', () {
        expect(Validators.businessName('My Restaurant'), isNull);
        expect(Validators.businessName("Joe's Diner"), isNull);
        expect(Validators.businessName('Café & Bistro'), isNull);
      });
    });

    group('description', () {
      test('returns null for null value (optional field)', () {
        expect(Validators.description(null), isNull);
      });

      test('returns null for empty value (optional field)', () {
        expect(Validators.description(''), isNull);
      });

      test('returns error for description exceeding max length', () {
        final longDesc = 'A' * 501;
        expect(Validators.description(longDesc), 'Description must be under 500 characters');
      });

      test('returns error for HTML/script injection', () {
        expect(Validators.description('<script>alert("xss")</script>'), 'Invalid characters detected');
      });

      test('returns null for valid description', () {
        expect(Validators.description('A great place to eat'), isNull);
      });
    });
  });

  group('MenuItemValidators', () {
    group('name', () {
      test('returns error for null value', () {
        expect(MenuItemValidators.name(null), 'Item name is required');
      });

      test('returns error for empty value', () {
        expect(MenuItemValidators.name(''), 'Item name is required');
        expect(MenuItemValidators.name('   '), 'Item name is required');
      });

      test('returns error for short name', () {
        expect(MenuItemValidators.name('A'), 'Name must be at least 2 characters');
      });

      test('returns error for name exceeding max length', () {
        final longName = 'A' * 101;
        expect(MenuItemValidators.name(longName), 'Name must be under 100 characters');
      });

      test('returns error for HTML/script injection', () {
        expect(MenuItemValidators.name('<script>alert("xss")</script>'), 'Invalid characters detected');
        expect(MenuItemValidators.name('Burger<img src=x>'), 'Invalid characters detected');
        expect(MenuItemValidators.name('onload=steal()'), 'Invalid characters detected');
      });

      test('returns null for valid item name', () {
        expect(MenuItemValidators.name('Masala Dosa'), isNull);
        expect(MenuItemValidators.name('Chicken Biryani'), isNull);
        expect(MenuItemValidators.name("Chef's Special"), isNull);
      });
    });

    group('price', () {
      test('returns error for null value', () {
        expect(MenuItemValidators.price(null), 'Price is required');
      });

      test('returns error for empty value', () {
        expect(MenuItemValidators.price(''), 'Price is required');
        expect(MenuItemValidators.price('   '), 'Price is required');
      });

      test('returns error for non-numeric value', () {
        expect(MenuItemValidators.price('abc'), 'Please enter a valid number');
        expect(MenuItemValidators.price('12.34.56'), 'Please enter a valid number');
      });

      test('returns error for negative price', () {
        expect(MenuItemValidators.price('-10'), 'Price cannot be negative');
      });

      test('returns error for price exceeding max', () {
        expect(MenuItemValidators.price('100000'), 'Price must be under 99,999');
      });

      test('returns null for valid price', () {
        expect(MenuItemValidators.price('0'), isNull);
        expect(MenuItemValidators.price('50'), isNull);
        expect(MenuItemValidators.price('99.99'), isNull);
        expect(MenuItemValidators.price('99999'), isNull);
      });
    });

    group('description', () {
      test('returns null for null value (optional field)', () {
        expect(MenuItemValidators.description(null), isNull);
      });

      test('returns null for empty value (optional field)', () {
        expect(MenuItemValidators.description(''), isNull);
        expect(MenuItemValidators.description('   '), isNull);
      });

      test('returns error for description exceeding max length', () {
        final longDesc = 'A' * 201;
        expect(MenuItemValidators.description(longDesc), 'Description must be under 200 characters');
      });

      test('returns error for HTML/script injection', () {
        expect(MenuItemValidators.description('<script>alert("xss")</script>'), 'Invalid characters detected');
      });

      test('returns null for valid description', () {
        expect(MenuItemValidators.description('Crispy rice crepe with potato filling'), isNull);
      });
    });
  });
}
