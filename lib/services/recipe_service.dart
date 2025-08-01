// lib/services/recipe_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';

class RecipeService {
  final _logger = Logger('RecipeService');

  /// Generates recipe ideas by calling the 'generate-recipes' Edge Function.
  ///
  /// Takes an optional [query] to specify the type of recipes desired
  /// (e.g., "breakfast ideas", "chicken recipes").
  /// Returns a list of recipe maps.
  Future<List<dynamic>> getRecipes({String? query}) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'generate-recipes',
        body: {'query': query ?? 'any type of meal'},
      );

      // The backend returns a JSON object like {"recipes": [...]}
      // The data is already parsed from JSON into a List by the client.
      return response.data['recipes'] as List<dynamic>;

    } on FunctionException catch (e, stackTrace) {
      _logger.severe('Supabase function error in getRecipes:', e, stackTrace);
      return []; // Return an empty list on error
    } catch (e, stackTrace) {
      _logger.severe('Generic error in getRecipes:', e, stackTrace);
      return []; // Return an empty list on error
    }
  }
}