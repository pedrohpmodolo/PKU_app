// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase client SDK (not used directly here)
import 'settings/settings.dart'; // Import your hierarchical SettingsScreen
import 'chat/conversation_list.dart'; // Import the ConversationListScreen
import 'scanner/analyze_screen.dart'; // Import the AnalyzeScreen

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
    const _HomePageContent(), // Your dashboard / main content
    ConversationListScreen(),
    AnalyzeScreen(), // The chat screen
    const SettingsScreen(), // The hierarchical Settings screen
    // const AnalyzeScreen(),  //The screen for scanning and analyzing food items
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        // Show the page matching the selected tab
        body: _pages[_currentIndex],
        
        // Bottom navigation bar with two items: Home and Settings
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: Colors.blueGrey,
          unselectedItemColor: Colors.grey, // Highlight active tab
          onTap: (index) => setState(() {
            // Update index on tap
            _currentIndex = index;
          }),
          items: const [
            //Home button NavBar
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            
            // Chat button NavBar
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble),
              label: 'Chat',
            ),
            
            // Scan button NavBar
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner),
              label: 'Scan',
            ),
            
            // Settings button NavBar
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
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
