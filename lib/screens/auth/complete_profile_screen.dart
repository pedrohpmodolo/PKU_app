import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/utils/profile_utils.dart';

class CompleteProfileScreen extends StatefulWidget {
  static const routeName = '/complete-profile';

  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  // Form controllers and variables
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _pheController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _centerController = TextEditingController();
  final TextEditingController _dietTypeController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _dislikesController = TextEditingController();
  final TextEditingController _calorieController = TextEditingController();
  final TextEditingController _formulaController = TextEditingController();

  String _gender = 'female';
  String _activity = 'moderate';
  String _severity = 'Mild PKU';
  String _language = 'en';

  bool _imperial = false;
  bool _pregnant = false;
  bool _breastfeeding = false;
  bool _visualAids = false;
  bool _caregiverAccess = false;

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Convert units if needed
    final weight = ProfileUtils.convertToKg(_weightController.text, _imperial);
    final height = ProfileUtils.convertToCm(_heightController.text, _imperial);
    final age = ProfileUtils.calculateAge(_diagnosisController.text);
    final bmr = ProfileUtils.calculateBMR(
      gender: _gender,
      weightKg: weight,
      heightCm: height,
      ageYears: age,
    );

    final updates = {
      'id': userId,
      'gender': _gender,
      'weight_kg': weight,
      'height_cm': height,
      'uses_imperial': _imperial,
      'phe_tolerance_mg': double.tryParse(_pheController.text),
      'protein_goal_g': double.tryParse(_proteinController.text),
      'diagnosis_date': _diagnosisController.text,
      'metabolic_center': _centerController.text,
      'diet_type': _dietTypeController.text,
      'allergies': _allergiesController.text.split(',').map((e) => e.trim()).toList(),
      'disliked_ingredients': _dislikesController.text.split(',').map((e) => e.trim()).toList(),
      'activity_level': _activity,
      'daily_calorie_target': double.tryParse(_calorieController.text),
      'pregnancy_status': _pregnant,
      'breastfeeding': _breastfeeding,
      'formula_type': _formulaController.text,
      'pku_severity': _severity,
      'needs_visual_aids': _visualAids,
      'language': _language,
      'has_caregiver_access': _caregiverAccess,
      'bmr': bmr,
    };

    await _supabase.from('profiles').update(updates).eq('id', userId);
    if (mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField(
                value: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: ['male', 'female', 'other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (value) => setState(() => _gender = value!),
              ),
              TextFormField(controller: _weightController, decoration: const InputDecoration(labelText: 'Weight')),
              TextFormField(controller: _heightController, decoration: const InputDecoration(labelText: 'Height')),
              SwitchListTile(title: const Text('Use Imperial Units'), value: _imperial, onChanged: (val) => setState(() => _imperial = val)),
              TextFormField(controller: _pheController, decoration: const InputDecoration(labelText: 'Daily PHE Tolerance (mg)')),
              TextFormField(controller: _proteinController, decoration: const InputDecoration(labelText: 'Daily Protein Goal (g)')),
              TextFormField(controller: _diagnosisController, decoration: const InputDecoration(labelText: 'Diagnosis Date (YYYY-MM-DD)')),
              TextFormField(controller: _centerController, decoration: const InputDecoration(labelText: 'Metabolic Center')),
              TextFormField(controller: _dietTypeController, decoration: const InputDecoration(labelText: 'Diet Type')),
              TextFormField(controller: _allergiesController, decoration: const InputDecoration(labelText: 'Allergies (comma-separated)')),
              TextFormField(controller: _dislikesController, decoration: const InputDecoration(labelText: 'Disliked Ingredients (comma-separated)')),
              DropdownButtonFormField(
                value: _activity,
                decoration: const InputDecoration(labelText: 'Activity Level'),
                items: ['sedentary', 'moderate', 'active']
                    .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                    .toList(),
                onChanged: (value) => setState(() => _activity = value!),
              ),
              TextFormField(controller: _calorieController, decoration: const InputDecoration(labelText: 'Daily Calorie Target')),
              SwitchListTile(title: const Text('Pregnant'), value: _pregnant, onChanged: (val) => setState(() => _pregnant = val)),
              SwitchListTile(title: const Text('Breastfeeding'), value: _breastfeeding, onChanged: (val) => setState(() => _breastfeeding = val)),
              TextFormField(controller: _formulaController, decoration: const InputDecoration(labelText: 'Formula Used (e.g., Phenex-1)')),
              DropdownButtonFormField(
                value: _severity,
                decoration: const InputDecoration(labelText: 'PKU Severity'),
                items: ['Hyperphenylalaninemia', 'Mild PKU', 'Moderate', 'Classic PKU']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) => setState(() => _severity = value!),
              ),
              SwitchListTile(title: const Text('Needs Visual Aids'), value: _visualAids, onChanged: (val) => setState(() => _visualAids = val)),
              TextFormField(initialValue: _language, decoration: const InputDecoration(labelText: 'Language Preference'), onChanged: (val) => _language = val),
              SwitchListTile(title: const Text('Caregiver Access'), value: _caregiverAccess, onChanged: (val) => setState(() => _caregiverAccess = val)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _submitProfile, child: const Text('Save and Continue')),
            ],
          ),
        ),
      ),
    );
  }
}
