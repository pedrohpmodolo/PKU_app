// lib/services/recipe_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class RecipeService {
  final String _apiUrl = Platform.isAndroid 
      ? 'http://10.0.2.2:8000/generate-recipes' 
      : 'http://192.168.1.185:8000/generate-recipes'; // <-- REMEMBER TO USE YOUR IP

  Future<String> getRecipesForFood(String foodName) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'food_name': foodName,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['recipes'] ?? 'Could not generate recipes.';
      } else {
        return 'Error from server: ${response.statusCode}';
      }
    } catch (e) {
      return 'Error connecting to the server: $e';
    }
  }
}