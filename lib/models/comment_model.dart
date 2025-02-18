import 'dart:io';

class Comment {
  final String id;
  final String postId; // Link comment to a post
  final String userId; // Identify the commenter
  final String content;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'post_id': postId,
        'user_id': userId,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  static Comment fromJson(Map<String, dynamic> json) => Comment(
        id: json['id'],
        postId: json['post_id'],
        userId: json['user_id'],
        content: json['content'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

class Post {
  final String id;
  final String userId;
  final String content;
  final String? imageUrl;
  int likes;
  List<Comment> comments;
  final DateTime timestamp;

  Post({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    this.likes = 0,
    List<Comment>? comments,
    required this.timestamp,
  }) : comments = comments ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'content': content,
        'image_url': imageUrl,
        'likes': likes,
        'comments': comments.map((c) => c.toJson()).toList(),
        'timestamp': timestamp.toIso8601String(),
      };

  static Post fromJson(Map<String, dynamic> json) => Post(
        id: json['id'],
        userId: json['user_id'],
        content: json['content'],
        imageUrl: json['image_url'],
        likes: json['likes'],
        comments: (json['comments'] as List)
            .map((c) => Comment.fromJson(c))
            .toList(),
        timestamp: DateTime.parse(json['timestamp']),
      );
}
