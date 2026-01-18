// This is a basic Flutter widget test for the Food Finder app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_vendor_app/theme/app_theme.dart';

void main() {
  group('App Theme', () {
    test('light theme should have correct primary color', () {
      final lightTheme = AppTheme.lightTheme;
      expect(lightTheme.primaryColor, AppColors.primary);
      expect(lightTheme.brightness, Brightness.light);
    });

    test('dark theme should have correct primary color', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.primaryColor, AppColors.primary);
      expect(darkTheme.brightness, Brightness.dark);
    });

    test('light and dark themes should share primary color', () {
      expect(AppTheme.lightTheme.primaryColor, AppTheme.darkTheme.primaryColor);
    });
  });
}
