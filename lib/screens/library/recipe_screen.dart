// lib/screens/library/recipe_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:pkuapp/services/recipe_service.dart'; // We'll create this service next

class RecipeScreen extends StatefulWidget {
  final String foodName;
  const RecipeScreen({super.key, required this.foodName});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  final RecipeService _recipeService = RecipeService();
  late Future<String> _recipeFuture;

  @override
  void initState() {
    super.initState();
    // Start fetching the recipes as soon as the screen loads
    _recipeFuture = _recipeService.getRecipesForFood(widget.foodName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Recipes for ${widget.foodName}')),
      body: FutureBuilder<String>(
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
          // If we have data, display it using the Markdown widget
          if (snapshot.hasData) {
            return Markdown(
              data: snapshot.data!,
              padding: const EdgeInsets.all(16.0),
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                h2: Theme.of(context).textTheme.headlineSmall,
              ),
            );
          }
          // Default case
          return const Center(child: Text('No recipes found.'));
        },
      ),
    );
  }
}