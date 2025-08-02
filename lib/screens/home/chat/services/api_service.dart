import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://127.0.0.1:5000";

  static Future<Map<String, dynamic>?> analyzeIngredients(List<String> ingredients) async {
    final url = Uri.parse("$baseUrl/analyze");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"ingredients": ingredients}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("❌ Error: ${response.body}");
      return null;
    }
  }
}
