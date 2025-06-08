import 'package:flutter/material.dart';
import '../../theme.dart'; 

class AuthScreen extends StatelessWidget {
  static const routeName = '/auth';

  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // “PKU Wise” Title
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

              // TabBar: Sign In / Sign Up
              TabBar(
                labelColor: colorScheme.primary,
                unselectedLabelColor:
                    colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
                indicatorColor: colorScheme.primary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                tabs: const [
                  Tab(text: 'Sign In'),
                  Tab(text: 'Sign Up'),
                ],
              ),

              // TabBarView: switches between SignInTab and SignUpTab
              const Expanded(
                child: TabBarView(
                  children: [
                  
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
