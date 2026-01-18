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

    test('should start with system theme mode by default', () {
      expect(themeService.themeMode, ThemeMode.system);
    });

    test('should return correct label for each theme mode', () async {
      expect(themeService.themeModeLabel, 'System');

      await themeService.setThemeMode(ThemeMode.light);
      expect(themeService.themeModeLabel, 'Light');

      await themeService.setThemeMode(ThemeMode.dark);
      expect(themeService.themeModeLabel, 'Dark');
    });

    test('should return correct icon for each theme mode', () async {
      expect(themeService.themeModeIcon, Icons.settings_brightness);

      await themeService.setThemeMode(ThemeMode.light);
      expect(themeService.themeModeIcon, Icons.light_mode);

      await themeService.setThemeMode(ThemeMode.dark);
      expect(themeService.themeModeIcon, Icons.dark_mode);
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

      await themeService.setThemeMode(ThemeMode.system);
      expect(notifyCount, 0); // Already system, should not notify
    });

    test('should toggle theme mode in correct order', () async {
      // Start at system
      expect(themeService.themeMode, ThemeMode.system);

      // System -> Light
      await themeService.toggleTheme();
      expect(themeService.themeMode, ThemeMode.light);

      // Light -> Dark
      await themeService.toggleTheme();
      expect(themeService.themeMode, ThemeMode.dark);

      // Dark -> System
      await themeService.toggleTheme();
      expect(themeService.themeMode, ThemeMode.system);
    });

    test('should persist theme mode to SharedPreferences', () async {
      await themeService.setThemeMode(ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');

      await themeService.setThemeMode(ThemeMode.light);
      expect(prefs.getString('theme_mode'), 'light');
    });

    test('should set all valid theme modes', () async {
      await themeService.setThemeMode(ThemeMode.dark);
      expect(themeService.themeMode, ThemeMode.dark);

      await themeService.setThemeMode(ThemeMode.light);
      expect(themeService.themeMode, ThemeMode.light);

      await themeService.setThemeMode(ThemeMode.system);
      expect(themeService.themeMode, ThemeMode.system);
    });
  });
}
