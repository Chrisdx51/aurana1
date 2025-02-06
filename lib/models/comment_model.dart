class Comment {
  String user;
  String content;
  DateTime timestamp;

  Comment({required this.user, required this.content, required this.timestamp});
}

class Post {
  String user;
  String content;
  int likes;
  List<String> reactions;
  List<Comment> comments;

  Post({
    required this.user,
    required this.content,
    this.likes = 0,
    this.reactions = const [],
    List<Comment>? comments,
  }) : comments = comments ?? []; // This makes the list mutable
}
