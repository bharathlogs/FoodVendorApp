import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/location_foreground_service.dart';
import 'services/analytics_service.dart';
import 'services/notification_service.dart';
import 'providers/providers.dart';
import 'models/user_model.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/biometric_prompt_screen.dart';
import 'screens/vendor/vendor_home.dart';
import 'screens/customer/customer_home.dart';
import 'screens/splash/splash_screen.dart';
import 'core/navigation/app_page_route.dart';
import 'core/navigation/app_transitions.dart';
import 'services/deep_link_service.dart';
import 'services/database_service.dart';
import 'screens/customer/vendor_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Initialize Firebase Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Register FCM background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize FCM notifications
  await NotificationService().initialize();

  // Initialize foreground task communication port
  LocationForegroundService.initCommunicationPort();

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _deepLinksInitialized = false;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    if (_deepLinksInitialized) return;
    _deepLinksInitialized = true;

    final deepLinkService = ref.read(deepLinkServiceProvider);

    // Initialize and handle initial link
    final initialLink = await deepLinkService.initialize();
    if (initialLink != null) {
      ref.read(pendingDeepLinkProvider.notifier).state = initialLink;
    }

    // Listen for incoming links
    deepLinkService.linkStream.listen((linkData) {
      _handleDeepLink(linkData);
    });
  }

  void _handleDeepLink(DeepLinkData linkData) {
    switch (linkData.type) {
      case DeepLinkType.vendor:
        _navigateToVendor(linkData.id);
        break;
    }
  }

  Future<void> _navigateToVendor(String vendorId) async {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    // Fetch vendor data
    final dbService = DatabaseService();
    final vendor = await dbService.getVendorProfile(vendorId);

    if (vendor != null && mounted) {
      navigator.push(
        AppPageRoute(
          page: VendorDetailScreen(vendor: vendor),
          transitionType: AppTransitionType.slideRight,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    // Listen for pending deep links (set during splash/auth)
    ref.listen<DeepLinkData?>(pendingDeepLinkProvider, (previous, next) {
      if (next != null) {
        // Clear the pending link and handle it
        ref.read(pendingDeepLinkProvider.notifier).state = null;
        _handleDeepLink(next);
      }
    });

    return MaterialApp(
      title: 'Food Finder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      navigatorKey: _navigatorKey,
      navigatorObservers: [AnalyticsService().observer],
      home: const WithForegroundTask(
        child: SplashWrapper(),
      ),
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    Widget? page;
    AppTransitionType transitionType = AppTransitionType.slideRight;

    switch (settings.name) {
      case '/login':
        page = const LoginScreen();
        transitionType = AppTransitionType.fade;
        break;
      case '/signup':
        page = const SignupScreen();
        transitionType = AppTransitionType.slideUp;
        break;
      case '/vendor-home':
        page = const WithForegroundTask(child: VendorHome());
        transitionType = AppTransitionType.fadeScale;
        break;
      case '/customer-home':
        page = const CustomerHome();
        transitionType = AppTransitionType.fadeScale;
        break;
    }

    if (page == null) return null;

    return AppPageRoute(
      page: page,
      transitionType: transitionType,
      settings: settings,
    );
  }
}

/// Wrapper that shows splash screen then transitions to auth
class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  bool _showSplash = true;

  void _onSplashComplete() {
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onComplete: _onSplashComplete);
    }
    return const AuthWrapper();
  }
}

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _bypassBiometric = false;

  void _onBiometricSuccess() {
    ref.read(biometricProvider.notifier).markVerified();
  }

  void _onUsePassword() {
    setState(() {
      _bypassBiometric = true;
    });
    // Sign out to force password login
    ref.read(authServiceProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final biometricState = ref.watch(biometricProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const LoginScreen(),
      data: (user) {
        if (user == null) {
          // Reset bypass when logged out
          if (_bypassBiometric) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _bypassBiometric = false;
              });
            });
          }
          return const LoginScreen();
        }

        // Logged in - determine role
        return FutureBuilder<UserModel?>(
          future: ref.read(authServiceProvider).getUserData(user.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final userData = userSnapshot.data;
            if (userData == null) {
              return const LoginScreen();
            }

            // Check if biometric gate should be shown
            if (!_bypassBiometric &&
                biometricState.isEnabled &&
                biometricState.hasCredential &&
                !biometricState.isVerified) {
              return BiometricPromptScreen(
                onSuccess: _onBiometricSuccess,
                onUsePassword: _onUsePassword,
              );
            }

            if (userData.role == UserRole.vendor) {
              return const VendorHome();
            } else {
              return const CustomerHome();
            }
          },
        );
      },
    );
  }
}
