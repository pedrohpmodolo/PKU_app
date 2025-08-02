class AnalyzedMeal {
  final String mealType; // e.g. Breakfast, Snack
  final List<String> ingredients;
  final double pheAmount;
  final List<Map<String, dynamic>>? nutritionSummary; // Optional nutrition details
  final String? recipe; // Optional recipe from LLM

  AnalyzedMeal({
    required this.mealType,
    required this.ingredients,
    required this.pheAmount,
    this.nutritionSummary,
    this.recipe,
  });
}
