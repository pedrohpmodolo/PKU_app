import 'package:http/http.dart' as http;
import 'dart:convert';

import 'prompt_builder.dart';
import 'profile_context.dart';

class AIService {
  final PromptBuilder _promptBuilder = PromptBuilder();

  Future<String> getAIResponse(String userInput, Map<String, dynamic> profile) async {
    final profileContext = ProfileContext.fromProfile(profile);
    final prompt = _promptBuilder.build(userInput: userInput, profileContext: profileContext);

    // Send to OpenAI (example for GPT-4, update with your key/endpoint)
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer YOUR_OPENAI_API_KEY',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-4',
        'messages': [
          {'role': 'system', 'content': prompt},
          {'role': 'user', 'content': userInput},
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      print('OpenAI error: ${response.body}');
      return 'Sorry, I couldn’t generate a response.';
    }
  }
}
