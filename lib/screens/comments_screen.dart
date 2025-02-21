import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/comments_service.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;

  CommentsScreen({required this.postId});

  @override
  _CommentsScreenState createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final CommentsService commentsService = CommentsService();
  List<Map<String, dynamic>> comments = [];
  bool isLoading = true;
  TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  // 🔥 Load Comments
  Future<void> _loadComments() async {
    List<Map<String, dynamic>> fetchedComments =
    await commentsService.getComments(widget.postId);
    setState(() {
      comments = fetchedComments;
      isLoading = false;
    });
  }

  // 🔥 Add Comment
  Future<void> _addComment() async {
    if (commentController.text.isEmpty) return;
    final String userId = Supabase.instance.client.auth.currentUser?.id ?? "";
    if (userId.isEmpty) return;

    await commentsService.addComment(widget.postId, userId, commentController.text);
    commentController.clear();
    _loadComments(); // Refresh comments
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Comments")),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: comment['profile_pic'] != null
                        ? NetworkImage(comment['profile_pic'])
                        : AssetImage('assets/default_avatar.png') as ImageProvider,
                  ),
                  title: Text(comment['name']),
                  subtitle: Text(comment['content']),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: "Write a comment...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
