// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';  // Supabase client SDK (not used directly here)
import 'settings/settings.dart';                         // Import your hierarchical SettingsScreen

/// HomeScreen: hosts a fixed bottom tab bar to switch between
/// the main dashboard content ("Home") and the Settings hierarchy.
class HomeScreen extends StatefulWidget {
  /// Named route for navigation
  static const routeName = '/home';

  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Tracks which bottom tab is currently selected:
  /// 0 = Home, 1 = Settings
  int _currentIndex = 0;

  /// The pages to display for each tab index.
  final List<Widget> _pages = [
    const _HomePageContent(),  // Your dashboard / main content
    const SettingsScreen(),    // The hierarchical Settings screen
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Show the page matching the selected tab
      body: _pages[_currentIndex],

      // Bottom navigation bar with two items: Home and Settings
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,          // Highlight active tab
        onTap: (index) => setState(() {       // Update index on tap
          _currentIndex = index;
        }),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// Placeholder widget for the Home tab’s content.
/// Replace this with your real home/dashboard UI.
class _HomePageContent extends StatelessWidget {
  const _HomePageContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Text(
          'Welcome to your dashboard!',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
