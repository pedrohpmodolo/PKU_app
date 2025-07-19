class FoodItem{
  final int id;
  final String name;
  final String category;
  final double proteinG;
  final double carbsG;
  final double energyKcal;

  FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.proteinG,
    required this.carbsG,
    required this.energyKcal,
  });

  factory FoodItem.fromMap(Map<String, dynamic> m) => FoodItem(
      id: m['Id'] is int ? m['Id'] : 0,
      name: m['name'] ?? 'Unknown',
      category: m['category'] ?? 'Unknown',
      proteinG: ((m['protein_g']) ?? 0.0).toDouble(),
      carbsG: (m['carbs_g'] ?? 0.0).toDouble(),
      energyKcal: ((m['energy_Kcal']) ?? 0.0).toDouble(),
    );
  }
