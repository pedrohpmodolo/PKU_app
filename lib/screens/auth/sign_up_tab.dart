import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../home/home_screen.dart';

class SignUpTab extends StatefulWidget {
  const SignUpTab({super.key});

  @override
  State<SignUpTab> createState() => _SignUpTabState();
}

class _SignUpTabState extends State<SignUpTab> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  DateTime? _selectedDOB;
  String? _selectedCountry;
  bool _loading = false;
  bool _waitingForEmailVerification = false;
  Timer? _emailCheckTimer;
  
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

   final Map<String, String> isoCountryMap = {
    'US': 'United States',
    'BR': 'Brazil',
    'GB': 'United Kingdom',
    'AU': 'Australia',
    'CA': 'Canada',
  };

  @override
  void initState() {
    super.initState();
    final localeCountryCode = WidgetsBinding.instance.window.locale.countryCode;
    final mapped = isoCountryMap[localeCountryCode ?? ''] ?? '';
    if (_countries.contains(mapped)) {
      _selectedCountry = mapped;
    }
  }

  @override
  void dispose() {
    _emailCheckTimer?.cancel();
    super.dispose();
  }

  void _startEmailConfirmationPolling() {
    _emailCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final userResponse = await Supabase.instance.client.auth.getUser();
      final user = userResponse.user;
      if (user?.emailConfirmedAt != null) {
        timer.cancel();
        setState(() => _waitingForEmailVerification = false);
        Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
      }
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      final fullName = [
        _firstNameController.text.trim(),
        _middleNameController.text.trim(),
        _lastNameController.text.trim()
      ].where((part) => part.isNotEmpty).join(' ');

      final res = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'name': fullName,
          'dob': _selectedDOB?.toIso8601String(),
          'country': _selectedCountry ?? '',
        },
        emailRedirectTo: 'pkuwise://login-callback',
      );

      if (res.session != null) {
        Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
      } else {
        setState(() => _waitingForEmailVerification = true);
        _startEmailConfirmationPolling();
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _googleSignUp() async {
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'pkuwise://login-callback',
    );

    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata ?? {};

    String fullName = '';
    if (metadata.containsKey('full_name')) {
      fullName = metadata['full_name'];
    } else {
      fullName = [
        metadata['first_name'] ?? '',
        metadata['middle_name'] ?? '',
        metadata['last_name'] ?? ''
      ].where((part) => part.toString().trim().isNotEmpty).join(' ');
    }

    await Supabase.instance.client.from('profiles').upsert({
      'id': user?.id,
      'name': fullName,
      'country': metadata['country'] ?? '',
      'created_at': DateTime.now().toIso8601String(),
    });

    Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
  }

  Widget _emailConfirmationWaitingWidget() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              const Text(
                'We’ve sent a confirmation email to your inbox. Once confirmed, you’ll be automatically redirected.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () async {
                  await Supabase.instance.client.auth.signInWithOtp(
                    email: _emailController.text.trim(),
                    emailRedirectTo: 'pkuwise://login-callback',
                  );
                },
                child: const Text('Resend Email'),
              ),
              TextButton(
                onPressed: () {
                  _emailCheckTimer?.cancel();
                  setState(() => _waitingForEmailVerification = false);
                },
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _waitingForEmailVerification
        ? _emailConfirmationWaitingWidget()
        : Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(labelText: 'First Name'),
                          validator: (v) => (v == null || v.isEmpty) ? 'Enter first name' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _middleNameController,
                          decoration: const InputDecoration(labelText: 'Middle Name (optional)'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(labelText: 'Last Name'),
                          validator: (v) => (v == null || v.isEmpty) ? 'Enter last name' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Country'),
                          value: _selectedCountry,
                          items: _countries.map((country) => DropdownMenuItem(value: country, child: Text(country))).toList(),
                          onChanged: (value) => setState(() => _selectedCountry = value),
                          validator: (v) => (v == null) ? 'Select a country' : null,
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () async {
                            final now = DateTime.now();
                            final firstDate = DateTime(now.year - 120);
                            final lastDate = DateTime(now.year - 1);
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: now.subtract(const Duration(days: 365 * 18)),
                              firstDate: firstDate,
                              lastDate: lastDate,
                            );
                            if (picked != null) {
                              setState(() => _selectedDOB = picked);
                            }
                          },
                          child: AbsorbPointer(
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: 'Date of Birth', hintText: 'Tap to select'),
                              validator: (_) => _selectedDOB == null ? 'Please select your date of birth' : null,
                              controller: TextEditingController(
                                text: _selectedDOB != null
                                    ? "${_selectedDOB!.year}-${_selectedDOB!.month.toString().padLeft(2, '0')}-${_selectedDOB!.day.toString().padLeft(2, '0')}"
                                    : '',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: (v) => (v == null || v.isEmpty) ? 'Enter email' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(labelText: 'Password'),
                          obscureText: true,
                          validator: (v) => (v == null || v.length < 6) ? 'Min 6 chars' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmController,
                          decoration: const InputDecoration(labelText: 'Confirm Password'),
                          obscureText: true,
                          validator: (v) => v != _passwordController.text ? 'Must match' : null,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          child: Text(_loading ? 'Registering…' : 'Sign Up'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _googleSignUp,
                    icon: Image.asset('lib/assets/icons/google_logo.png', height: 24, width: 24),
                    label: const Text('Continue with Google'),
                  ),
                ],
              ),
            ),
          );
  }
}