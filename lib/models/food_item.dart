// lib/models/food_item.dart

class FoodItem {
  final String fdcId; // Changed to String to support barcodes
  final String name;
  final String? category;
  final double proteinG;
  final double? carbsG;
  final double? energyKcal;
  double get pheMg => proteinG * 50;

  FoodItem({
    required this.fdcId,
    required this.name,
    this.category,
    required this.proteinG,
    this.carbsG,
    this.energyKcal,
  });

  // --- THIS IS THE NEW CONSTRUCTOR THAT WAS MISSING ---
  /// Creates a FoodItem from a JSON map (typically from Supabase).
  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      // The fdc_id might be an int or a string, so we handle both cases.
      fdcId: json['fdc_id'].toString(), 
      name: json['name'] ?? 'Unknown Food',
      category: json['category'],
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0.0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0.0,
      energyKcal: (json['energy_kcal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Creates a FoodItem from the Open Food Facts API response.
  factory FoodItem.fromOpenFoodFacts(String barcode, Map<String, dynamic> productData) {
    final nutriments = productData['nutriments'] ?? {};
    return FoodItem(
      fdcId: barcode, // Use the barcode directly as a String ID
      name: productData['product_name'] ?? 'Unknown Product',
      category: (productData['categories_tags'] as List<dynamic>?)?.firstOrNull as String? ?? 'Branded Food',
      proteinG: (nutriments['proteins_100g'] as num?)?.toDouble() ?? 0.0,
      carbsG: (nutriments['carbohydrates_100g'] as num?)?.toDouble() ?? 0.0,
      energyKcal: (nutriments['energy-kcal_100g'] as num?)?.toDouble() ?? 0.0,
    );
  }
}