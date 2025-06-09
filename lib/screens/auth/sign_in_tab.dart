import 'package:flutter/material.dart';

class SignInTab extends StatefulWidget {
  const SignInTab({Key? key}) : super(key: key);

  @override
  State<SignInTab> createState() => _SignInTabState();
}

class _SignInTabState extends State<SignInTab> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: auth logic
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Signing in…')));
    }
  }

  void _googleSignIn() {
    // TODO: integrate Google Sign-In logic here
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Google Sign-In…')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Please enter your email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Password must be at least 6 chars'
                      : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Sign In'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
