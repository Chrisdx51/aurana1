import 'dart:io';

class Comment {
  final String user;
  final String content;
  final List<Comment> replies;

  Comment({
    required this.user,
    required this.content,
    required this.replies,
  });

  Map<String, dynamic> toJson() => {
        'user': user,
        'content': content,
        'replies': replies.map((reply) => reply.toJson()).toList(),
      };

  static Comment fromJson(Map<String, dynamic> json) => Comment(
        user: json['user'],
        content: json['content'],
        replies: (json['replies'] as List)
            .map((reply) => Comment.fromJson(reply))
            .toList(),
      );
}

class Post {
  final String user;
  final String content;
  final File? image; // Added image property here
  int likes;
  List<String> reactions;
  List<Comment> comments;
  final DateTime timestamp;

  Post({
    required this.user,
    required this.content,
    this.image,
    this.likes = 0,
    this.reactions = const [],
    List<Comment>? comments,
    required this.timestamp,
  }) : comments = comments ?? [];

  Map<String, dynamic> toJson() => {
        'user': user,
        'content': content,
        'image': image?.path, // Serialize image as path
        'likes': likes,
        'reactions': reactions,
        'comments': comments.map((c) => c.toJson()).toList(),
        'timestamp': timestamp.toIso8601String(),
      };

  static Post fromJson(Map<String, dynamic> json) => Post(
        user: json['user'],
        content: json['content'],
        image: json['image'] != null ? File(json['image']) : null,
        likes: json['likes'],
        reactions: List<String>.from(json['reactions']),
        comments:
            (json['comments'] as List).map((c) => Comment.fromJson(c)).toList(),
        timestamp: DateTime.parse(json['timestamp']),
      );
}
