// prompt_builder.dart

import 'profile_context.dart';

/// Responsible for constructing a prompt that blends the user input with their context.
class PromptBuilder {
  /// Constructs a personalized prompt given user input and profile data.
  String build({required String userInput, required ProfileContext profileContext}) {
    return '''
You are a specialized AI dietitian for Phenylketonuria (PKU) management.
The following is background information about your patient:

${profileContext.formatForPrompt()}

Using the patient's data and PKU dietary guidelines, respond helpfully to their question.

User Question: "$userInput"
''';
  }
}
