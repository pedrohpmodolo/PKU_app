// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
// Supabase client SDK (not used directly here)
import 'settings/settings.dart';                         // Import your hierarchical SettingsScreen
import 'chat/conversation_list.dart';                   // Import the ConversationListScreen
import 'ingredient_input_screen.dart';                 // Import the IngredientInputScreen
import '../../models/analyzed_meal.dart';             // Import the AnalyzedMeal model

/// HomeScreen: hosts a fixed bottom tab bar to switch between
/// the main dashboard content ("Home") and the Settings hierarchy.
class HomeScreen extends StatefulWidget {
  /// Named route for navigation
  static const routeName = '/home';

  const HomeScreen({super.key});

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
    ConversationListScreen(),  // The chat screen
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

          //Home button NavBar
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),

          // Chat button NavBar
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),

          // Settings button NavBar
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
/// KSP-updated
class _HomePageContent extends StatefulWidget {
  const _HomePageContent();

  @override
  State<_HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<_HomePageContent> {
  List<AnalyzedMeal> _dailyMeals = [];

  // Commented out for future use
  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   final args = ModalRoute.of(context)?.settings.arguments;
  //   if (args is String) {
  //     setState(() {
  //       _analyzedMeals = args;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '💖Welcome to your dashboard!💖',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                // Push the screen and wait for results
                final result = await Navigator.of(context).pushNamed('/ingredient-input');
                if (result is Map<String, dynamic>) {
                  setState(() {
                    _dailyMeals.add(
                      AnalyzedMeal(
                        mealType: result['mealType'],
                        ingredients: (result['ingredients'] as String).split(',').map((e) => e.trim()).toList(),
                        pheAmount: (result['phe'] ?? 0).toDouble(),
                      ),
                    );
                  });
                }
              },
              icon: Icon(Icons.science_outlined),
              label: Text("Analyze Ingredients"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5DADE2), // 💙 PKU awareness blue
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 24),

            // 🧠 Recently Analyzed
            if (_dailyMeals.isNotEmpty)
              Card(
                color: Colors.teal[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("🧬 Today’s PHE Summary", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        "Total PHE: ${_dailyMeals.fold<double>(0, (sum, m) => sum + m.pheAmount).toStringAsFixed(2)} mg / 250mg",
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 12),
                      ..._dailyMeals.map((meal) => ListTile(
                            leading: Icon(Icons.local_dining, color: Color(0xFF5DADE2)),
                            title: Text(meal.mealType),
                            subtitle: Text(meal.ingredients.join(", ")),
                            trailing: Text("${meal.pheAmount.toStringAsFixed(1)} mg"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
//end{code}