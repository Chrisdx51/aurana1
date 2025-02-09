import 'package:flutter/material.dart';
import 'dart:io'; // Import the dart:io package for File
import '../models/comment_model.dart'; // Import the shared Comment model

class CommentsPage extends StatefulWidget {
  final String postUser;
  final String postContent;
  final File? postImage; // Add postImage here
  final List<Comment> comments;

  CommentsPage({
    required this.postUser,
    required this.postContent,
    this.postImage, // Initialize it here
    required this.comments,
  });

  @override
  _CommentsPageState createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final TextEditingController _commentController = TextEditingController();
  Comment? _replyingTo; // Tracks which comment the user is replying to

  void _addComment() {
    if (_commentController.text.isNotEmpty) {
      setState(() {
        if (_replyingTo == null) {
          // Add a top-level comment
          widget.comments.add(
            Comment(
              user: "You",
              content: _commentController.text,
              replies: [],
            ),
          );
        } else {
          // Add a reply to a specific comment
          _replyingTo!.replies.add(
            Comment(
              user: "You",
              content: _commentController.text,
              replies: [],
            ),
          );
        }
      });
      _commentController.clear();
      _replyingTo = null; // Reset reply mode
    }
  }

  void _startReplying(Comment comment) {
    setState(() {
      _replyingTo = comment;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Column(
        children: [
          // Post Details
          Card(
            margin: EdgeInsets.all(10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.postUser,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 5),
                  if (widget.postContent.isNotEmpty)
                    Text(
                      widget.postContent,
                      style: TextStyle(fontSize: 14),
                    ),
                  if (widget.postImage != null) // Show the post image
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Image.file(
                        widget.postImage!,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Comments List
          Expanded(
            child: ListView.builder(
              itemCount: widget.comments.length,
              itemBuilder: (context, index) {
                final comment = widget.comments[index];
                return _buildCommentTile(comment);
              },
            ),
          ),

          // Add Comment Bar
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Row(
              children: [
                if (_replyingTo != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      "Replying to ${_replyingTo!.user}",
                      style: TextStyle(color: Colors.teal.shade300, fontSize: 12),
                    ),
                  ),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "Write a comment...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.teal.shade300),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(Comment comment, {int depth = 0}) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 20.0, top: 8.0, bottom: 8.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.symmetric(horizontal: 10),
        color: Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.user,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 5),
              Text(
                comment.content,
                style: TextStyle(fontSize: 14),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _startReplying(comment),
                    child: Text(
                      "Reply",
                      style: TextStyle(color: Colors.teal.shade300),
                    ),
                  ),
                ],
              ),
              // Display Replies
              if (comment.replies.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: comment.replies.length,
                  itemBuilder: (context, index) {
                    return _buildCommentTile(comment.replies[index], depth: depth + 1);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
