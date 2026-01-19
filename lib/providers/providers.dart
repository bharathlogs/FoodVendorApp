import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/analytics_service.dart';
import '../services/notification_service.dart';
import '../services/biometric_service.dart';
import '../services/deep_link_service.dart';
import '../models/user_model.dart';
import '../models/review.dart';

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
    return ThemeMode.light;
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
    // Toggle between light and dark only
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'light'; // Treat system as light
    }
  }

  ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.light; // Default to light
    }
  }

  String get themeModeLabel {
    return state == ThemeMode.dark ? 'Dark' : 'Light';
  }

  IconData get themeModeIcon {
    return state == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode;
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
        // Pre-fetch menu for offline access when adding to favorites
        _preFetchMenuForOffline(vendorId);
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Pre-fetch menu items for a vendor to cache them for offline access
  /// This runs in the background and doesn't block the favorites operation
  void _preFetchMenuForOffline(String vendorId) {
    final dbService = ref.read(databaseServiceProvider);
    // Subscribe to the menu stream once to trigger Firestore to cache the data
    // The subscription is automatically cleaned up after first emission
    dbService.getMenuItemsStream(vendorId).first.then((_) {
      debugPrint('Pre-fetched menu for vendor $vendorId for offline access');
    }).catchError((e) {
      debugPrint('Failed to pre-fetch menu for vendor $vendorId: $e');
    });
  }

  Future<void> addFavorite(String vendorId) async {
    final authState = ref.read(authStateProvider);
    final user = authState.valueOrNull;

    if (user == null) return;

    state = const AsyncValue.loading();

    try {
      final dbService = ref.read(databaseServiceProvider);
      await dbService.addFavorite(user.uid, vendorId);
      // Pre-fetch menu for offline access
      _preFetchMenuForOffline(vendorId);
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

// ============================================================================
// Biometric Authentication Providers
// ============================================================================

/// Provides the BiometricService singleton
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

/// State for biometric authentication
class BiometricState {
  final bool isEnabled;
  final bool hasCredential;
  final bool isVerified;

  const BiometricState({
    this.isEnabled = false,
    this.hasCredential = false,
    this.isVerified = false,
  });

  BiometricState copyWith({
    bool? isEnabled,
    bool? hasCredential,
    bool? isVerified,
  }) {
    return BiometricState(
      isEnabled: isEnabled ?? this.isEnabled,
      hasCredential: hasCredential ?? this.hasCredential,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

/// Biometric authentication notifier
class BiometricNotifier extends Notifier<BiometricState> {
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricCredentialKey = 'biometric_credential_stored';

  @override
  BiometricState build() {
    _loadSavedState();
    return const BiometricState();
  }

  Future<void> _loadSavedState() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final isEnabled = prefs.getBool(_biometricEnabledKey) ?? false;
    final hasCredential = prefs.getBool(_biometricCredentialKey) ?? false;

    state = BiometricState(
      isEnabled: isEnabled,
      hasCredential: hasCredential,
      isVerified: false,
    );
  }

  /// Enable or disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_biometricEnabledKey, enabled);

    // If disabling, also clear credential
    if (!enabled) {
      await prefs.setBool(_biometricCredentialKey, false);
      state = state.copyWith(isEnabled: false, hasCredential: false);
    } else {
      state = state.copyWith(isEnabled: true);
    }
  }

  /// Store credential flag after successful login
  Future<void> storeCredential() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_biometricCredentialKey, true);
    state = state.copyWith(hasCredential: true);
  }

  /// Clear credential flag (on logout)
  Future<void> clearCredential() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_biometricCredentialKey, false);
    state = state.copyWith(hasCredential: false, isVerified: false);
  }

  /// Mark biometric as verified for this session
  void markVerified() {
    state = state.copyWith(isVerified: true);
  }

  /// Reset verified state (e.g., when app goes to background)
  void resetVerified() {
    state = state.copyWith(isVerified: false);
  }

  /// Check if biometric gate should be shown
  bool get shouldShowBiometricGate {
    return state.isEnabled && state.hasCredential && !state.isVerified;
  }
}

/// Provider for biometric authentication state
final biometricProvider = NotifierProvider<BiometricNotifier, BiometricState>(() {
  return BiometricNotifier();
});

// ============================================================================
// Review Providers
// ============================================================================

/// Stream of reviews for a specific vendor
final vendorReviewsProvider =
    StreamProvider.family<List<Review>, String>((ref, vendorId) {
  final dbService = ref.read(databaseServiceProvider);
  return dbService.getVendorReviewsStream(vendorId);
});

/// Stream of current user's review for a specific vendor
final userReviewProvider =
    StreamProvider.family<Review?, String>((ref, vendorId) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;

  if (user == null) {
    return Stream.value(null);
  }

  final dbService = ref.read(databaseServiceProvider);
  return dbService.getUserReviewForVendorStream(vendorId, user.uid);
});

/// Notifier for managing review actions with rate limiting
class ReviewNotifier extends Notifier<AsyncValue<void>> {
  static const String _reviewTimestampsKey = 'review_timestamps';
  static const int _maxReviewsPerHour = 5;
  static const Duration _rateLimitWindow = Duration(hours: 1);

  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Check if user can submit a review (client-side rate limiting)
  Future<bool> canSubmitReview() async {
    final timestamps = await _getReviewTimestamps();
    final now = DateTime.now();
    final windowStart = now.subtract(_rateLimitWindow);

    // Count reviews within the rate limit window
    final recentReviews =
        timestamps.where((t) => t.isAfter(windowStart)).length;

    return recentReviews < _maxReviewsPerHour;
  }

  /// Get remaining cooldown time if rate limited
  Future<Duration?> getRateLimitCooldown() async {
    final timestamps = await _getReviewTimestamps();
    if (timestamps.length < _maxReviewsPerHour) return null;

    final now = DateTime.now();
    final windowStart = now.subtract(_rateLimitWindow);

    // Get timestamps within window, sorted oldest first
    final recentTimestamps = timestamps
        .where((t) => t.isAfter(windowStart))
        .toList()
      ..sort();

    if (recentTimestamps.length < _maxReviewsPerHour) return null;

    // Calculate when the oldest review in window will expire
    final oldestInWindow = recentTimestamps.first;
    final expiresAt = oldestInWindow.add(_rateLimitWindow);

    if (expiresAt.isAfter(now)) {
      return expiresAt.difference(now);
    }

    return null;
  }

  Future<List<DateTime>> _getReviewTimestamps() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final timestampsJson = prefs.getStringList(_reviewTimestampsKey) ?? [];
    return timestampsJson
        .map((s) => DateTime.tryParse(s))
        .whereType<DateTime>()
        .toList();
  }

  Future<void> _recordReviewTimestamp() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final timestamps = await _getReviewTimestamps();
    final now = DateTime.now();
    final windowStart = now.subtract(_rateLimitWindow);

    // Keep only recent timestamps + new one
    final updatedTimestamps = [
      ...timestamps.where((t) => t.isAfter(windowStart)),
      now,
    ];

    await prefs.setStringList(
      _reviewTimestampsKey,
      updatedTimestamps.map((t) => t.toIso8601String()).toList(),
    );
  }

  Future<bool> submitReview({
    required String vendorId,
    required Review review,
  }) async {
    // Check rate limit before submitting
    if (!await canSubmitReview()) {
      final cooldown = await getRateLimitCooldown();
      final minutes = cooldown?.inMinutes ?? 0;
      state = AsyncValue.error(
        'Rate limit exceeded. Please wait $minutes minutes before submitting another review.',
        StackTrace.current,
      );
      return false;
    }

    state = const AsyncValue.loading();

    try {
      final dbService = ref.read(databaseServiceProvider);
      await dbService.addReview(vendorId, review);
      await _recordReviewTimestamp();
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateReview({
    required String vendorId,
    required String reviewId,
    required Review review,
  }) async {
    // Updates don't count toward rate limit (editing existing review)
    state = const AsyncValue.loading();

    try {
      final dbService = ref.read(databaseServiceProvider);
      await dbService.updateReview(vendorId, reviewId, review);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteReview({
    required String vendorId,
    required String reviewId,
  }) async {
    state = const AsyncValue.loading();

    try {
      final dbService = ref.read(databaseServiceProvider);
      await dbService.deleteReview(vendorId, reviewId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Provider for review actions
final reviewNotifierProvider =
    NotifierProvider<ReviewNotifier, AsyncValue<void>>(() {
  return ReviewNotifier();
});

// ============================================================================
// Deep Link Providers
// ============================================================================

/// Provides the DeepLinkService singleton
final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  final service = DeepLinkService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Stream of incoming deep links
final deepLinkStreamProvider = StreamProvider<DeepLinkData>((ref) {
  final service = ref.watch(deepLinkServiceProvider);
  return service.linkStream;
});

/// Pending deep link to be processed (set from initial link or incoming link)
final pendingDeepLinkProvider = StateProvider<DeepLinkData?>((ref) => null);
