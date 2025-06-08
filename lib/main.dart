// lib/main.dart
import 'package:flutter/material.dart'; // Flutter framework core

import 'screens/onboarding_screen.dart'; // Onboarding flow UI
import 'screens/auth/auth_screen.dart'; // Authentication UI
import 'theme.dart'; // Custom light/dark theme definitions

void main() {
  // Ensure widget binding before using any plugins or platform channels
  WidgetsFlutterBinding.ensureInitialized();
  // Launch the app, instantiating the PKUApp widget
  runApp(const PKUApp());
}

// Stateful widget to manage app-level state (e.g., theme)
class PKUApp extends StatefulWidget {
  const PKUApp({super.key});

  @override
  State<PKUApp> createState() => _PKUAppState();
}

class _PKUAppState extends State<PKUApp> {
  // Current theme mode; starts following the system setting
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Hide the debug banner in debug builds
      title: 'PKU Wise', // App title used by the OS

      // 1) Apply custom light theme
      theme: lightThemeData,
      // 2) Apply custom dark theme
      darkTheme: darkThemeData,
      // 3) Choose between light/dark based on _themeMode
      themeMode: _themeMode,

      // Start the user experience at the onboarding screen
      initialRoute: OnboardingScreen.routeName,
      routes: {
        // Onboarding route: passes a callback to toggle theme
        OnboardingScreen.routeName: (ctx) => OnboardingScreen(
              onToggleTheme: (newMode) {
                // Update theme mode when user toggles
                setState(() => _themeMode = newMode);
              },
            ),
        // Authentication route: simple static screen
        AuthScreen.routeName: (ctx) => const AuthScreen(),
      },
    );
  }
}
