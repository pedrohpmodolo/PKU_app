// lib/services/food_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

// A data model for a food item from your Supabase table
class FoodItem {
  final String name;
  final String? category;
  final double proteinG;
  final double carbsG;
  final double energyKcal;
  // We calculate Phe from protein (1g protein = approx 50mg Phe)
  double get pheMg => proteinG * 50;

  FoodItem({
    required this.name,
    this.category,
    required this.proteinG,
    required this.carbsG,
    required this.energyKcal,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: json['name'] ?? 'Unknown',
      category: json['category'],
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0.0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0.0,
      energyKcal: (json['energy_kcal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}


class FoodService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Searches for foods in the database using the RPC function.
  Future<List<FoodItem>> searchFoods(String searchTerm) async {
    if (searchTerm.isEmpty) {
      return [];
    }
    try {
      final response = await _supabase.rpc(
        'search_foods',
        params: {'search_term': searchTerm},
      );

      final foodList = (response as List)
          .map((item) => FoodItem.fromJson(item as Map<String, dynamic>))
          .toList();
          
      return foodList;
    } catch (e) {
      print('Error searching foods: $e');
      return []; // Return an empty list on error
    }
  }
}