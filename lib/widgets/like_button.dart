import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/likes_service.dart';

class LikeButton extends StatefulWidget {
  final String postId;
  final String userId;

  LikeButton({required this.postId, required this.userId});

  @override
  _LikeButtonState createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  final LikesService likesService = LikesService();
  bool isLiked = false;
  int likeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadLikeStatus();
  }

  // 🔥 Load Like Status & Count
  Future<void> _loadLikeStatus() async {
    bool liked = await likesService.hasUserLikedPost(widget.postId, widget.userId);
    int count = await likesService.getLikesCount(widget.postId);

    setState(() {
      isLiked = liked;
      likeCount = count;
    });
  }

  // 🔥 Toggle Like
  Future<void> _toggleLike() async {
    if (isLiked) {
      await likesService.removeLike(widget.postId, widget.userId);
    } else {
      await likesService.addLike(widget.postId, widget.userId);
    }

    _loadLikeStatus(); // Refresh like count & state
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: Colors.red),
          onPressed: _toggleLike,
        ),
        Text("$likeCount"),
      ],
    );
  }
}
