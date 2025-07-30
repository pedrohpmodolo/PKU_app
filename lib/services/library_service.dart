// lib/services/library_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pkuapp/models/food_item.dart';

class LibraryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetches a list of the user's favorite foods.
  Future<List<FoodItem>> getFavoriteFoods() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('user_favorite_foods')
          .select('foods(*)') // This is a Supabase join
          .eq('user_id', userId);

      final foodList = (response as List)
          .map((item) => FoodItem.fromJson(item['foods'] as Map<String, dynamic>))
          .toList();
          
      return foodList;
    } catch (e) {
      print('Error fetching favorite foods: $e');
      return [];
    }
  }

  /// Adds a food to the user's favorites.
  Future<void> addFavorite(FoodItem food) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    await _supabase.from('foods').upsert({
      'fdc_id': food.fdcId,
      'name': food.name,
      'category': food.category,
      'protein_g': food.proteinG,
      'carbs_g': food.carbsG,
      'energy_kcal': food.energyKcal,
    });

    await _supabase.from('user_favorite_foods').upsert({
      'user_id': userId,
      'food_id': food.fdcId,
    });
  }

  /// Removes a food from the user's favorites.
  Future<void> removeFavorite(String foodId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    await _supabase
        .from('user_favorite_foods')
        .delete()
        .match({'user_id': userId, 'food_id': foodId});
  }
}