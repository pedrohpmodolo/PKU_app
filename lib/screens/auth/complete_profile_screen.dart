// lib/screens/auth/complete_profile_screen.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/utils/profile_utils.dart';
import '../home/home_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  static const routeName = '/complete-profile';

  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  // --- CONTROLLERS AND VARIABLES ---
  String _userName = 'Loading...'; 
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _pheController = TextEditingController();
  final _proteinController = TextEditingController();
  final _diagnosisDateController = TextEditingController();
  final _centerController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _dislikesController = TextEditingController();
  final _calorieController = TextEditingController();
  final _formulaController = TextEditingController();
  final _languageController = TextEditingController(text: 'en');

  DateTime? _diagnosisDate;
  String _gender = 'Female';
  String _activity = 'Sedentary';
  String? _dietType;
  String _severity = 'Mild PKU';
  
  bool _imperial = false;
  bool _pregnant = false;
  bool _breastfeeding = false;
  bool _visualAids = false;
  bool _caregiverAccess = false;
  bool _isSaving = false;

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
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase.from('profiles').select('name').eq('id', userId).single();
      if (mounted) {
        setState(() {
          _userName = data['name'] ?? 'User';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _userName = 'User');
    }
  }

  void _updateCalorieTarget() {
    if (_weightController.text.isNotEmpty &&
        _heightController.text.isNotEmpty &&
        _diagnosisDate != null) {
      final weight = ProfileUtils.convertToKg(_weightController.text, _imperial);
      final height = ProfileUtils.convertToCm(_heightController.text, _imperial);
      final age = ProfileUtils.calculateAgeFromDate(_diagnosisDate!);
      
      final bmr = ProfileUtils.calculateBMR(
        gender: _gender,
        weightKg: weight,
        heightCm: height,
        ageYears: age,
      );

      _calorieController.text = bmr?.toStringAsFixed(0) ?? '';
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _pheController.dispose();
    _proteinController.dispose();
    _diagnosisDateController.dispose();
    _centerController.dispose();
    _allergiesController.dispose();
    _dislikesController.dispose();
    _calorieController.dispose();
    _formulaController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors in the form.'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isSaving = true);

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isSaving = false);
      return;
    }

    try {
      final weight = ProfileUtils.convertToKg(_weightController.text, _imperial);
      final height = ProfileUtils.convertToCm(_heightController.text, _imperial);
      final age = _diagnosisDate != null ? ProfileUtils.calculateAgeFromDate(_diagnosisDate!) : 0;
      final bmr = ProfileUtils.calculateBMR(
        gender: _gender, weightKg: weight, heightCm: height, ageYears: age);

      final updates = {
        'id': userId,
        'name': _userName,
        'gender': _gender,
        'dob': _diagnosisDate?.toIso8601String(),
        'weight_kg': weight,
        'height_cm': height,
        'uses_imperial': _imperial,
        'phe_tolerance_mg': double.tryParse(_pheController.text),
        'protein_goal_g': double.tryParse(_proteinController.text),
        'diagnosis_date': _diagnosisDate?.toIso8601String(),
        'metabolic_center': _centerController.text,
        'diet_type': _dietType,
        'allergies': _allergiesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'disliked_ingredients': _dislikesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'activity_level': _activity,
        'daily_calorie_target': double.tryParse(_calorieController.text),
        'pregnancy_status': _pregnant,
        'breastfeeding': _breastfeeding,
        'formula_type': _formulaController.text,
        'pku_severity': _severity,
        'needs_visual_aids': _visualAids,
        'language': _languageController.text,
        'has_caregiver_access': _caregiverAccess,
        'bmr': bmr,
      };

      await _supabase.from('profiles').update(updates).eq('id', userId);

      final summaryDataForApi = {
        'name': updates['name'],
        'gender': updates['gender'],
        'dob': updates['dob'],
        'weight_kg': updates['weight_kg'],
        'pku_severity': updates['pku_severity'],
        'phe_tolerance_mg': updates['phe_tolerance_mg'],
        'diet_type': updates['diet_type'],
        'allergies': updates['allergies'],
      };
      
      // --- THIS IS THE CORRECTED LINE ---
      final summaryResponse = await http.post(
        Uri.parse('http://192.168.0.208:8000/generate-profile-summary'), // ADDED THE PORT :8000
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(summaryDataForApi),
      );

      String llmSummary = "Could not generate AI summary at this time.";
      if (summaryResponse.statusCode == 200) {
        final data = jsonDecode(summaryResponse.body);
        llmSummary = data['summary'] ?? llmSummary;
      }

      final pdfData = await ProfileUtils.generateProfilePdf(updates, llmSummary);
      
      final nameParts = _userName.split(' ');
      final lastName = nameParts.length > 1 ? nameParts.last : nameParts.first;
      final firstNameInitial = nameParts.first.isNotEmpty ? nameParts.first[0] : '';
      final dateString = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final fileName = '${lastName}_${firstNameInitial}_${dateString}.pdf';
      final pdfPath = '$userId/$fileName';

      await _supabase.storage.from('user-profiles').uploadBinary(
            pdfPath,
            pdfData,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      if (mounted) Navigator.pushReplacementNamed(context, HomeScreen.routeName);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if(mounted) setState(() => _isSaving = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Complete Your Profile')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Welcome, $_userName!', style: Theme.of(context).textTheme.headlineMedium),
                const Text("Let's finish setting up your profile."),
                const SizedBox(height: 24),

                Text('Basic Information', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: ['Female', 'Male', 'Other']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (value) => setState(() {
                    _gender = value!;
                    _updateCalorieTarget();
                  }),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _diagnosisDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Diagnosis Date',
                    hintText: 'Tap to select a date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _diagnosisDate ?? DateTime.now(),
                      firstDate: DateTime(1920),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _diagnosisDate = pickedDate;
                        _diagnosisDateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                        _updateCalorieTarget();
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),

                Text('Measurements', style: Theme.of(context).textTheme.titleLarge),
                SwitchListTile(
                  title: const Text('Use Imperial Units (lbs, ft)'),
                  value: _imperial,
                  onChanged: (val) => setState(() => _imperial = val),
                  secondary: const Icon(Icons.swap_horiz),
                ),
                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Weight',
                    suffixText: _imperial ? 'lbs' : 'kg',
                  ),
                  onChanged: (_) => _updateCalorieTarget(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _heightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Height',
                    suffixText: _imperial ? 'ft, in' : 'cm',
                  ),
                   onChanged: (_) => _updateCalorieTarget(),
                ),
                const SizedBox(height: 24),
                
                Text('PKU Details', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  "To get the most personalized advice, we recommend filling out the details below.",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _pheController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Daily PHE Tolerance (mg)')
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _proteinController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Daily Protein Goal (g)')
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _centerController,
                  decoration: const InputDecoration(labelText: 'Primary Hospital / Metabolic Clinic')
                ),
                const SizedBox(height: 16),
                 DropdownButtonFormField<String>(
                  value: _dietType,
                  decoration: const InputDecoration(labelText: 'Diet Type'),
                  isExpanded: true, 
                  items: _dietTypes
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _dietType = value!),
                  validator: (value) => value == null ? 'Please select a diet type' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _allergiesController,
                  decoration: const InputDecoration(labelText: 'Allergies (comma-separated)')
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _dislikesController,
                  decoration: const InputDecoration(labelText: 'Disliked Ingredients (comma-separated)')
                ),
                 const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _activity,
                  decoration: const InputDecoration(labelText: 'Activity Level'),
                  items: ['Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active']
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (value) => setState(() {
                    _activity = value!;
                    _updateCalorieTarget();
                  }),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _calorieController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Daily Calorie Target (auto-calculated)',
                  ),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Manual Override'),
                        content: const Text(
                          'This value is auto-calculated based on your profile. Manually changing it may affect accuracy. Do you still want to proceed?'
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Proceed')),
                        ],
                      ),
                    );
                    if (confirm == false) {
                      FocusScope.of(context).unfocus();
                    }
                  },
                ),
                const SizedBox(height: 16),

                SwitchListTile(
                  title: const Text('Currently Pregnant'),
                  value: _pregnant,
                  onChanged: (val) => setState(() => _pregnant = val),
                  secondary: const Icon(Icons.pregnant_woman),
                ),
                SwitchListTile(
                  title: const Text('Currently Breastfeeding'),
                  value: _breastfeeding,
                  onChanged: (val) => setState(() => _breastfeeding = val),
                  secondary: const Icon(Icons.baby_changing_station),
                ),
                 const SizedBox(height: 16),
                 
                TextFormField(
                  controller: _formulaController,
                  decoration: const InputDecoration(labelText: 'Formula Used (e.g., Phenex-1)')
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _severity,
                  decoration: const InputDecoration(labelText: 'PKU Severity'),
                  items: ['Hyperphenylalaninemia', 'Mild PKU', 'Moderate PKU', 'Classic PKU']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) => setState(() => _severity = value!),
                ),
                const SizedBox(height: 16),
                
                SwitchListTile(
                  title: const Text('Needs Visual Aids'),
                  value: _visualAids,
                  onChanged: (val) => setState(() => _visualAids = val)
                ),
                SwitchListTile(
                  title: const Text('Enable Caregiver Access'),
                  value: _caregiverAccess,
                  onChanged: (val) => setState(() => _caregiverAccess = val)
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSaving ? null : _submitProfile,
                  child: Text(_isSaving ? 'Saving...' : 'Save and Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}