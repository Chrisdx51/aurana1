class UserModel {
  final String id;
  final String name;
  final String bio;
  final String? icon;
  final String? dob; // ✅ Added Date of Birth

  UserModel({
    required this.id,
    required this.name,
    required this.bio,
    this.icon,
    this.dob, // ✅ Added to constructor
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      bio: json['bio'] ?? '',
      icon: json['icon'],
      dob: json['dob'], // ✅ Fetching DOB from database
    );
  }

  UserModel copyWith({
    String? name,
    String? bio,
    String? icon,
    String? dob, // ✅ Allow updating DOB
  }) {
    return UserModel(
      id: this.id,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      icon: icon ?? this.icon,
      dob: dob ?? this.dob, // ✅ Update DOB when needed
    );
  }
}
