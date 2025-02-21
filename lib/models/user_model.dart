class UserModel {
  final String id;
  final String name;
  final String bio;
  final String? icon; // ✅ Profile Picture URL
  final String? dob;  // ✅ Date of Birth
  final String? spiritualPath; // ✅ Spiritual Path (New)
  final String? element; // ✅ Elemental Connection (New)

  UserModel({
    required this.id,
    required this.name,
    required this.bio,
    this.icon,
    this.dob,
    this.spiritualPath, // ✅ Added to constructor
    this.element, // ✅ Added to constructor
  });

  // ✅ Convert JSON Data from Supabase
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      bio: json['bio'] ?? '',
      icon: json['icon'], // Can be null
      dob: json['dob'],  // Can be null
      spiritualPath: json['spiritual_path'], // ✅ Fetch Spiritual Path
      element: json['element'], // ✅ Fetch Elemental Connection
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
      'spiritual_path': spiritualPath, // ✅ Store Spiritual Path
      'element': element, // ✅ Store Element
    };
  }

  // ✅ CopyWith Method (For Updating State)
  UserModel copyWith({
    String? name,
    String? bio,
    String? icon,
    String? dob,
    String? spiritualPath, // ✅ Allow updating Spiritual Path
    String? element, // ✅ Allow updating Elemental Connection
  }) {
    return UserModel(
      id: this.id,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      icon: icon ?? this.icon,
      dob: dob ?? this.dob,
      spiritualPath: spiritualPath ?? this.spiritualPath, // ✅ Update Spiritual Path
      element: element ?? this.element, // ✅ Update Element
    );
  }
}
