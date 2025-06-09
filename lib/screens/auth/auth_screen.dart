import 'package:flutter/material.dart';
import 'sign_in_tab.dart';
import 'sign_up_tab.dart';

/// AuthScreen: Hosts the Sign In and Sign Up tabs within a tab controller.
class AuthScreen extends StatelessWidget {
  /// Named route used for navigation
  static const routeName = '/auth';

  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the app's color scheme for consistent theming
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      // Number of tabs: Sign In and Sign Up
      length: 2,
      child: Scaffold(
        // Ensures UI avoids system overlays like notches or status bar
        body: SafeArea(
          child: Column(
            children: [
              // App title with padding
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                child: Row(
                  children: [
                    Text(
                      'PKU Wise',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // Tab bar with two options: Sign In and Sign Up
              TabBar(
                labelColor: colorScheme.primary, // Active tab label color
                unselectedLabelColor: colorScheme.onSurface
                    .withAlpha((0.6 * 255).toInt()), // Inactive label color
                indicatorColor: colorScheme.primary, // Underline indicator color
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18), // Label text style
                tabs: const [
                  Tab(text: 'Sign In'), // First tab
                  Tab(text: 'Sign Up'), // Second tab
                ],
              ),

              // TabBarView displays the content for each tab
              const Expanded(
                child: TabBarView(
                  children: [
                    SignInTab(), // Content for Sign In tab
                    SignUpTab(), // Content for Sign Up tab
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
