class UserModel {
  final String id;
  final String name;
  final String bio;
  final String? icon; // ✅ Profile Picture URL
  final String? dob;  // ✅ Date of Birth
  final String? zodiacSign; // ✅ Zodiac Sign (FIXED)
  final String? spiritualPath; // ✅ Spiritual Path
  final String? element; // ✅ Elemental Connection
  final int spiritualXP; // ✅ Spiritual XP
  final int spiritualLevel; // ✅ Spiritual Level (New)
  final List<String>? friends;
  final List<Map<String, dynamic>>? visitorLog;
  final List<Map<String, dynamic>>? giftInventory;
  final bool? isJourneyPublic;

  UserModel({
    required this.id,
    required this.name,
    required this.bio,
    this.icon,
    this.dob,
    this.zodiacSign, // ✅ Added
    this.spiritualPath,
    this.element,
    this.spiritualXP = 0,
    this.spiritualLevel = 1, // ✅ Default to level 1
    this.friends,
    this.visitorLog,
    this.giftInventory,
    this.isJourneyPublic,
  });

  // ✅ Convert JSON Data from Supabase
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      bio: json['bio'] ?? '',
      icon: json['icon'],
      dob: json['dob'],
      zodiacSign: json['zodiac_sign'], // ✅ Ensure it's mapped from Supabase
      spiritualPath: json['spiritual_path'],
      element: json['element'],
      spiritualXP: json['spiritual_xp'] ?? 0,
      spiritualLevel: json['spiritual_level'] ?? 1, // ✅ Ensure we fetch the correct level
      friends: List<String>.from(json['friends'] ?? []),
      visitorLog: List<Map<String, dynamic>>.from(json['visitor_log'] ?? []),
      giftInventory: List<Map<String, dynamic>>.from(json['gift_inventory'] ?? []),
      isJourneyPublic: json['is_journey_public'] ?? true,
    );
  }

  // ✅ Convert UserModel back to JSON for Supabase updates
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'icon': icon,
      'dob': dob,
      'zodiac_sign': zodiacSign, // ✅ Added
      'spiritual_path': spiritualPath,
      'element': element,
      'spiritual_xp': spiritualXP,
      'spiritual_level': spiritualLevel, // ✅ Store Spiritual Level in Supabase
      'friends': friends,
      'visitor_log': visitorLog,
      'gift_inventory': giftInventory,
      'is_journey_public': isJourneyPublic,
    };
  }

  // ✅ CopyWith Method (For Updating State)
  UserModel copyWith({
    String? name,
    String? bio,
    String? icon,
    String? dob,
    String? zodiacSign, // ✅ Added
    String? spiritualPath,
    String? element,
    int? spiritualXP,
    int? spiritualLevel, // ✅ Allow updating Spiritual Level
    List<String>? friends,
    List<Map<String, dynamic>>? visitorLog,
    List<Map<String, dynamic>>? giftInventory,
    bool? isJourneyPublic,
  }) {
    return UserModel(
      id: this.id,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      icon: icon ?? this.icon,
      dob: dob ?? this.dob,
      zodiacSign: zodiacSign ?? this.zodiacSign, // ✅ Ensure copyWith updates it
      spiritualPath: spiritualPath ?? this.spiritualPath,
      element: element ?? this.element,
      spiritualXP: spiritualXP ?? this.spiritualXP,
      spiritualLevel: spiritualLevel ?? this.spiritualLevel, // ✅ Update Spiritual Level
      friends: friends ?? this.friends,
      visitorLog: visitorLog ?? this.visitorLog,
      giftInventory: giftInventory ?? this.giftInventory,
      isJourneyPublic: isJourneyPublic ?? this.isJourneyPublic,
    );
  }
}
