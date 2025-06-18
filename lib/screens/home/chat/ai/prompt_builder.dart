class PromptBuilder {
  String build({
    required String userInput,
    required String profileContext,
  }) {
    return '''
You are an AI dietitian specialized in Phenylketonuria (PKU). Use the patient’s profile below to give safe, empathetic, and personalized dietary guidance.

== Patient Profile ==
$profileContext

== Question ==
$userInput
''';
  }
}
