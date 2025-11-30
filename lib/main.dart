// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'screens/landing_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/language_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (safe try/catch so app still runs if init fails)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    debugPrint('Firebase initialization error: $e\n$st');
  }

  runApp(const AgrioDemoApp());
}

class AgrioDemoApp extends StatelessWidget {
  const AgrioDemoApp({super.key});

  // Routes that are allowed when the user is NOT signed in.
  static const Set<String> publicRoutes = {
    '/',        // LanguageScreen (always open)
    '/login',
    '/signup',
  };

  // If you later want to allow more public screens, add them above.

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF74C043);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crop AI',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0E0E0E),
        colorScheme: const ColorScheme.dark().copyWith(
          primary: primaryGreen,
          secondary: primaryGreen,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),

      // We'll use initialRoute and onGenerateRoute to guard navigation
      initialRoute: '/',
      // We keep a minimal routes map for convenience, but navigation goes through onGenerateRoute.
      routes: {
        '/': (_) => const LanguageScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
      },

      // Central route generator with auth guard.
      onGenerateRoute: (RouteSettings settings) {
        final String name = settings.name ?? '/';
        final Object? args = settings.arguments;

        // If target is public, just return its route
        if (publicRoutes.contains(name)) {
          return _buildRouteByName(name, args);
        }

        // For non-public routes, check Firebase auth state synchronously
        final user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          // Not signed in -> redirect to login (pass original route so login can redirect back after success)
          return MaterialPageRoute(
            settings: const RouteSettings(name: '/login'),
            builder: (context) => const LoginScreen(),
          );
        }

        // Signed in -> allow the requested protected route
        return _buildRouteByName(name, args);
      },

      // Optional: unknown route fallback
      onUnknownRoute: (settings) {
        // If route isn't defined, send to home if signed in, otherwise to language.
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          return MaterialPageRoute(builder: (_) => const HomeScreen());
        } else {
          return MaterialPageRoute(builder: (_) => const LanguageScreen());
        }
      },

      // keep a simple builder
      builder: (context, child) {
        return child!;
      },
    );
  }

  // Helper to create MaterialPageRoute for the named screens you have.
  MaterialPageRoute<dynamic>? _buildRouteByName(String name, Object? args) {
    switch (name) {
      case '/':
        return MaterialPageRoute(settings: const RouteSettings(name: '/'), builder: (_) => const LanguageScreen());
      case '/login':
        return MaterialPageRoute(settings: const RouteSettings(name: '/login'), builder: (_) => const LoginScreen());
      case '/signup':
        return MaterialPageRoute(settings: const RouteSettings(name: '/signup'), builder: (_) => const SignupScreen());
      case '/home':
        return MaterialPageRoute(settings: const RouteSettings(name: '/home'), builder: (_) => const HomeScreen());
      case '/profile':
        return MaterialPageRoute(settings: const RouteSettings(name: '/profile'), builder: (_) => const ProfileScreen());
      case '/landing':
        return MaterialPageRoute(settings: const RouteSettings(name: '/landing'), builder: (_) => const LandingScreen());
      default:
        return null; // will be handled by onUnknownRoute
    }
  }
}
