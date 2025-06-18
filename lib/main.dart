import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/onboarding_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/settings/settings.dart';
import 'screens/home/settings/account_settings.dart';
import 'theme.dart';
import 'screens/home/chat/chat_screen.dart';

Future<void> main() async {
  // Ensure Flutter binding is initialized before any async or plugin calls
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env (e.g. SUPABASE_URL, SUPABASE_ANNON_KEY)
  await dotenv.load();

  // Initialize Supabase client with project credentials
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANNON_KEY']!,
  );

  // Supabase automatically handles deep links for email confirmation (version 1.10.0+)

  // Launch the app
  runApp(const PKUApp());
}

/// Root widget for managing app-wide state (theme + routing)
class PKUApp extends StatefulWidget {
  const PKUApp({super.key});

  @override
  State<PKUApp> createState() => _PKUAppState();
}

class _PKUAppState extends State<PKUApp> {
  // Controls app theme (light, dark, or system preference)
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();

    // Auth state listener (sign in / sign out) for routing decisions
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        Navigator.pushReplacementNamed(context, HomeScreen.routeName);
      } else if (event == AuthChangeEvent.signedOut) {
        Navigator.pushReplacementNamed(context, AuthScreen.routeName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check for an existing session to skip onboarding
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PKU Wise',

      // Apply theme settings
      theme: lightThemeData,
      darkTheme: darkThemeData,
      themeMode: _themeMode,

      // Determine initial screen based on auth session
      initialRoute: session != null
          ? HomeScreen.routeName
          : OnboardingScreen.routeName,

      // Define available routes
      routes: {
        OnboardingScreen.routeName: (ctx) => OnboardingScreen(
              onToggleTheme: (newMode) => setState(() => _themeMode = newMode),
            ),
        AuthScreen.routeName: (ctx)     => const AuthScreen(),
        HomeScreen.routeName: (ctx)     => const HomeScreen(),
        SettingsScreen.routeName: (ctx) => const SettingsScreen(),
      },
    );
  }
}
