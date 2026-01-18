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
import 'screens/vendor/vendor_home.dart';
import 'screens/customer/customer_home.dart';
import 'screens/splash/splash_screen.dart';
import 'core/navigation/app_page_route.dart';
import 'core/navigation/app_transitions.dart';

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

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Food Finder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
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

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const LoginScreen(),
      data: (user) {
        if (user == null) {
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
