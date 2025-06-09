import 'package:flutter/material.dart';

class SignUpTab extends StatefulWidget {
  const SignUpTab({Key? key}) : super(key: key);

  @override
  State<SignUpTab> createState() => _SignUpTabState();
}

class _SignUpTabState extends State<SignUpTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: sign-up logic
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Creating account…')));
    }
  }

  void _googleSignUp() {
    // TODO: integrate Google Sign-Up logic here
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Google Sign-Up…')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter your email' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmController,
                    decoration:
                        const InputDecoration(labelText: 'Confirm Password'),
                    obscureText: true,
                    validator: (v) => v != _passwordController.text
                        ? 'Passwords don’t match'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _googleSignUp,
              icon: Image.asset(
                'lib/assets/icons/google_logo.png',
                height: 24,
                width: 24,
              ),
              label: const Text('Continue with Google'),
            ),
          ],
        ),
      ),
    );
  }
}
