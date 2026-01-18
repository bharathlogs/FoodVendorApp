import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/location_foreground_service.dart';
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

  // Initialize foreground task communication port
  LocationForegroundService.initCommunicationPort();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Finder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Not logged in
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // Logged in - determine role
        return FutureBuilder<UserModel?>(
          future: AuthService().getUserData(snapshot.data!.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final user = userSnapshot.data;
            if (user == null) {
              return const LoginScreen();
            }

            if (user.role == UserRole.vendor) {
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
