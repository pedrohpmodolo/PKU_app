// lib/main.dart
import 'package:flutter/material.dart';              // Core Flutter framework
import 'package:flutter_dotenv/flutter_dotenv.dart';  // Load environment variables from .env
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase client SDK

import 'screens/onboarding_screen.dart';              // Onboarding flow UI
import 'screens/auth/auth_screen.dart';               // Sign In / Sign Up UI
import 'screens/home/home_screen.dart';               // Home screen with bottom tabs
import 'screens/home/settings/settings.dart';         // Settings overview screen
import 'theme.dart';                                  // Light/dark theme definitions

Future<void> main() async {
  // Ensure Flutter binding is initialized before any async or plugin calls
  WidgetsFlutterBinding.ensureInitialized();
  // Load API keys and other secrets from the .env file
  await dotenv.load();
  // Initialize Supabase with URL and anon key from environment
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANNON_KEY']!,
  );
  // Start the app by running the PKUApp widget
  runApp(const PKUApp());
}

/// PKUApp manages global state (theme, auth routing)
class PKUApp extends StatefulWidget {
  const PKUApp({super.key});

  @override
  State<PKUApp> createState() => _PKUAppState();
}

class _PKUAppState extends State<PKUApp> {
  // Tracks whether the app uses light, dark, or system theme
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    // Listen for Supabase auth changes (sign-in, sign-out)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        // Navigate to HomeScreen when signed in
        Navigator.pushReplacementNamed(context, HomeScreen.routeName);
      } else if (event == AuthChangeEvent.signedOut) {
        // Navigate back to AuthScreen when signed out
        Navigator.pushReplacementNamed(context, AuthScreen.routeName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if a session already exists (persisted login)
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      debugShowCheckedModeBanner: false,              // Disable debug banner
      title: 'PKU Wise',                              // App title

      // Apply custom themes
      theme: lightThemeData,                          // Light theme data
      darkTheme: darkThemeData,                       // Dark theme data
      themeMode: _themeMode,                          // Currently active theme

      // Determine initial screen: Home if logged in, otherwise Onboarding
      initialRoute: session != null
          ? HomeScreen.routeName
          : OnboardingScreen.routeName,

      // Define named routes for navigation
      routes: {
        OnboardingScreen.routeName: (ctx) => OnboardingScreen(
              onToggleTheme: (newMode) => setState(() => _themeMode = newMode),
            ),
        AuthScreen.routeName: (ctx)       => const AuthScreen(),
        HomeScreen.routeName: (ctx)       => const HomeScreen(),
        SettingsScreen.routeName: (ctx)   => const SettingsScreen(),
      },
    );
  }
}