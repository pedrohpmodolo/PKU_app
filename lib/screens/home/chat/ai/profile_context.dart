// profile_context.dart

/// Encapsulates user profile fields in a structured object for prompt generation.
class ProfileContext {
  final String name;
  final String country;
  final DateTime? dob;
  final num? pheLevel;

  ProfileContext({
    required this.name,
    required this.country,
    required this.dob,
    required this.pheLevel,
  });

  /// Factory to create context from raw Supabase profile data.
  factory ProfileContext.fromProfile(Map<String, dynamic> profile) {
    return ProfileContext(
      name: profile['name'] ?? 'User',
      country: profile['country'] ?? 'Unknown',
      dob: profile['dob'] != null ? DateTime.tryParse(profile['dob']) : null,
      pheLevel: profile['phe_level'],
    );
  }

  /// Formats a readable string for the AI prompt.
  String formatForPrompt() {
    final buffer = StringBuffer();
    buffer.writeln("Patient name: $name");
    buffer.writeln("Country: $country");
    if (dob != null) buffer.writeln("Date of Birth: ${dob!.toIso8601String().split('T').first}");
    if (pheLevel != null) buffer.writeln("Phenylalanine tolerance level: ${pheLevel} mg/day");
    return buffer.toString();
  }
}
