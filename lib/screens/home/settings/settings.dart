// lib/screens/home/settings/settings.dart

import 'package:flutter/material.dart';
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
    super.key,
    required this.title,
    required this.items,
  });

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

/// Stub screens for the “General” group:
class ControlCenterSettingsScreen extends StatelessWidget {
  const ControlCenterSettingsScreen({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('Control Center')),
        body: const Center(child: Text('Control Center settings here')),
      );
}

class DisplayBrightnessSettingsScreen extends StatelessWidget {
  const DisplayBrightnessSettingsScreen({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('Display & Brightness')),
        body: const Center(child: Text('Display & Brightness settings here')),
      );
}

class HomeScreenSettingsScreen extends StatelessWidget {
  const HomeScreenSettingsScreen({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('Home Screen')),
        body: const Center(child: Text('Home Screen settings here')),
      );
}

class AccessibilitySettingsScreen extends StatelessWidget {
  const AccessibilitySettingsScreen({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('Accessibility')),
        body: const Center(child: Text('Accessibility settings here')),
      );
}

class WallpaperSettingsScreen extends StatelessWidget {
  const WallpaperSettingsScreen({super.key});
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
      SettingItem(
        title: 'Control Center',
        icon: Icons.control_camera,
        page: ControlCenterSettingsScreen(),
      ),
      SettingItem(
        title: 'Display & Brightness',
        icon: Icons.brightness_6,
        page: DisplayBrightnessSettingsScreen(),
      ),
      SettingItem(
        title: 'Home Screen',
        icon: Icons.home,
        page: HomeScreenSettingsScreen(),
      ),
      SettingItem(
        title: 'Accessibility',
        icon: Icons.accessibility,
        page: AccessibilitySettingsScreen(),
      ),
      SettingItem(
        title: 'Wallpaper',
        icon: Icons.wallpaper,
        page: WallpaperSettingsScreen(),
      ),
    ],
  ),
  SettingItem(
    title: 'Account',
    icon: Icons.person,
    page: AccountSettings(),
  ),
];

/// Entry‐point for Settings tab.
class SettingsScreen extends StatelessWidget {
  static const routeName = '/settings';
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingGroupScreen(
      title: 'Settings',
      items: _settingsTree,
    );
  }
}
