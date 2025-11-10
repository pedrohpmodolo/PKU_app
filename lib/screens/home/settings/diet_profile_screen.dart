// lib/screens/home/settings/diet_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DietProfileScreen extends StatefulWidget {
  const DietProfileScreen({super.key});

  @override
  State<DietProfileScreen> createState() => _DietProfileScreenState();
}

class _DietProfileScreenState extends State<DietProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isSaving = false;

  // --- CONTROLLERS ---
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  DateTime? _selectedDob;

  final _pheController = TextEditingController();
  final _proteinController = TextEditingController();
  final _calorieController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _dislikesController = TextEditingController();

  // --- STATE VARIABLES ---
  String? _gender;
  String? _pkuSeverity;
  String? _dietType;
  String _activity = 'Sedentary';
  bool _pregnant = false;
  bool _breastfeeding = false;

  // Dropdown Options
  final List<String> _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];
  final List<String> _severities = [
    'Classic PKU',
    'Moderate PKU',
    'Mild PKU',
    'Hyperphenylalaninemia (HPA)'
  ];
  final List<String> _dietTypes = [
    'Infant: Breast milk + PKU Formula',
    'Infant: Standard Formula + PKU Formula',
    'Low-Protein Diet (Childhood)',
    'Diet for Life (Adolescent/Adult)',
    'Maternal Diet (Pre-conception & Pregnancy)',
    'Liberalized Diet (BH4-Responsive)',
    'Returning to Diet',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _pheController.dispose();
    _proteinController.dispose();
    _calorieController.dispose();
    _allergiesController.dispose();
    _dislikesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _loadProfileData() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase.from('profiles').select().eq('id', userId).single();

      if (mounted) {
        setState(() {
          // Personal Info
          final fullName = (data['name'] as String? ?? '').trim();
          final nameParts = fullName.split(' ');
          if (nameParts.isNotEmpty) {
            _firstNameController.text = nameParts.first;
            if (nameParts.length > 1) {
              _lastNameController.text = nameParts.sublist(1).join(' ');
            }
          }

          if (data['dob'] != null) {
            _selectedDob = DateTime.parse(data['dob']);
            _dobController.text = DateFormat('yyyy-MM-dd').format(_selectedDob!);
          }
          _heightController.text = data['height_cm']?.toString() ?? '';
          _weightController.text = data['weight_kg']?.toString() ?? '';
          _gender = data['gender'];
          _pkuSeverity = data['pku_severity'];

          // Dietary Goals
          _pheController.text = data['phe_tolerance_mg']?.toString() ?? '';
          _proteinController.text = data['protein_goal_g']?.toString() ?? '';
          _calorieController.text = data['daily_calorie_target']?.toString() ?? '';
          
          // Preferences
          _allergiesController.text = (data['allergies'] as List<dynamic>?)?.join(', ') ?? '';
          _dislikesController.text = (data['disliked_ingredients'] as List<dynamic>?)?.join(', ') ?? '';
          _dietType = data['diet_type'];
          _activity = data['activity_level'] ?? 'Sedentary';
          _pregnant = data['pregnancy_status'] ?? false;
          _breastfeeding = data['breastfeeding'] ?? false;
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);

    try {
      final userId = _supabase.auth.currentUser!.id;
      final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();

      final updates = {
        'name': fullName,
        'dob': _dobController.text.isNotEmpty ? _dobController.text : null,
        'height_cm': double.tryParse(_heightController.text),
        'weight_kg': double.tryParse(_weightController.text),
        'gender': _gender,
        'pku_severity': _pkuSeverity,
        'phe_tolerance_mg': double.tryParse(_pheController.text),
        'protein_goal_g': double.tryParse(_proteinController.text),
        'daily_calorie_target': double.tryParse(_calorieController.text),
        'diet_type': _dietType,
        'activity_level': _activity,
        'allergies': _allergiesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'disliked_ingredients': _dislikesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'pregnancy_status': _pregnant,
        'breastfeeding': _breastfeeding,
      };

      await _supabase.from('profiles').update(updates).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveProfile,
            icon: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
                : const Icon(Icons.save),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Personal Information', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    // --- ROW 1: NAMES ---
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(labelText: 'First Name'),
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(labelText: 'Last Name'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // --- ROW 2: DOB ---
                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () => _selectDate(context),
                    ),
                    const SizedBox(height: 16),

                    // --- ROW 3: HEIGHT & WEIGHT ---
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _heightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Height (cm)'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Weight (kg)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- ROW 4: GENDER (Full width to be safe) ---
                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (val) => setState(() => _gender = val),
                    ),
                    const SizedBox(height: 16),

                    // --- ROW 5: SEVERITY (Full width required for long text) ---
                    DropdownButtonFormField<String>(
                      value: _pkuSeverity,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'PKU Severity'),
                      items: _severities.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) => setState(() => _pkuSeverity = val),
                    ),

                    const Divider(height: 48),

                    // --- DIETARY GOALS ---
                    Text('Dietary Goals', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pheController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Daily PHE Tolerance (mg)'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _proteinController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Protein Goal (g)'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _calorieController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Calorie Goal (kcal)'),
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 48),

                    // --- DIET DETAILS ---
                    Text('Diet Details', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _dietType,
                      decoration: const InputDecoration(labelText: 'Diet Type'),
                      isExpanded: true,
                      items: _dietTypes.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (value) => setState(() => _dietType = value!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _activity,
                      decoration: const InputDecoration(labelText: 'Activity Level'),
                      items: ['Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active']
                          .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                          .toList(),
                      onChanged: (value) => setState(() => _activity = value!),
                    ),

                    const Divider(height: 48),

                    // --- PREFERENCES ---
                    Text('Preferences & Status', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _allergiesController,
                      decoration: const InputDecoration(labelText: 'Allergies (comma-separated)'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dislikesController,
                      decoration: const InputDecoration(labelText: 'Disliked Ingredients (comma-separated)'),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Currently Pregnant'),
                      value: _pregnant,
                      onChanged: (val) => setState(() => _pregnant = val),
                    ),
                    SwitchListTile(
                      title: const Text('Currently Breastfeeding'),
                      value: _breastfeeding,
                      onChanged: (val) => setState(() => _breastfeeding = val),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}