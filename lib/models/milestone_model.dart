class MilestoneModel {
  final String id;
  final String userId;
  final String content;
  final String milestoneType;
  final DateTime createdAt;
  final String visibility;             // ✅ Visibility of this post (open, friends_only, private)
  final String journeyVisibility;      // ✅ Journey visibility (optional, depending on your table design)

  int energyBoosts;
  String? mediaUrl;
  String? username;
  String? avatar;                      // ✅ Renamed from icon to avatar
  bool userHasBoosted;

  int likeCount;
  int commentCount;
  bool likedByMe;

  MilestoneModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.milestoneType,
    required this.createdAt,
    required this.visibility,
    this.journeyVisibility = 'public',  // ✅ Default to public if not specified
    this.energyBoosts = 0,
    this.mediaUrl,
    this.username,
    this.avatar,                         // ✅ Renamed
    this.userHasBoosted = false,
    this.likeCount = 0,
    this.commentCount = 0,
    this.likedByMe = false,
  });

  /// FROM SUPABASE JSON
  factory MilestoneModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'];

    return MilestoneModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] ?? '',
      milestoneType: json['milestone_type'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      visibility: json['visibility'] ?? 'open',
      journeyVisibility: json['journey_visibility'] ?? 'public', // ✅ Added field support

      energyBoosts: json['energy_boosts'] ?? 0,
      mediaUrl: json['media_url'],

      username: profile != null ? profile['username'] ?? '' : '',
      avatar: profile != null ? profile['avatar'] ?? '' : '',    // ✅ Changed to avatar

      userHasBoosted: json['user_boosted'] ?? false,
      likeCount: json['like_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      likedByMe: json['liked_by_me'] ?? false,
    );
  }

  /// NEW: ALIAS FOR fromMap
  factory MilestoneModel.fromMap(Map<String, dynamic> map) {
    return MilestoneModel.fromJson(map);
  }

  /// TO JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'milestone_type': milestoneType,
      'created_at': createdAt.toIso8601String(),
      'visibility': visibility,
      'journey_visibility': journeyVisibility,   // ✅ Include in JSON

      'energy_boosts': energyBoosts,
      'media_url': mediaUrl,

      'username': username,
      'avatar': avatar,                          // ✅ Changed to avatar

      'user_boosted': userHasBoosted,
      'like_count': likeCount,
      'comment_count': commentCount,
      'liked_by_me': likedByMe,
    };
  }
}
