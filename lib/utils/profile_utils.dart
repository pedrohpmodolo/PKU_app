class ProfileUtils {
  /// Converts pounds to kilograms if using imperial units
  static double? convertToKg(String weight, bool usesImperial) {
    final w = double.tryParse(weight);
    return (w != null && usesImperial) ? w * 0.453592 : w;
  }

  /// Converts inches to centimeters if using imperial units
  static double? convertToCm(String height, bool usesImperial) {
    final h = double.tryParse(height);
    return (h != null && usesImperial) ? h * 2.54 : h;
  }

  /// Calculates age from a date string (YYYY-MM-DD)
  static int? calculateAge(String dateStr) {
    try {
      final birthDate = DateTime.parse(dateStr);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return null;
    }
  }

  /// Calculates BMR using the Mifflin-St Jeor Equation
  static double? calculateBMR({
    required String gender,
    required double? weightKg,
    required double? heightCm,
    required int? ageYears,
  }) {
    if (weightKg == null || heightCm == null || ageYears == null) return null;

    if (gender == 'male') {
      return 10 * weightKg + 6.25 * heightCm - 5 * ageYears + 5;
    } else {
      return 10 * weightKg + 6.25 * heightCm - 5 * ageYears - 161;
    }
  }
}
