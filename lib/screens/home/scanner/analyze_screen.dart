import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'scanner_page.dart';
import 'models/food_model.dart';

class AnalyzeScreen extends StatefulWidget {
  final FoodItem? food;
  const AnalyzeScreen({super.key, this.food});

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  final TextEditingController _controller = TextEditingController();
  //final ImagePicker _picker = ImagePicker();
  final TextEditingController _feedbackController = TextEditingController();

  void _submitFeedback() async {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback before submitting.')),
      );
      return;
    }

    try{
      await Supabase.instance.client
          .from('feedback')
          .insert({'message': text, 'created_at': DateTime.now().toIso8601String()});

      _feedbackController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting feedback: $e')),
      );
    }
  }

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
      final List<FoodItem> matches = rows.map(FoodItem.fromMap).toList();


      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Select a food item'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: matches.length,
              separatorBuilder: (context, index) => const Divider(thickness: 1),
              itemBuilder: (context, index) {
                final food = matches[index];
                return ListTile(
                  title: Text(food.name ?? 'Unknown Food'),
                  subtitle: Text(food.category ?? 'Unknown Category'),
                  onTap: () {
                    Navigator.pop(context); // Close the dialog
                    _showFoodDetails(food);
                  },
                );
              }
           ),
          ),
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

  void _showFoodDetails(FoodItem food) {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(food.name ?? 'Unknown Food'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Category: ${food.category ?? 'Unknown'}'),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter amount (g)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                final double? grams = double.tryParse(amountController.text);
                if (grams != null && grams > 0) {
                  Navigator.of(context).pop();
                  _showPortionAdjustedDetails(food, grams);
              }
              },
              child: const Text('Calculate Nutrients'),
            )
          ],
        ),
    ),
    );
  }

  void _showPortionAdjustedDetails(FoodItem food, double grams) {
    final multiplier = grams / 100.0;

    final double protein = (food.proteinG ?? 0.0) * multiplier;
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
        title: Text('${food.name ?? 'Unknown Food'} - ${grams.toStringAsFixed(0)} g'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${food.category ?? 'Unknown'}'),
            Text('Protein: ${protein.toStringAsFixed(1)} g'),
            Text('Estimated PHE: ${phe.toStringAsFixed(0)} mg'),
            const SizedBox(height: 10),
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
            ),
          ],
        ),
        )
    );
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
            const Divider(),
            const SizedBox(height: 10),
            
            const Text(
              "Or Scan a Label:",
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
            ),
            const SizedBox(height: 10),
            
            const ScannerWidget(),
            const Divider(),
            const Text(
              'Something wrong? Send feedback:',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _feedbackController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter your feedback here...',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _submitFeedback,
              ),
              ),
                
            ),
          ],
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import 'scanner_page.dart';
// import 'models/food_model.dart';

// class AnalyzeScreen extends StatefulWidget {
//   final FoodItem? food;
//   const AnalyzeScreen({super.key, this.food});

//   @override
//   State<AnalyzeScreen> createState() => _AnalyzeScreenState();
// }

// class _AnalyzeScreenState extends State<AnalyzeScreen> {
//   final TextEditingController _controller = TextEditingController();
//   //final ImagePicker _picker = ImagePicker();
//   final TextEditingController _feedbackController = TextEditingController();

//   void _submitFeedback() async {
//     final text = _feedbackController.text.trim();
//     if (text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please enter your feedback before submitting.')),
//       );
//       return;
//     }

//     try{
//       await Supabase.instance.client
//           .from('feedback')
//           .insert({'message': text, 'created_at': DateTime.now().toIso8601String()});

//       _feedbackController.clear();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Feedback submitted successfully!')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error submitting feedback: $e')),
//       );
//     }
//   }

//   // Manual search logic
//   Future<void> _manualSearch() async {
//     final query = _controller.text.trim();
//     if (query.isEmpty) {
//       return;
//     }

//     final rows = await Supabase.instance.client
//         .from('foods')
//         .select()
//         .ilike('name', '%$query%');

//     if (rows.isNotEmpty) {
//       final food = FoodItem.fromMap(rows.first);
//       final double protein = (food.proteinG ?? 0.0) as double;
//       final double phe = protein * 50; // Assuming 50mg PHE per gram
//       String risk = 'Unknown';
//       if (phe < 50) {
//         risk = 'Low Risk';
//       } else if (phe <= 100) {
//         risk = 'Moderate Risk';
//       } else {
//         risk = 'High Risk';
//       }

//       showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           title: Text(
//             food.name ?? 'Unknown Food',
//             style: const TextStyle(fontWeight: FontWeight.w600),
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text('Category: ${food.category ?? 'Unknown'}'),
//               Text('Protein: ${protein.toStringAsFixed(1)} g'),
//               Text('Estimated PHE: ${phe.toStringAsFixed(0)} g'),
//               Text('Energy: ${food.energyKcal ?? 'Unknown'} kcal'),
//               Text('Carbs: ${food.carbsG ?? 'Unknown'} g'),
//               const SizedBox(height: 10),
//               Row(
//                 children: [
//                   const Text(
//                     'Risk Level: ',
//                     style: TextStyle(fontWeight: FontWeight.w500),
//                   ),
//                   Text(
//                     risk,
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: risk == 'Low Risk'
//                           ? Colors.green
//                           : risk == 'Moderate Risk'
//                           ? Colors.orange
//                           : Colors.red,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       );
//     } else {
//       showDialog(
//         context: context,
//         builder: (_) => const AlertDialog(
//           title: Text('No Results Found'),
//           content: Text('This food was not found in the database.'),
//         ),
//       );
//       //     }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           "Analyze Food",
//           style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               "Search by Food Name:",
//               style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
//             ),
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     decoration: const InputDecoration(
//                       hintText: "Enter food name",
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.search),
//                   onPressed: _manualSearch,
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             const Divider(),
//             const SizedBox(height: 10),
            
//             const Text(
//               "Or Scan a Label:",
//               style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
//             ),
//             const SizedBox(height: 10),
            
//             const ScannerWidget(),
//             const Divider(),
//             const Text(
//               'Something wrong? Send feedback:',
//               style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
//             ),
//             const SizedBox(height: 10),
//             TextField(
//               controller: _feedbackController,
//               maxLines: 3,
//               decoration: InputDecoration(
//                 hintText: 'Enter your feedback here...',
//                 border: OutlineInputBorder(),
//                 suffixIcon: IconButton(
//                   icon: const Icon(Icons.send),
//                   onPressed: _submitFeedback,
//               ),
//               ),
                
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
