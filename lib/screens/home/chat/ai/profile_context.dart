// profile_context.dart

/// Encapsulates user profile fields in a structured object for prompt generation.
class ProfileContext {
  final String name;
  final String country;
  final DateTime? dob;
  final String? gender;
  final bool usesImperial;
  final double? weightKg;
  final double? heightCm;
  final double? bmr;
  final double? pheToleranceMg;
  final double? proteinGoalG;
  final DateTime? diagnosisDate;
  final String? metabolicCenter;
  final String? dietType;
  final List<String> allergies;
  final List<String> dislikedIngredients;
  final String? activityLevel;
  final double? dailyCalorieTarget;
  final bool pregnancyStatus;
  final bool breastfeeding;
  final String? formulaType;
  final String? pkuSeverity;
  final bool needsVisualAids;
  final String language;
  final bool hasCaregiverAccess;

  ProfileContext({
    required this.name,
    required this.country,
    required this.dob,
    required this.gender,
    required this.usesImperial,
    required this.weightKg,
    required this.heightCm,
    required this.bmr,
    required this.pheToleranceMg,
    required this.proteinGoalG,
    required this.diagnosisDate,
    required this.metabolicCenter,
    required this.dietType,
    required this.allergies,
    required this.dislikedIngredients,
    required this.activityLevel,
    required this.dailyCalorieTarget,
    required this.pregnancyStatus,
    required this.breastfeeding,
    required this.formulaType,
    required this.pkuSeverity,
    required this.needsVisualAids,
    required this.language,
    required this.hasCaregiverAccess,
  });

  /// Factory to create context from raw Supabase profile data.
  factory ProfileContext.fromProfile(Map<String, dynamic> p) {
    return ProfileContext(
      name: p['name'] ?? 'User',
      country: p['country'] ?? 'Unknown',
      dob: p['dob'] != null ? DateTime.tryParse(p['dob']) : null,
      gender: p['gender'],
      usesImperial: p['uses_imperial'] ?? false,
      weightKg: (p['weight_kg'] as num?)?.toDouble(),
      heightCm: (p['height_cm'] as num?)?.toDouble(),
      bmr: (p['bmr'] as num?)?.toDouble(),
      pheToleranceMg: (p['phe_tolerance_mg'] as num?)?.toDouble(),
      proteinGoalG: (p['protein_goal_g'] as num?)?.toDouble(),
      diagnosisDate: p['diagnosis_date'] != null ? DateTime.tryParse(p['diagnosis_date']) : null,
      metabolicCenter: p['metabolic_center'],
      dietType: p['diet_type'],
      allergies: List<String>.from(p['allergies'] ?? []),
      dislikedIngredients: List<String>.from(p['disliked_ingredients'] ?? []),
      activityLevel: p['activity_level'],
      dailyCalorieTarget: (p['daily_calorie_target'] as num?)?.toDouble(),
      pregnancyStatus: p['pregnancy_status'] ?? false,
      breastfeeding: p['breastfeeding'] ?? false,
      formulaType: p['formula_type'],
      pkuSeverity: p['pku_severity'],
      needsVisualAids: p['needs_visual_aids'] ?? false,
      language: p['language'] ?? 'en',
      hasCaregiverAccess: p['has_caregiver_access'] ?? false,
    );
  }

  /// Formats a readable string for the AI prompt.
  String formatForPrompt() {
    final buffer = StringBuffer();
    buffer.writeln("Patient name: $name");
    buffer.writeln("Country: $country");
    if (dob != null) buffer.writeln("Date of Birth: \${dob!.toIso8601String().split('T').first}");
    if (gender != null) buffer.writeln("Gender: $gender");
    buffer.writeln("Uses Imperial Units: $usesImperial");
    if (weightKg != null) buffer.writeln("Weight: ${weightKg} kg");
    if (heightCm != null) buffer.writeln("Height: ${heightCm} cm");
    if (bmr != null) buffer.writeln("BMR: ${bmr!.toStringAsFixed(2)} kcal/day");
    if (pheToleranceMg != null) buffer.writeln("PHE Tolerance: $pheToleranceMg mg/day");
    if (proteinGoalG != null) buffer.writeln("Protein Goal: $proteinGoalG g/day");
    if (diagnosisDate != null) buffer.writeln("Diagnosis Date: \${diagnosisDate!.toIso8601String().split('T').first}");
    if (metabolicCenter != null) buffer.writeln("Metabolic Center: $metabolicCenter");
    if (dietType != null) buffer.writeln("Diet Type: $dietType");
    if (allergies.isNotEmpty) buffer.writeln("Allergies: ${allergies.join(', ')}");
    if (dislikedIngredients.isNotEmpty) buffer.writeln("Dislikes: ${dislikedIngredients.join(', ')}");
    if (activityLevel != null) buffer.writeln("Activity Level: $activityLevel");
    if (dailyCalorieTarget != null) buffer.writeln("Calorie Target: $dailyCalorieTarget kcal/day");
    if (pregnancyStatus) buffer.writeln("Status: Pregnant");
    if (breastfeeding) buffer.writeln("Status: Breastfeeding");
    if (formulaType != null) buffer.writeln("Formula: $formulaType");
    if (pkuSeverity != null) buffer.writeln("PKU Severity: $pkuSeverity");
    if (needsVisualAids) buffer.writeln("Needs Visual Aids: Yes");
    buffer.writeln("Language: $language");
    buffer.writeln("Caregiver Access: $hasCaregiverAccess");
    return buffer.toString();
  }
}
