import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://127.0.0.1:5000";

  static Future<Map<String, dynamic>?> analyzeIngredientsPreview(List<String> ingredients, {String mealType = "Unspecified"}) async {
    final url = Uri.parse("$baseUrl/analyze-preview");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "ingredients": ingredients,
        "meal_type": mealType,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("❌ Error: ${response.body}");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> analyzeIngredients(List<String> ingredients, {String mealType = "Unspecified"}) async {
    final url = Uri.parse("$baseUrl/analyze");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "ingredients": ingredients,
        "meal_type": mealType,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("❌ Error: ${response.body}");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getDailySummary() async {
    final url = Uri.parse("$baseUrl/daily-summary");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("❌ Error getting daily summary: ${response.body}");
      return null;
    }
  }

  static Future<bool> resetDailyTracking() async {
    final url = Uri.parse("$baseUrl/reset-day");
    final response = await http.post(url);

    if (response.statusCode == 200) {
      print("✅ Daily tracking reset successfully");
      return true;
    } else {
      print("❌ Error resetting daily tracking: ${response.body}");
      return false;
    }
  }
}
