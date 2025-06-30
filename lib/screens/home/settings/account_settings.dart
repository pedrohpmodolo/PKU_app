// lib/screens/home/settings/account_settings.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../screens/onboarding_screen.dart'; // Navigate to onboarding after logout

/// AccountSettings: allows user to view and update profile, change email/password,
/// and logout.
class AccountSettings extends StatefulWidget {
  static const routeName = '/settings/account';
  const AccountSettings({super.key});

  @override
  State<AccountSettings> createState() => _AccountSettingsState();
}

class _AccountSettingsState extends State<AccountSettings> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _selectedCountry;
  bool _loading = false;

  // Example country list
  final List<String> _countries = const [
    'United States', 'Canada', 'United Kingdom', 'Australia', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata ?? {};
    _firstNameController = TextEditingController(text: metadata['first_name'] as String? ?? '');
    _middleNameController = TextEditingController(text: metadata['middle_name'] as String? ?? '');
    _lastNameController = TextEditingController(text: metadata['last_name'] as String? ?? '');
    _selectedCountry = metadata['country'] as String?;
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Handle profile, email, and password updates
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final attrs = UserAttributes(
        email: _emailController.text.trim(),
        password: _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
        data: {
          'first_name': _firstNameController.text.trim(),
          'middle_name': _middleNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'country': _selectedCountry,
        },
      );
      await Supabase.instance.client.auth.updateUser(attrs);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Sign out and return to onboarding
  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen(onToggleTheme: null)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // First Name
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter first name' : null,
                ),
                const SizedBox(height: 16),
                // Middle Name (optional)
                TextFormField(
                  controller: _middleNameController,
                  decoration: const InputDecoration(labelText: 'Middle Name (optional)'),
                ),
                const SizedBox(height: 16),
                // Last Name
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter last name' : null,
                ),
                const SizedBox(height: 16),
                // Country
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Country'),
                  value: _selectedCountry,
                  items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedCountry = v),
                  validator: (v) => (v == null) ? 'Select a country' : null,
                ),
                const SizedBox(height: 16),
                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter email' : null,
                ),
                const SizedBox(height: 16),
                // New Password
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'New Password'),
                  obscureText: true,
                  validator: (v) => v != null && v.isNotEmpty && v.length < 6
                      ? 'Min 6 chars'
                      : null,
                ),
                const SizedBox(height: 24),
                // Update Profile button
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: Text(_loading ? 'Updating…' : 'Update Profile'),
                ),
                const SizedBox(height: 16),
                // Logout button
                OutlinedButton(
                  onPressed: _logout,
                  child: const Text('Log Out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
