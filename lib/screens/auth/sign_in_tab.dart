import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home/home_screen.dart'; // Use this to navigate after successful login
import 'complete_profile_screen.dart';

/// SignInTab: Allows users to log in via email/password or Google OAuth.
class SignInTab extends StatefulWidget {
  const SignInTab({super.key});

  @override
  State<SignInTab> createState() => _SignInTabState();
}

class _SignInTabState extends State<SignInTab> {
  final _formKey = GlobalKey<FormState>();      // Key to validate the login form
  final _email = TextEditingController();       // Controller for the Email field
  final _password = TextEditingController();    // Controller for the Password field
  bool _loading = false;                        // Tracks whether a login request is in progress

  /// Handles email/password login
  Future<void> _submit() async {
    // Only proceed if the form inputs pass validation
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true); // Disable inputs while loading
    try {
      // Call Supabase auth API to sign in with email & password
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (res.session != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed in successfully!')),
        );
        // Navigate to Comple Profile Screen, replacing this screen
        Navigator.of(context).pushReplacementNamed(CompleteProfileScreen.routeName);
      }
    } on AuthException catch (e) {
      // Display any errors from Supabase
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      setState(() => _loading = false); // Re-enable inputs
    }
  }

  /// Starts the Google OAuth flow
  Future<void> _googleSignIn() async {
    // Opens the browser for Google sign-in
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
    );
    // After OAuth completes, navigate to HomeScreen
    Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24), // Add space around the form
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Login form
          Form(
            key: _formKey,
            child: Column(
              children: [
                // Email input
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter email' : null,
                ),
                const SizedBox(height: 16),

                // Password input
                TextFormField(
                  controller: _password,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true, // Hides the input text
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Min 6 chars' : null,
                ),
                const SizedBox(height: 24),

                // Sign In button
                ElevatedButton(
                  onPressed: _loading ? null : _submit, // Disable if loading
                  child: Text(_loading ? 'Signing in…' : 'Sign In'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Google OAuth button
          OutlinedButton.icon(
            onPressed: _googleSignIn,
            icon: Image.asset(
              'lib/assets/icons/google_logo.png',
              height: 24,
              width: 24,
            ),
            label: const Text('Continue with Google'),
          ),
        ],
      ),
    );
  }
}
