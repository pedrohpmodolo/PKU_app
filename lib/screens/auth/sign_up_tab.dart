import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home/home_screen.dart'; // For navigating to HomeScreen after signup

/// SignUpTab: A form allowing users to register via email/password or Google.
class SignUpTab extends StatefulWidget {
  const SignUpTab({Key? key}) : super(key: key);

  @override
  State<SignUpTab> createState() => _SignUpTabState();
}

class _SignUpTabState extends State<SignUpTab> {
  final _formKey = GlobalKey<FormState>();           // Key for form validation
  final _firstNameController = TextEditingController(); 
  final _middleNameController = TextEditingController(); // Optional
  final _lastNameController = TextEditingController();
  String? _selectedCountry;                           // Stores dropdown selection
  final _countries = const [                          // Alphabetical order country list
  'Afghanistan',
  'Albania',
  'Algeria',
  'Andorra',
  'Angola',
  'Antigua and Barbuda',
  'Argentina',
  'Armenia',
  'Australia',
  'Austria',
  'Azerbaijan',
  'Bahamas',
  'Bahrain',
  'Bangladesh',
  'Barbados',
  'Belarus',
  'Belgium',
  'Belize',
  'Benin',
  'Bhutan',
  'Bolivia',
  'Bosnia and Herzegovina',
  'Botswana',
  'Brazil',
  'Brunei',
  'Bulgaria',
  'Burkina Faso',
  'Burundi',
  'Cabo Verde',
  'Cambodia',
  'Cameroon',
  'Canada',
  'Central African Republic',
  'Chad',
  'Chile',
  'China',
  'Colombia',
  'Comoros',
  'Congo (Democratic Republic of the)',
  'Congo (Republic of the)',
  'Costa Rica',
  'Cote d\'Ivoire',
  'Croatia',
  'Cuba',
  'Cyprus',
  'Czech Republic',
  'Denmark',
  'Djibouti',
  'Dominica',
  'Dominican Republic',
  'Ecuador',
  'Egypt',
  'El Salvador',
  'Equatorial Guinea',
  'Eritrea',
  'Estonia',
  'Eswatini',
  'Ethiopia',
  'Fiji',
  'Finland',
  'France',
  'Gabon',
  'Gambia',
  'Georgia',
  'Germany',
  'Ghana',
  'Greece',
  'Grenada',
  'Guatemala',
  'Guinea',
  'Guinea-Bissau',
  'Guyana',
  'Haiti',
  'Honduras',
  'Hungary',
  'Iceland',
  'India',
  'Indonesia',
  'Iran',
  'Iraq',
  'Ireland',
  'Israel',
  'Italy',
  'Jamaica',
  'Japan',
  'Jordan',
  'Kazakhstan',
  'Kenya',
  'Kiribati',
  'Korea (Democratic People\'s Republic of)',
  'Korea (Republic of)',
  'Kuwait',
  'Kyrgyzstan',
  'Laos',
  'Latvia',
  'Lebanon',
  'Lesotho',
  'Liberia',
  'Libya',
  'Liechtenstein',
  'Lithuania',
  'Luxembourg',
  'Madagascar',
  'Malawi',
  'Malaysia',
  'Maldives',
  'Mali',
  'Malta',
  'Marshall Islands',
  'Mauritania',
  'Mauritius',
  'Mexico',
  'Micronesia',
  'Moldova',
  'Monaco',
  'Mongolia',
  'Montenegro',
  'Morocco',
  'Mozambique',
  'Myanmar',
  'Namibia',
  'Nauru',
  'Nepal',
  'Netherlands',
  'New Zealand',
  'Nicaragua',
  'Niger',
  'Nigeria',
  'North Macedonia',
  'Norway',
  'Oman',
  'Pakistan',
  'Palestine',
  'Panama',
  'Papua New Guinea',
  'Paraguay',
  'Peru',
  'Philippines',
  'Poland',
  'Portugal',
  'Qatar',
  'Romania',
  'Russia',
  'Rwanda',
  'Samoa',
  'San Marino',
  'Sao Tome and Principe',
  'Saudi Arabia',
  'Senegal',
  'Serbia',
  'Seychelles',
  'Sierra Leone',
  'Singapore',
  'Slovakia',
  'Slovenia',
  'Solomon Islands',
  'Somalia',
  'South Africa',
  'South Korea',
  'South Sudan',
  'Spain',
  'Sri Lanka',
  'Sudan',
  'Suriname',
  'Sweden',
  'Switzerland',
  'Syria',
  'Taiwan',
  'Tajikistan',
  'Tanzania',
  'Thailand',
  'Timor-Leste',
  'Togo',
  'Tonga',
  'Trinidad and Tobago',
  'Tunisia',
  'Turkey',
  'Turkmenistan',
  'Tuvalu',
  'Uganda',
  'Ukraine',
  'United Arab Emirates',
  'United Kingdom',
  'United States',
  'Uruguay',
  'Uzbekistan',
  'Vanuatu',
  'Vatican City',
  'Venezuela',
  'Vietnam',
  'Yemen',
  'Zambia',
  'Zimbabwe',
];

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false; // Tracks submission state

  /// Handle email/password signup
  Future<void> _submit() async {
    // Validate form fields
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      // Call Supabase to create a new user
      final res = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'first_name': _firstNameController.text.trim(),
          'middle_name': _middleNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'country': _selectedCountry!,
        },
      );

      // Show success or next steps
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.user != null
                ? 'Confirmation sent to your email!'
                : 'Sign-up initiated.',
          ),
        ),
      );

      // If user object is returned, navigate to HomeScreen
      if (res.user != null) {
        Navigator.of(context)
            .pushReplacementNamed(HomeScreen.routeName);
      }
    } on AuthException catch (e) {
      // Display any errors
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Handle Google OAuth signup
  Future<void> _googleSignUp() async {
    // Start the Google OAuth flow
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
    );
    // After OAuth completes, go to HomeScreen
    Navigator.of(context)
        .pushReplacementNamed(HomeScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24), // Form padding
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The registration form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // First Name
                  TextFormField(
                    controller: _firstNameController,
                    decoration:
                        const InputDecoration(labelText: 'First Name'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter first name' : null,
                  ),
                  const SizedBox(height: 16),
                  // Middle Name (optional)
                  TextFormField(
                    controller: _middleNameController,
                    decoration: const InputDecoration(
                        labelText: 'Middle Name (optional)'),
                  ),
                  const SizedBox(height: 16),
                  // Last Name
                  TextFormField(
                    controller: _lastNameController,
                    decoration:
                        const InputDecoration(labelText: 'Last Name'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter last name' : null,
                  ),
                  const SizedBox(height: 16),
                  // Country Dropdown
                  DropdownButtonFormField<String>(
                    decoration:
                        const InputDecoration(labelText: 'Country'),
                    value: _selectedCountry,
                    items: _countries
                        .map((country) => DropdownMenuItem(
                              value: country,
                              child: Text(country),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedCountry = value),
                    validator: (v) =>
                        (v == null) ? 'Select a country' : null,
                  ),
                  const SizedBox(height: 16),
                  // Email
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter email' : null,
                  ),
                  const SizedBox(height: 16),
                  // Password
                  TextFormField(
                    controller: _passwordController,
                    decoration:
                        const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Min 6 chars' : null,
                  ),
                  const SizedBox(height: 16),
                  // Confirm Password
                  TextFormField(
                    controller: _confirmController,
                    decoration: const InputDecoration(
                        labelText: 'Confirm Password'),
                    obscureText: true,
                    validator: (v) =>
                        v != _passwordController.text ? 'Must match' : null,
                  ),
                  const SizedBox(height: 24),
                  // Sign Up button
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: Text(_loading ? 'Registering…' : 'Sign Up'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Google sign-up
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
