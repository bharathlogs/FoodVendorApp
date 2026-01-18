import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/analytics_service.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';

// ============================================================================
// Core Service Providers
// ============================================================================

/// Provides the AuthService singleton
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provides the DatabaseService singleton
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// Provides the AnalyticsService singleton
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// Provides the NotificationService singleton
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// ============================================================================
// Authentication Providers
// ============================================================================

/// Stream of Firebase auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Current user data from Firestore (based on auth state)
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) async {
      if (user == null) return null;
      final authService = ref.read(authServiceProvider);
      return await authService.getUserData(user.uid);
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Whether the current user is a vendor
final isVendorProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.valueOrNull?.role == UserRole.vendor;
});

// ============================================================================
// Theme Providers
// ============================================================================

/// SharedPreferences provider - must be overridden in main
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

/// Theme mode notifier for managing app theme
class ThemeNotifier extends Notifier<ThemeMode> {
  static const String _themeModeKey = 'theme_mode';

  @override
  ThemeMode build() {
    _loadSavedTheme();
    return ThemeMode.system;
  }

  Future<void> _loadSavedTheme() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final savedMode = prefs.getString(_themeModeKey);

    if (savedMode != null) {
      state = _themeModeFromString(savedMode);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;

    state = mode;

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_themeModeKey, _themeModeToString(mode));
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.light
        ? ThemeMode.dark
        : state == ThemeMode.dark
            ? ThemeMode.system
            : ThemeMode.light;
    await setThemeMode(newMode);
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String get themeModeLabel {
    switch (state) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  IconData get themeModeIcon {
    switch (state) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.settings_brightness;
    }
  }
}

/// Provider for theme mode management
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});

// ============================================================================
// Connectivity Providers
// ============================================================================

/// Tracks online/offline status
final connectivityProvider = StateProvider<bool>((ref) => true);

// ============================================================================
// Favorites Providers
// ============================================================================

/// Stream of current user's favorite vendor IDs
final favoriteVendorIdsProvider = StreamProvider<Set<String>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;

  if (user == null) {
    return Stream.value(<String>{});
  }

  final dbService = ref.read(databaseServiceProvider);
  return dbService.getFavoriteVendorIdsStream(user.uid);
});

/// Check if a specific vendor is favorited
final isVendorFavoritedProvider =
    Provider.family<bool, String>((ref, vendorId) {
  final favoriteIds = ref.watch(favoriteVendorIdsProvider);
  return favoriteIds.valueOrNull?.contains(vendorId) ?? false;
});

/// Notifier for managing favorites actions
class FavoritesNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> toggleFavorite(String vendorId) async {
    final authState = ref.read(authStateProvider);
    final user = authState.valueOrNull;

    if (user == null) return;

    state = const AsyncValue.loading();

    try {
      final dbService = ref.read(databaseServiceProvider);
      final isFavorited =
          ref.read(favoriteVendorIdsProvider).valueOrNull?.contains(vendorId) ??
              false;

      if (isFavorited) {
        await dbService.removeFavorite(user.uid, vendorId);
      } else {
        await dbService.addFavorite(user.uid, vendorId);
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addFavorite(String vendorId) async {
    final authState = ref.read(authStateProvider);
    final user = authState.valueOrNull;

    if (user == null) return;

    state = const AsyncValue.loading();

    try {
      final dbService = ref.read(databaseServiceProvider);
      await dbService.addFavorite(user.uid, vendorId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeFavorite(String vendorId) async {
    final authState = ref.read(authStateProvider);
    final user = authState.valueOrNull;

    if (user == null) return;

    state = const AsyncValue.loading();

    try {
      final dbService = ref.read(databaseServiceProvider);
      await dbService.removeFavorite(user.uid, vendorId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider for favorites actions
final favoritesNotifierProvider =
    NotifierProvider<FavoritesNotifier, AsyncValue<void>>(() {
  return FavoritesNotifier();
});
