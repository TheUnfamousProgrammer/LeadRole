class Persona {
  final String userId;
  final String? displayName;
  final String gender;
  final String? ageRange;
  final String? ethnicity;
  final String? hair;
  final String? style;
  final String? faceKitURL;
  final bool consent;

  const Persona({
    required this.userId,
    required this.gender,
    required this.consent,
    this.displayName,
    this.ageRange,
    this.ethnicity,
    this.hair,
    this.style,
    this.faceKitURL,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'displayName': displayName,
    'gender': gender,
    'ageRange': ageRange,
    'ethnicity': ethnicity,
    'hair': hair,
    'style': style,
    'faceKitURL': faceKitURL,
    'consent': consent,
  };
}
