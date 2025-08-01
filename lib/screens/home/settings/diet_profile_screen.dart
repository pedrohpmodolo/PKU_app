// lib/screens/home/settings/diet_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // Controllers for editable fields
  final _pheController = TextEditingController();
  final _proteinController = TextEditingController();
  final _calorieController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _dislikesController = TextEditingController();

  String? _dietType;
  String _activity = 'Sedentary';
  bool _pregnant = false;
  bool _breastfeeding = false;

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
    _pheController.dispose();
    _proteinController.dispose();
    _calorieController.dispose();
    _allergiesController.dispose();
    _dislikesController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase.from('profiles').select().eq('id', userId).single();

      if (mounted) {
        setState(() {
          _pheController.text = data['phe_tolerance_mg']?.toString() ?? '';
          _proteinController.text = data['protein_goal_g']?.toString() ?? '';
          _calorieController.text = data['daily_calorie_target']?.toString() ?? '';
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
      final updates = {
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
        Navigator.of(context).pop(); // Go back after saving
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
        title: const Text('Edit Diet & Goals'),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveProfile,
            icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator()) : const Icon(Icons.save),
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
                    Text('Your Goals', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
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
                    TextFormField(
                      controller: _calorieController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Daily Calorie Goal (kcal)'),
                    ),
                    const Divider(height: 48),
                    Text('Your Diet', style: Theme.of(context).textTheme.titleLarge),
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
                      value: _activity,
                      decoration: const InputDecoration(labelText: 'Activity Level'),
                      items: ['Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active'].map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                      onChanged: (value) => setState(() => _activity = value!),
                    ),
                    const Divider(height: 48),
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