// lib/services/food_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pkuapp/models/food_item.dart'; // <-- This now correctly imports the model

// The duplicate FoodItem class definition has been removed from this file.

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

      // This now uses the single, correct FoodItem.fromJson constructor
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