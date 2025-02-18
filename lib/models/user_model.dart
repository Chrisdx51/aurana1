import 'dart:convert';

class UserModel {
  final String id;
  final String realName;
  final String nickname;
  final String bio;
  final String dob;
  final String zodiac;
  final String profilePic;
  final List<String> interests;

  UserModel({
    required this.id,
    required this.realName,
    required this.nickname,
    required this.bio,
    required this.dob,
    required this.zodiac,
    required this.profilePic,
    required this.interests,
  });

  // Convert a Supabase row to a UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      realName: json['real_name'] ?? '',
      nickname: json['nickname'] ?? '',
      bio: json['bio'] ?? '',
      dob: json['dob'] ?? '',
      zodiac: json['zodiac'] ?? '',
      profilePic: json['profile_pic'] ?? '',
      interests: (json['interests'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  // Convert UserModel to a Supabase row format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'real_name': realName,
      'nickname': nickname,
      'bio': bio,
      'dob': dob,
      'zodiac': zodiac,
      'profile_pic': profilePic,
      'interests': interests,
    };
  }
}
