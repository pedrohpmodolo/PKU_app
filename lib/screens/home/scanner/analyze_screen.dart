import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'scanner_page.dart';
import 'models/food_model.dart';

class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key});

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Manual search logic
  Future<void> _manualSearch() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      return;
    }

    final rows = await Supabase.instance.client
        .from('foods')
        .select()
        .ilike('name', '%$query%');

    if (rows.isNotEmpty) {
      final food = FoodItem.fromMap(rows.first);
      final double protein = (food.proteingG ?? 0.0) as double;
      final double phe = protein * 50; // Assuming 50mg PHE per gram
      String risk = 'Unknown';
      if (phe < 50) {
        risk = 'Low Risk';
      } else if (phe <= 100) {
        risk = 'Moderate Risk';
      } else {
        risk = 'High Risk';
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(food.name ?? 'Unknown Food',
          style: const TextStyle(fontWeight: FontWeight.w600),),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Category: ${food.category ?? 'Unknown'}'),
              Text('Protein: ${protein.toStringAsFixed(1)} g'),
              Text('Estimated PHE: ${phe.toStringAsFixed(0)} g'),
              Text('Energy: ${food.energyKcal ?? 'Unknown'} kcal'),
              Text('Carbs: ${food.carbsG ?? 'Unknown'} g'),
              const SizedBox(height: 10,),
              Row(
                children: [
                  const Text(
                    'Risk Level: ',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    risk, 
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: risk == 'Low Risk'
                      ? Colors.green
                      : risk == 'Moderate Risk'
                      ? Colors.orange
                      : Colors.red,
                    ),
                  )
                ],
              )
            ],
          ),
          // content: Text(
            // 'Category: ${food.category ?? 'Unknown'}\n'
            // 'Protein: ${protein.toStringAsFixed(1)} g\n'
            // 'Estimated PHE: ${phe.toStringAsFixed(0)} mg\n'
            // 'Energy: ${food.energyKcal ?? 'Unknown'} Kcal\n'
            // 'Carbs: ${food.carbsG ?? 'Unknown'} g\n'
            // 'Risk Level: $risk',
          // ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('No Results Found'),
          content: Text('This food was not found in the database.'),
        ),
      );
      //     }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Analyze Food",
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Search by Food Name:",
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Enter food name",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _manualSearch,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 10),
            const Text(
              "Or Scan a Label:",
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
            ),
            const SizedBox(height: 10),
            const ScannerWidget(), // ⬅️ Scanner logic embedded here
          ],
        ),
      ),
    );
  }
}

