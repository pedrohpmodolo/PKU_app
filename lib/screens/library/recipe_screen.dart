// lib/screens/library/recipe_screen.dart

import 'package:flutter/material.dart';
import 'package:pkuapp/services/recipe_service.dart';

class RecipeScreen extends StatefulWidget {
  final String foodName;
  const RecipeScreen({super.key, required this.foodName});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  final RecipeService _recipeService = RecipeService();
  // The future now holds a List of recipes, not a String
  late Future<List<dynamic>> _recipeFuture;

  @override
  void initState() {
    super.initState();
    // Call the new 'getRecipes' method with the named 'query' parameter
    _recipeFuture = _recipeService.getRecipes(query: widget.foodName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Recipes for ${widget.foodName}')),
      // Use a FutureBuilder that expects a List
      body: FutureBuilder<List<dynamic>>(
        future: _recipeFuture,
        builder: (context, snapshot) {
          // While waiting for a response, show a loading indicator
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // If there's an error, show an error message
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          // If we have data, but the list is empty
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No recipes found.'));
          }

          // If we have recipe data, display it in a ListView
          final recipes = snapshot.data!;

          return ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              // Use an ExpansionTile to neatly display each recipe
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ExpansionTile(
                  title: Text(recipe['title'] ?? 'Untitled Recipe', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(recipe['description'] ?? ''),
                  childrenPadding: const EdgeInsets.all(16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PHE: ${recipe['phe_mg_per_serving']}mg | Protein: ${recipe['protein_g_per_serving']}g | Calories: ${recipe['calories_kcal_per_serving']}kcal',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Divider(height: 24),
                    const Text('Ingredients:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    // Display list of ingredients
                    for (var ingredient in (recipe['ingredients'] as List<dynamic>))
                      Text('• $ingredient'),
                    const SizedBox(height: 16),
                    const Text('Instructions:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    // Display list of instructions
                    for (var i = 0; i < (recipe['instructions'] as List<dynamic>).length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text('${i + 1}. ${recipe['instructions'][i]}'),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}