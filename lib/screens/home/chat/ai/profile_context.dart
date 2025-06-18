class ProfileContext {
  static String fromProfile(Map<String, dynamic> profile) {
    return '''
Name: ${profile['name']}
Date of Birth: ${profile['dob']}
Country: ${profile['country']}
Phenylalanine Level: ${profile['phe_level'] ?? 'Unknown'}
''';
  }
}
