class UserModel {
  final String id;
  final String name;
  final String bio;
  final String? icon; // ✅ Profile Picture URL
  final String? dob;  // ✅ Date of Birth

  UserModel({
    required this.id,
    required this.name,
    required this.bio,
    this.icon,
    this.dob,
  });

  // ✅ Convert JSON Data from Supabase
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      bio: json['bio'] ?? '',
      icon: json['icon'], // Can be null
      dob: json['dob'],  // Can be null
    );
  }

  // ✅ Convert UserModel back to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'icon': icon,
      'dob': dob,
    };
  }

  // ✅ CopyWith Method (For Updating State)
  UserModel copyWith({
    String? name,
    String? bio,
    String? icon,
    String? dob,
  }) {
    return UserModel(
      id: this.id,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      icon: icon ?? this.icon,
      dob: dob ?? this.dob,
    );
  }
}
