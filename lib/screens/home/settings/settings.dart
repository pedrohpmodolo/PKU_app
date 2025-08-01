// lib/screens/home/settings/settings.dart

import 'package:flutter/material.dart';
import 'package:pkuapp/screens/onboarding_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account_screen.dart'; // New screen for credentials
import 'diet_profile_screen.dart'; // New screen for PKU details
import 'reports_list_screen.dart';
import 'notifications_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _supabase = Supabase.instance.client;

  Future<void> _logout() async {
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

    if (confirm == true && mounted) {
      await _supabase.auth.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen(onToggleTheme: null)),
        (_) => false,
      );
    }
  }

  // Helper widget for section headers like "ACCOUNT", "APP".
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  // Helper widget for a single, tappable setting item.
  Widget _buildSettingsTile({
    required String title,
    required IconData icon,
    VoidCallback? onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
      title: Text(title, style: TextStyle(color: color)),
      trailing: color == null ? const Icon(Icons.chevron_right, size: 18) : null,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    final userName = user?.userMetadata?['name'] ?? 'PKU Wise User';
    final userEmail = user?.email ?? 'No email found';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Profile')),
      body: ListView(
        children: [
          // --- User Profile Header Card ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: TextStyle(
                          fontSize: 24,
                          color: Theme.of(context).colorScheme.onPrimaryContainer)),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: Theme.of(context).textTheme.titleLarge),
                    Text(userEmail, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
          ),

          _buildSectionHeader('Diet'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSettingsTile(
              title: 'Edit Diet & Goals',
              icon: Icons.local_dining_outlined,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DietProfileScreen()),
                );
              },
            ),
          ),

          _buildSectionHeader('Reports'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSettingsTile(
              title: 'View My Reports',
              icon: Icons.bar_chart_outlined,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReportsListScreen()),
                );
              },
            ),
          ),
          
          _buildSectionHeader('Account & Security'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSettingsTile(
              title: 'Privacy & Credentials',
              icon: Icons.security_outlined,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AccountScreen()),
                );
              },
            ),
          ),
          
          _buildSectionHeader('App'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildSettingsTile(
                  title: 'Notifications',
                  icon: Icons.notifications_outlined,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                _buildSettingsTile(
                  title: 'About',
                  icon: Icons.info_outline,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              onPressed: _logout,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.red.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}