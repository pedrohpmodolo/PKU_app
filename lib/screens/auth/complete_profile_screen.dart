// lib/screens/auth/complete_profile_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pkuapp/utils/profile_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home/home_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  static const routeName = '/complete-profile';
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  // --- CONTROLLERS AND VARIABLES ---
  String _userName = 'Loading...';
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _inchesController = TextEditingController();
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
  bool _caregiverAccess = false; // This was missing from the form, added to Step 3
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

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _inchesController.dispose();
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

  // --- LOGIC METHODS ---
  void _updateCalorieTarget() {
    if (_weightController.text.isNotEmpty &&
        (_heightController.text.isNotEmpty || _inchesController.text.isNotEmpty) &&
        _diagnosisDate != null) {
      final weight = ProfileUtils.convertToKg(_weightController.text, _imperial);
      final height = ProfileUtils.convertToCm(
        _heightController.text,
        _imperial,
        inches: _inchesController.text,
      );
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

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors before saving.'), backgroundColor: Colors.red),
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
      final height = ProfileUtils.convertToCm(
        _heightController.text,
        _imperial,
        inches: _inchesController.text,
      );
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

      final summaryResponse = await Supabase.instance.client.functions.invoke('generate-profile-summary');
      final llmSummary = summaryResponse.data['summary'] ?? "Could not generate AI summary at this time.";

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
        body: Form(
          key: _formKey,
          child: Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < 2) {
                setState(() => _currentStep += 1);
              } else {
                _submitProfile();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep -= 1);
              }
            },
            onStepTapped: (step) => setState(() => _currentStep = step),
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: _isSaving ? null : details.onStepContinue,
                      child: Text(_isSaving ? 'Saving...' : (_currentStep == 2 ? 'Save Profile' : 'Continue')),
                    ),
                    const SizedBox(width: 12),
                    if (_currentStep > 0 && !_isSaving)
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Back'),
                      ),
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('Basic Info'),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                content: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: ['Female', 'Male', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (value) => setState(() { _gender = value!; _updateCalorieTarget(); }),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _diagnosisDateController,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Diagnosis Date', hintText: 'Used to calculate age', suffixIcon: Icon(Icons.calendar_today)),
                      onTap: () async {
                        final pickedDate = await showDatePicker(context: context, initialDate: _diagnosisDate ?? DateTime.now(), firstDate: DateTime(1920), lastDate: DateTime.now());
                        if (pickedDate != null) {
                          setState(() {
                            _diagnosisDate = pickedDate;
                            _diagnosisDateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                            _updateCalorieTarget();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Use Imperial Units (lbs, ft)'),
                      value: _imperial,
                      onChanged: (val) => setState(() => _imperial = val),
                      secondary: const Icon(Icons.swap_horiz),
                    ),
                    TextFormField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: 'Weight', suffixText: _imperial ? 'lbs' : 'kg'),
                      onChanged: (_) => _updateCalorieTarget(),
                    ),
                    const SizedBox(height: 16),
                    if (_imperial)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _heightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Height (ft)'),
                              onChanged: (_) => _updateCalorieTarget(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _inchesController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Height (in)'),
                              onChanged: (_) => _updateCalorieTarget(),
                            ),
                          ),
                        ],
                      )
                    else
                      TextFormField(
                        controller: _heightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Height', suffixText: 'cm'),
                        onChanged: (_) => _updateCalorieTarget(),
                      ),
                  ],
                ),
              ),
              Step(
                title: const Text('PKU Details'),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                content: Column(
                  // --- THIS SECTION IS NOW FILLED IN ---
                  children: [
                    TextFormField(
                      controller: _pheController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Daily PHE Tolerance (mg)'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _proteinController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Daily Protein Goal (g)'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _dietType,
                      decoration: const InputDecoration(labelText: 'Diet Type'),
                      isExpanded: true,
                      items: _dietTypes.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (value) => setState(() => _dietType = value!),
                      validator: (value) => value == null ? 'Please select a diet type' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _severity,
                      decoration: const InputDecoration(labelText: 'PKU Severity'),
                      items: ['Hyperphenylalaninemia', 'Mild PKU', 'Moderate PKU', 'Classic PKU'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (value) => setState(() => _severity = value!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _formulaController,
                      decoration: const InputDecoration(labelText: 'Formula Used (e.g., Phenex-1)'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _centerController,
                      decoration: const InputDecoration(labelText: 'Primary Hospital / Metabolic Clinic'),
                    ),
                  ],
                ),
              ),
              Step(
                title: const Text('Preferences'),
                isActive: _currentStep >= 2,
                content: Column(
                  children: [
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
                    DropdownButtonFormField<String>(
                      value: _activity,
                      decoration: const InputDecoration(labelText: 'Activity Level'),
                      items: ['Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active'].map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                      onChanged: (value) => setState(() { _activity = value!; _updateCalorieTarget(); }),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _calorieController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Daily Calorie Goal (kcal)',
                        hintText: 'Auto-calculated or override',
                      ),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Manual Override'),
                            content: const Text('This value is auto-calculated. Do you want to enter your own target?'),
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
                    ),
                    SwitchListTile(
                      title: const Text('Currently Breastfeeding'),
                      value: _breastfeeding,
                      onChanged: (val) => setState(() => _breastfeeding = val),
                    ),
                    SwitchListTile(
                      title: const Text('Enable Visual Aids'),
                      value: _visualAids,
                      onChanged: (val) => setState(() => _visualAids = val),
                    ),
                    SwitchListTile(
                      title: const Text('Enable Caregiver Access'),
                      value: _caregiverAccess,
                      onChanged: (val) => setState(() => _caregiverAccess = val),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}