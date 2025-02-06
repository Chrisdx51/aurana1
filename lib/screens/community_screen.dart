import 'package:flutter/material.dart';
import '../models/comment_model.dart';

class CommunityScreen extends StatefulWidget {
  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<Post> posts = [
    Post(user: "Alice", content: "Today’s meditation was amazing!", comments: []),
    Post(user: "Chris", content: "Feeling blessed and grateful.", comments: []),
  ];

  TextEditingController _messageController = TextEditingController();
  int selectedPostIndex = 0; // Default to first post
  Map<int, String> userReactions = {}; // Track user's reaction per post
  Map<int, Map<String, int>> postReactions = {}; // Track all reactions per post

  void _sendMessage() {
    String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      setState(() {
        posts[selectedPostIndex].comments.add(
          Comment(user: "You", content: message, timestamp: DateTime.now()),
        );
      });
      _messageController.clear();
    }
  }

  void _addReaction(int postIndex, String reaction) {
    setState(() {
      if (!postReactions.containsKey(postIndex)) {
        postReactions[postIndex] = {};
      }

      // Check if user has already reacted to this post
      if (userReactions.containsKey(postIndex)) {
        // Remove old reaction count
        String oldReaction = userReactions[postIndex]!;
        if (postReactions[postIndex]!.containsKey(oldReaction)) {
          postReactions[postIndex]![oldReaction] =
              (postReactions[postIndex]![oldReaction]! - 1).clamp(0, double.infinity.toInt());
        }
      }

      // Save the new reaction
      userReactions[postIndex] = reaction;
      if (postReactions[postIndex]!.containsKey(reaction)) {
        postReactions[postIndex]![reaction] = (postReactions[postIndex]![reaction]! + 1);
      } else {
        postReactions[postIndex]![reaction] = 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Community Discussions')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedPostIndex = index;
                    });
                  },
                  child: Card(
                    margin: EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.user, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          SizedBox(height: 5),
                          Text(post.content, style: TextStyle(fontSize: 16)),
                          SizedBox(height: 10),
                          // Emoji Reactions
                          Row(
                            children: [
                              _reactionButton(index, "🙏"),
                              _reactionButton(index, "🧘"),
                              _reactionButton(index, "🌟"),
                              _reactionButton(index, "💜"),
                              _reactionButton(index, "✨"),
                            ],
                          ),
                          SizedBox(height: 5),
                          Wrap(
                            children: postReactions[index]?.entries.map((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      "${entry.key} ${entry.value}",
                                      style: TextStyle(fontSize: 12), // Smaller text
                                    ),
                                  );
                                }).toList() ??
                                [],
                          ),
                          SizedBox(height: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: post.comments.map((comment) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(
                                  "${comment.user}: ${comment.content}",
                                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Chat box at the bottom of the screen
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
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a comment...",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(10),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.purple),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reactionButton(int postIndex, String emoji) {
    return GestureDetector(
      onTap: () => _addReaction(postIndex, emoji),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: userReactions[postIndex] == emoji ? Colors.purple.shade100 : Colors.white, // Highlight selected reaction
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Text(
              emoji,
              style: TextStyle(fontSize: 12), // Much smaller emoji size
            ),
            SizedBox(width: 4),
            Text(
              postReactions[postIndex]?[emoji]?.toString() ?? "0", // Show count
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), // Smaller text
            ),
          ],
        ),
      ),
    );
  }
}
