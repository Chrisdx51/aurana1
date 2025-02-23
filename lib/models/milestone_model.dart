class MilestoneModel {
  final String id;
  final String userId;
  final String content;
  final String milestoneType;
  final DateTime createdAt;
  int energyBoosts; // ✅ Allow modification
  final String? mediaUrl; // ✅ Allow images/videos
  final String? username; // ✅ Allow username
  final String? icon; // ✅ Allow profile pictures
  final bool userHasBoosted; // ✅ New field to track if user boosted

  MilestoneModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.milestoneType,
    required this.createdAt,
    this.energyBoosts = 0,
    this.mediaUrl,
    this.username,
    this.icon, // ✅ Store profile picture URL
    this.userHasBoosted = false, // ✅ Default to false
  });


  // ✅ Convert from Supabase JSON
  factory MilestoneModel.fromJson(Map<String, dynamic> json) {
    return MilestoneModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      milestoneType: json['milestone_type'] as String,
      createdAt: DateTime.parse(json['created_at']),
      energyBoosts: json['energy_boosts'] ?? 0,
      mediaUrl: json['media_url'] as String?, // ✅ Prevents null issues
      username: json['profiles']?['name'] as String? ?? "", // ✅ Safe username retrieval
      icon: json['profiles']?['icon'] as String? ?? "", // ✅ Safe profile picture retrieval
      userHasBoosted: json.containsKey('user_boosted') ? json['user_boosted'] as bool : false, // ✅ Ensure it's fetched properly
    );
  }


  // ✅ Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'milestone_type': milestoneType,
      'created_at': createdAt.toIso8601String(),
      'energy_boosts': energyBoosts,
      if (mediaUrl != null) 'media_url': mediaUrl, // ✅ Prevents storing null
      if (username != null) 'username': username, // ✅ Include username
      if (icon != null) 'icon': icon, // ✅ Include profile picture
      'user_boosted': userHasBoosted, // ✅ Store the value
    };
  }
  // ✅ Allow modifications
  MilestoneModel copyWith({
    String? id,
    String? userId,
    String? content,
    String? milestoneType,
    DateTime? createdAt,
    int? energyBoosts,
    String? mediaUrl,
    String? username,
    String? icon,
    bool? userHasBoosted,
  }) {
    return MilestoneModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      milestoneType: milestoneType ?? this.milestoneType,
      createdAt: createdAt ?? this.createdAt,
      energyBoosts: energyBoosts ?? this.energyBoosts,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      username: username ?? this.username,
      icon: icon ?? this.icon,
      userHasBoosted: userHasBoosted ?? this.userHasBoosted,
    );
  }
}