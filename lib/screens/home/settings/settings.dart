// lib/screens/home/settings/settings.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <-- 1. ADD THIS IMPORT
import 'package:pkuapp/screens/onboarding_screen.dart';   // <-- 2. ADD THIS IMPORT
import 'account_settings.dart';

/// A node in the settings hierarchy: either a leaf (page) or a group (children).
class SettingItem {
  final String title;
  final IconData icon;
  final Widget? page;
  final List<SettingItem>? children;

  const SettingItem({
    required this.title,
    required this.icon,
    this.page,
    this.children,
  }) : assert((page == null) ^ (children == null),
            'Either page or children must be non-null, but not both');
}

/// Reusable screen for a group of settings items.
class SettingGroupScreen extends StatelessWidget {
  final String title;
  final List<SettingItem> items;

  const SettingGroupScreen({
    Key? key,
    required this.title,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final item = items[i];
          return ListTile(
            leading: Icon(item.icon),
            title: Text(item.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (item.children != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingGroupScreen(
                      title: item.title,
                      items: item.children!,
                    ),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => item.page!),
                );
              }
            },
          );
        },
      ),
    );
  }
}

// ... (All your other placeholder screens like ControlCenterSettingsScreen remain the same) ...

class ControlCenterSettingsScreen extends StatelessWidget {
  const ControlCenterSettingsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('Control Center')),
        body: const Center(child: Text('Control Center settings here')),
      );
}

class DisplayBrightnessSettingsScreen extends StatelessWidget {
  const DisplayBrightnessSettingsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('Display & Brightness')),
        body: const Center(child: Text('Display & Brightness settings here')),
      );
}

class HomeScreenSettingsScreen extends StatelessWidget {
  const HomeScreenSettingsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('Home Screen')),
        body: const Center(child: Text('Home Screen settings here')),
      );
}

class AccessibilitySettingsScreen extends StatelessWidget {
  const AccessibilitySettingsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('Accessibility')),
        body: const Center(child: Text('Accessibility settings here')),
      );
}

class WallpaperSettingsScreen extends StatelessWidget {
  const WallpaperSettingsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('Wallpaper')),
        body: const Center(child: Text('Wallpaper settings here')),
      );
}


/// The root of your settings hierarchy.
const _settingsTree = <SettingItem>[
  SettingItem(
    title: 'General',
    icon: Icons.settings,
    children: [
      // ... (your general settings remain here)
    ],
  ),
  SettingItem(
    title: 'Account',
    icon: Icons.person,
    page: AccountSettings(),
  ),
];

// --- 3. THIS WIDGET HAS BEEN UPDATED ---
/// Entry‐point for Settings tab.
class SettingsScreen extends StatelessWidget {
  static const routeName = '/settings';
  const SettingsScreen({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    // Show a confirmation dialog before logging out
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await Supabase.instance.client.auth.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen(onToggleTheme: null)),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Build the original settings list
          for (final item in _settingsTree)
            ListTile(
              leading: Icon(item.icon),
              title: Text(item.title),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                if (item.children != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SettingGroupScreen(
                        title: item.title,
                        items: item.children!,
                      ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => item.page!),
                  );
                }
              },
            ),
          
          // Add a divider and the new Log Out button
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log Out', style: TextStyle(color: Colors.red)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}