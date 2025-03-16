class UserModel {
  final String id;
  final String name;
  final String bio;

  final String? avatar;
  final String? dob;
  final String? zodiacSign;
  final String? spiritualPath;
  final String? element;
  final String? privacySetting;

  final String? city;
  final String? country;

  final String? lastSeen;
  final bool? isOnline;
  final String? soulMatchMessage;

  final int spiritualXP;
  final int spiritualLevel;

  final List<String> friends;
  final List<Map<String, dynamic>> visitorLog;
  final List<Map<String, dynamic>> giftInventory;

  final String? journeyVisibility; // ✅ New field for controlling Soul Journey wall visibility

  UserModel({
    required this.id,
    required this.name,
    required this.bio,
    this.avatar,
    this.dob,
    this.zodiacSign,
    this.spiritualPath,
    this.element,
    this.privacySetting = 'public',
    this.city,
    this.country,
    this.lastSeen,
    this.isOnline,
    this.soulMatchMessage,
    this.spiritualXP = 0,
    this.spiritualLevel = 1,
    this.friends = const [],
    this.visitorLog = const [],
    this.giftInventory = const [],
    this.journeyVisibility = 'public', // ✅ Default to public
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      bio: json['bio'] ?? '',
      avatar: json['avatar'],
      dob: json['dob'],
      zodiacSign: json['zodiac_sign'],
      spiritualPath: json['spiritual_path'],
      element: json['element'],
      privacySetting: json['privacy_setting'] ?? 'public',
      city: json['city'],
      country: json['country'],
      lastSeen: json['last_seen'],
      isOnline: json['is_online'] == true,
      soulMatchMessage: json['soul_match_message'],
      spiritualXP: json['spiritual_xp'] ?? 0,
      spiritualLevel: json['spiritual_level'] ?? 1,
      friends: json['friends'] != null
          ? List<String>.from(json['friends'])
          : [],
      visitorLog: json['visitor_log'] != null
          ? List<Map<String, dynamic>>.from(json['visitor_log'])
          : [],
      giftInventory: json['gift_inventory'] != null
          ? List<Map<String, dynamic>>.from(json['gift_inventory'])
          : [],
      journeyVisibility: json['journey_visibility'] ?? 'public', // ✅ This syncs with Supabase!
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'avatar': avatar,
      'dob': dob,
      'zodiac_sign': zodiacSign,
      'spiritual_path': spiritualPath,
      'element': element,
      'privacy_setting': privacySetting,
      'city': city,
      'country': country,
      'last_seen': lastSeen,
      'is_online': isOnline,
      'soul_match_message': soulMatchMessage,
      'spiritual_xp': spiritualXP,
      'spiritual_level': spiritualLevel,
      'friends': friends,
      'visitor_log': visitorLog,
      'gift_inventory': giftInventory,
      'journey_visibility': journeyVisibility, // ✅ This updates Supabase correctly
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? bio,
    String? avatar,
    String? dob,
    String? zodiacSign,
    String? spiritualPath,
    String? element,
    String? privacySetting,
    String? city,
    String? country,
    String? lastSeen,
    bool? isOnline,
    String? soulMatchMessage,
    int? spiritualXP,
    int? spiritualLevel,
    List<String>? friends,
    List<Map<String, dynamic>>? visitorLog,
    List<Map<String, dynamic>>? giftInventory,
    String? journeyVisibility,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      avatar: avatar ?? this.avatar,
      dob: dob ?? this.dob,
      zodiacSign: zodiacSign ?? this.zodiacSign,
      spiritualPath: spiritualPath ?? this.spiritualPath,
      element: element ?? this.element,
      privacySetting: privacySetting ?? this.privacySetting,
      city: city ?? this.city,
      country: country ?? this.country,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      soulMatchMessage: soulMatchMessage ?? this.soulMatchMessage,
      spiritualXP: spiritualXP ?? this.spiritualXP,
      spiritualLevel: spiritualLevel ?? this.spiritualLevel,
      friends: friends ?? this.friends,
      visitorLog: visitorLog ?? this.visitorLog,
      giftInventory: giftInventory ?? this.giftInventory,
      journeyVisibility: journeyVisibility ?? this.journeyVisibility,
    );
  }
}
