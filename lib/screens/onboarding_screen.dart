// lib/screens/onboarding_screen.dart
// for ImageFilter
// First screen when user interact with the app

import 'package:flutter/material.dart';
import 'auth/auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  static const routeName = '/onboarding';

  /// Callback to let parent toggle between light/dark themes
  final void Function(ThemeMode)? onToggleTheme;

  const OnboardingScreen({
    super.key,
    this.onToggleTheme,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // List of onboarding data: title and description text
  final List<Map<String, String>> _pagesData = [
    {
      'title': 'Welcome to PKU Wise',
      'body':
          'PKU Wise is an AI-powered dietary assistant designed for Phenylketonuria management. Our algorithms analyze your nutritional needs and provide personalized meal recommendations.',
    },
    {
      'title': 'Clinical Accuracy',
      'body':
          'All phenylalanine thresholds and nutrient calculations are verified by licensed dietitians. PKU Wise will alert you if a food item exceeds your daily limit.',
    },
    {
      'title': 'Get Started',
      'body':
          'Create an account or log in to save your profile and begin your personalized PKU journey.',
    },
  ];

  void _onNextPressed() {
    if (_currentPage < _pagesData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pushReplacementNamed(AuthScreen.routeName);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Optional subtle texture or background color could go here.
          // For a plain background, omit this Stack child.
          Positioned.fill(
            child: Container(color: colorScheme.surface),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top-right moon button for theme toggle
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0, top: 16.0),
                    child: IconButton(
                      icon: Icon(
                        Theme.of(context).brightness == Brightness.light
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined,
                        color: colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
                        size: 24,
                      ),
                      tooltip: 'Toggle theme',
                      onPressed: () {
                        if (widget.onToggleTheme != null) {
                          final nextMode = Theme.of(context).brightness ==
                                  Brightness.light
                              ? ThemeMode.dark
                              : ThemeMode.light;
                          widget.onToggleTheme!(nextMode);
                        }
                      },
                    ),
                  ),
                ),

                // Expanded PageView to hold each onboarding page
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pagesData.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (ctx, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24.0, vertical: 48.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _pagesData[index]['title']!,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _pagesData[index]['body']!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: colorScheme.onSurface),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Dots indicator using colorScheme.primary for the active dot
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < _pagesData.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == i ? 12 : 8,
                          height: _currentPage == i ? 12 : 8,
                          decoration: BoxDecoration(
                            color: (_currentPage == i)
                                ? colorScheme.primary
                                : colorScheme.onSurface.withAlpha((0.3 * 255).toInt()),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),

                // “Next”/“Get Started” button
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _onNextPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _currentPage < _pagesData.length - 1
                            ? 'Next'
                            : 'Get Started',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
