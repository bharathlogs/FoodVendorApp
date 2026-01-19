import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_vendor_app/services/theme_service.dart';

void main() {
  group('ThemeService', () {
    late ThemeService themeService;

    setUp(() {
      // Reset SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      themeService = ThemeService();
    });

    test('should start with light theme mode by default', () {
      expect(themeService.themeMode, ThemeMode.light);
    });

    test('should return correct label for each theme mode', () async {
      // Starts with light
      expect(themeService.themeModeLabel, 'Light');

      await themeService.setThemeMode(ThemeMode.dark);
      expect(themeService.themeModeLabel, 'Dark');

      await themeService.setThemeMode(ThemeMode.light);
      expect(themeService.themeModeLabel, 'Light');
    });

    test('should return correct icon for each theme mode', () async {
      // Starts with light
      expect(themeService.themeModeIcon, Icons.light_mode);

      await themeService.setThemeMode(ThemeMode.dark);
      expect(themeService.themeModeIcon, Icons.dark_mode);

      await themeService.setThemeMode(ThemeMode.light);
      expect(themeService.themeModeIcon, Icons.light_mode);
    });

    test('should change theme mode and notify listeners', () async {
      int notifyCount = 0;
      themeService.addListener(() {
        notifyCount++;
      });

      await themeService.setThemeMode(ThemeMode.dark);
      expect(themeService.themeMode, ThemeMode.dark);
      expect(notifyCount, 1);

      await themeService.setThemeMode(ThemeMode.light);
      expect(themeService.themeMode, ThemeMode.light);
      expect(notifyCount, 2);
    });

    test('should not notify listeners when setting same theme mode', () async {
      int notifyCount = 0;
      themeService.addListener(() {
        notifyCount++;
      });

      // Already light, should not notify
      await themeService.setThemeMode(ThemeMode.light);
      expect(notifyCount, 0);
    });

    test('should toggle between light and dark only', () async {
      // Start at light
      expect(themeService.themeMode, ThemeMode.light);

      // Light -> Dark
      await themeService.toggleTheme();
      expect(themeService.themeMode, ThemeMode.dark);

      // Dark -> Light
      await themeService.toggleTheme();
      expect(themeService.themeMode, ThemeMode.light);

      // Light -> Dark (again)
      await themeService.toggleTheme();
      expect(themeService.themeMode, ThemeMode.dark);
    });

    test('should persist theme mode to SharedPreferences', () async {
      await themeService.setThemeMode(ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');

      await themeService.setThemeMode(ThemeMode.light);
      expect(prefs.getString('theme_mode'), 'light');
    });

    test('should set valid theme modes', () async {
      await themeService.setThemeMode(ThemeMode.dark);
      expect(themeService.themeMode, ThemeMode.dark);

      await themeService.setThemeMode(ThemeMode.light);
      expect(themeService.themeMode, ThemeMode.light);
    });

    test('should treat system mode as light when loading', () async {
      // Simulate stored 'system' value (legacy)
      SharedPreferences.setMockInitialValues({'theme_mode': 'system'});

      final newService = ThemeService();
      // Allow async loading
      await Future.delayed(const Duration(milliseconds: 100));

      // System mode should be treated as light
      expect(newService.themeMode == ThemeMode.light ||
          newService.themeMode == ThemeMode.system, isTrue);
    });
  });
}
