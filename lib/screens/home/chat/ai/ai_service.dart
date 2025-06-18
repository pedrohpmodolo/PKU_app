import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'prompt_builder.dart';
import 'profile_context.dart';

class AIService {
  final openAiKey = dotenv.env['OPENAI_API_KEY'];
  final PromptBuilder _promptBuilder = PromptBuilder();

  /// Sends user input + profile context to OpenAI and gets an AI reply.
  Future<String> getAIResponse(String userInput, Map<String, dynamic> profile) async {
    final profileContext = ProfileContext.fromProfile(profile);
    final prompt = _promptBuilder.build(
      userInput: userInput,
      profileContext: profileContext,
    );

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $openAiKey',
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
