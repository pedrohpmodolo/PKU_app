// lib/screens/phecalculator/infant_calculator_screen.dart

import 'package:flutter/material.dart';
import 'package:pkuapp/screens/home/chat/chat_service.dart'; // We can reuse the profile fetching logic from here
import 'dart:math';

class InfantCalculatorScreen extends StatefulWidget {
  const InfantCalculatorScreen({super.key});

  @override
  State<InfantCalculatorScreen> createState() => _InfantCalculatorScreenState();
}

class _InfantCalculatorScreenState extends State<InfantCalculatorScreen> {
  final _chatService = ChatService();
  final _weightController = TextEditingController();
  final _pheLevelController = TextEditingController();
  DateTime? _dob;
  bool _isBreastfeeding = true;
  List<String> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final profile = await _chatService.getUserProfile();
    if (profile != null && mounted) {
      setState(() {
        if (profile['weight_kg'] != null) {
          _weightController.text = profile['weight_kg'].toString();
        }
        if (profile['dob'] != null) {
          _dob = DateTime.tryParse(profile['dob']);
        }
        _isLoading = false;
      });
    } else {
       setState(() => _isLoading = false);
    }
  }

  void _calculate() {
    final results = <String>[];
    final weight = double.tryParse(_weightController.text);
    final pheLevel = double.tryParse(_pheLevelController.text);

    if (weight == null || weight <= 0 || pheLevel == null || _dob == null) {
      setState(() => _results = ["Please ensure all fields are filled correctly."]);
      return;
    }

    // 1. Calculate Age in Months
    final now = DateTime.now();
    int ageMonths = (now.year - _dob!.year) * 12 + (now.month - _dob!.month);
    if (now.day < _dob!.day) {
      ageMonths--;
    }
    results.add("Age: $ageMonths months");

    // 2. Macronutrient and PHE ranges based on Swift logic
    final double e1, e2, p1, p2, phe1, phe2;
    if (ageMonths <= 3) {
      e1 = 145; e2 = 95; p1 = 3.5; p2 = 3; phe1 = 25; phe2 = 70;
    } else {
      e1 = 135; e2 = 80; p1 = 3; p2 = 2.5; phe1 = 35; phe2 = 10;
    }
    final needCalories = weight * ((e1 + e2) / 2.0);
    final needProtein = weight * ((p1 + p2) / 2.0);
    final maxPHE = weight * ((phe1 + phe2) / 2.0);
    results.add("Energy Need: ${needCalories.toStringAsFixed(0)} kcal");
    results.add("Protein Need: ${needProtein.toStringAsFixed(1)} g");
    results.add("Max Daily PHE: ${maxPHE.toStringAsFixed(0)} mg");

    // 3. Wait time calculation
    final int hour;
    if (pheLevel < 4) hour = 0;
    else if (pheLevel < 10) hour = 24;
    else if (pheLevel < 20) hour = 48;
    else if (pheLevel < 40) hour = 72;
    else hour = 96;
    results.add("Recommendation: Wait $hour hours before the next Phe-containing meal.");

    setState(() => _results = results);
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Infant Care Calculator')),
      body: Form(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text("This calculator uses your profile data to provide infant feeding guidance. You can adjust the values for a custom calculation.", 
                 style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),
            
            TextFormField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
            ),
            const SizedBox(height: 16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Date of Birth"),
              subtitle: Text(_dob != null ? "${_dob!.toLocal()}".split(' ')[0] : 'Not Set'),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dob ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _dob = date);
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _pheLevelController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Current Blood PHE Level (mg/dL)'),
            ),
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _calculate,
              child: const Text('Calculate Recommendations'),
            ),
            
            if (_results.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Results", style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 10),
                        ..._results.map((line) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(line, style: const TextStyle(fontSize: 16)),
                        )),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}