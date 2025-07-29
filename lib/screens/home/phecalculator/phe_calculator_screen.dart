// lib/screens/phe_calculator_screen.dart

import 'package:flutter/material.dart';
// Make sure to create and import the new screen we designed
import 'package:pkuapp/screens/home/phecalculator/infant_calculator_screen.dart'; 
import 'package:pkuapp/utils/food_service.dart';

class PheCalculatorScreen extends StatefulWidget {
  const PheCalculatorScreen({super.key});

  @override
  State<PheCalculatorScreen> createState() => _PheCalculatorScreenState();
}

class _PheCalculatorScreenState extends State<PheCalculatorScreen> {
  final FoodService _foodService = FoodService();
  final TextEditingController _searchController = TextEditingController();

  List<FoodItem> _searchResults = [];
  List<Map<String, dynamic>> _mealItems = [];
  bool _isLoading = false;

  double _totalPhe = 0;
  double _totalProtein = 0;

  // ... (all your existing functions like _onSearchChanged, _addFoodToMeal, etc. remain here without change) ...

  void _onSearchChanged(String query) async {
    if (query.length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isLoading = true);
    final results = await _foodService.searchFoods(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  void _addFoodToMeal(FoodItem food) {
    _searchController.clear();
    setState(() {
      _searchResults = [];
    });
    
    showDialog(
      context: context,
      builder: (context) {
        final weightController = TextEditingController();
        return AlertDialog(
          title: Text('Add ${food.name}'),
          content: TextField(
            controller: weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Weight in grams (g)'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final weight = double.tryParse(weightController.text);
                if (weight != null && weight > 0) {
                  setState(() {
                    _mealItems.add({'food': food, 'weight': weight});
                    _calculateTotals();
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _calculateTotals() {
    double phe = 0;
    double protein = 0;
    for (var item in _mealItems) {
      FoodItem food = item['food'];
      double weight = item['weight'];
      phe += (food.pheMg / 100.0) * weight;
      protein += (food.proteinG / 100.0) * weight;
    }
    setState(() {
      _totalPhe = phe;
      _totalProtein = protein;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Calculator'),
      ),
      body: Column(
        children: [
          // --- ADD THIS NEW WIDGET HERE ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Center(
              child: TextButton.icon(
                icon: const Icon(Icons.child_care),
                label: const Text('Open Infant Care Calculator'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const InfantCalculatorScreen(),
                    ),
                  );
                },
              ),
            ),
          ),
          // --- END OF NEW WIDGET ---

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                labelText: 'Search for a food...',
                suffixIcon: _isLoading ? const Padding(padding: EdgeInsets.all(10.0), child: CircularProgressIndicator()) : const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          
          Expanded(
            child: _searchController.text.isNotEmpty && _searchResults.isNotEmpty
                ? _buildSearchResults()
                : _buildMealList(),
          ),

          _buildTotalsFooter(),
        ],
      ),
    );
  }

  // ... (all your existing build methods like _buildSearchResults, _buildMealList, etc. remain here without change) ...
  
  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final food = _searchResults[index];
        return ListTile(
          title: Text(food.name),
          subtitle: Text('${food.proteinG.toStringAsFixed(1)}g Protein / 100g'),
          onTap: () => _addFoodToMeal(food),
        );
      },
    );
  }

  Widget _buildMealList() {
    if (_mealItems.isEmpty) {
      return const Center(child: Text('Add foods to calculate your meal.'));
    }
    return ListView.builder(
      itemCount: _mealItems.length,
      itemBuilder: (context, index) {
        final item = _mealItems[index];
        final FoodItem food = item['food'];
        final double weight = item['weight'];
        final calculatedPhe = (food.pheMg / 100.0) * weight;

        return ListTile(
          title: Text('${food.name} (${weight}g)'),
          subtitle: Text('${calculatedPhe.toStringAsFixed(0)} mg Phe'),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              setState(() {
                _mealItems.removeAt(index);
                _calculateTotals();
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildTotalsFooter() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, -2))
        ]
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const Text('Total Phe', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${_totalPhe.toStringAsFixed(0)} mg', style: const TextStyle(fontSize: 18, color: Colors.redAccent)),
              ],
            ),
            Column(
              children: [
                const Text('Total Protein', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${_totalProtein.toStringAsFixed(1)} g', style: const TextStyle(fontSize: 18)),
              ],
            ),
          ],
        ),
      ),
    );
  }

}