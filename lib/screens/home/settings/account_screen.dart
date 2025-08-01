// lib/screens/home/settings/account_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _supabase = Supabase.instance.client;

  Future<void> _changePassword() async {
    final email = _supabase.auth.currentUser?.email;
    if (email == null) return;
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Password reset link sent to your email.'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red));
      }
    }
  }

  // --- THIS IS THE CORRECTED FUNCTION ---
  Future<void> _changeEmail() async {
    final newEmailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final currentUserEmail = _supabase.auth.currentUser?.email;

    if (currentUserEmail == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Email'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: newEmailController,
                  decoration: const InputDecoration(labelText: 'New Email'),
                  validator: (val) => (val == null || !val.contains('@')) ? 'Invalid email' : null,
                ),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Current Password'),
                  obscureText: true,
                  validator: (val) => (val == null || val.length < 6) ? 'Password is required' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(); // Close dialog
                  try {
                    // 1. Verify user's current password by signing them in again.
                    await _supabase.auth.signInWithPassword(
                      email: currentUserEmail,
                      password: passwordController.text,
                    );

                    // 2. If sign-in is successful, update the email.
                    await _supabase.auth.updateUser(UserAttributes(email: newEmailController.text));
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Confirmation links sent to both your old and new email addresses.'),
                          backgroundColor: Colors.green));
                    }
                  } catch (e) {
                     if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Error: Invalid credentials or another issue occurred.'),
                          backgroundColor: Colors.red));
                    }
                  }
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account & Security')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Change Email'),
            subtitle: const Text('Requires password confirmation'),
            onTap: _changeEmail,
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            subtitle: const Text('Sends a reset link to your email'),
            onTap: _changePassword,
          ),
        ],
      ),
    );
  }
}