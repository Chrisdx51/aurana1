import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/milestone_model.dart';
import 'profile_screen.dart';
import 'add_milestone_screen.dart';
import '../widgets/video_widget.dart';

class SoulJourneyScreen extends StatefulWidget {
  final String userId;

  SoulJourneyScreen({required this.userId});

  @override
  _SoulJourneyScreenState createState() => _SoulJourneyScreenState();
}

class _SoulJourneyScreenState extends State<SoulJourneyScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<MilestoneModel> _milestones = [];
  bool _isLoading = true;
  final supabase = Supabase.instance.client;
  bool _isGlobal = false; // ✅ Default to "Soul Journey" (User's own posts)

  @override
  void initState() {
    super.initState();
    _loadMilestones();
  }

  Future<void> _loadMilestones() async {
    try {
      final userId = widget.userId;

      List<MilestoneModel> milestones;
      if (_isGlobal) {
        milestones = await _supabaseService.fetchMilestones(global: true);
      } else {
        milestones = await _supabaseService.fetchMilestones(userId: userId);
      }

      // ✅ Debug Output
      print("🔹 Loaded ${milestones.length} milestones. Global: $_isGlobal");
      for (var milestone in milestones) {
        print("➡️ ${milestone.content} | Visibility: ${milestone.visibility}");
      }

      setState(() {
        _milestones = milestones;
        _isLoading = false;
      });
    } catch (error) {
      print("❌ Error loading milestones: $error");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMilestone(String milestoneId) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Post"),
        content: Text("Are you sure you want to delete this milestone?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text("Cancel")),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (!confirmDelete) return;

    bool success = await _supabaseService.deleteMilestone(milestoneId);
    if (success) {
      setState(() => _milestones.removeWhere((m) => m.id == milestoneId));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Milestone deleted successfully!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Failed to delete milestone.")));
    }
  }

  void _toggleLike(MilestoneModel milestone) async {
    setState(() {
      milestone.likedByMe = !milestone.likedByMe;
      milestone.likeCount += milestone.likedByMe ? 1 : -1;
    });

    try {
      if (milestone.likedByMe) {
        await supabase.from('journey_likes').insert({'journey_id': milestone.id, 'user_id': supabase.auth.currentUser!.id});
      } else {
        await supabase.from('journey_likes').delete().match({'journey_id': milestone.id, 'user_id': supabase.auth.currentUser!.id});
      }
    } catch (error) {
      print('Error toggling like: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/bg10.png', fit: BoxFit.cover),
          ),
          Column(
            children: [
              AppBar(
                title: Flexible( // ✅ Prevents overflow
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded( // ✅ Ensures buttons do not overflow
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _isGlobal = false;
                              _loadMilestones();
                            });
                          },
                          child: Text("Soul Journey",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: !_isGlobal ? Colors.white : Colors.white70, fontSize: 18)),
                        ),
                      ),
                      SizedBox(width: 10), // ✅ Reduce width to avoid overflow
                      Expanded( // ✅ Ensures buttons do not overflow
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _isGlobal = true;
                              _loadMilestones();
                            });
                          },
                          child: Text("Global Wall",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: _isGlobal ? Colors.white : Colors.white70, fontSize: 18)),
                        ),
                      ),
                    ],
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _milestones.isEmpty
                    ? Center(child: Text("No milestones yet. Start your journey!"))
                    : PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: _milestones.length,
                  itemBuilder: (context, index) {
                    var milestone = _milestones[index];

                    return Stack(
                      children: [
                        Positioned.fill(
                          child: milestone.mediaUrl != null && milestone.mediaUrl!.isNotEmpty
                              ? milestone.mediaUrl!.endsWith('.mp4')
                              ? VideoWidget(videoUrl: milestone.mediaUrl!)
                              : Image.network(milestone.mediaUrl!, fit: BoxFit.cover)
                              : Container(color: Colors.blueGrey),
                        ),
                        Positioned(
                          top: 50,
                          left: 10,
                          right: 10,
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => ProfileScreen(userId: milestone.userId)),
                                  );
                                },
                                child: CircleAvatar(
                                  backgroundImage: milestone.icon != null && milestone.icon!.isNotEmpty
                                      ? NetworkImage(milestone.icon!)
                                      : null,
                                  backgroundColor: Colors.grey.shade200, // Shows a grey background if no image
                                  radius: 25,
                                  child: milestone.icon == null || milestone.icon!.isEmpty
                                      ? Icon(Icons.person, color: Colors.white, size: 24) // Placeholder icon
                                      : null,
                                ),
                              ),
                              SizedBox(width: 10),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => ProfileScreen(userId: milestone.userId)),
                                  );
                                },
                                child: Text(
                                  milestone.username ?? "Unknown Seeker",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                              Spacer(),
                              if (milestone.userId == supabase.auth.currentUser?.id)
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await _deleteMilestone(milestone.id);
                                  },
                                )
                              else
                                IconButton(
                                  icon: Icon(Icons.report, color: Colors.white),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("⚠️ Report submitted for review.")),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 100,
                          left: 10,
                          right: 10,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(milestone.content, style: TextStyle(fontSize: 18, color: Colors.white)),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _toggleLike(milestone),
                                    child: Icon(Icons.auto_awesome, color: milestone.likedByMe ? Colors.amber : Colors.white, size: 30),
                                  ),
                                  SizedBox(width: 10),
                                  Text("${milestone.likeCount}", style: TextStyle(fontSize: 18, color: Colors.white)),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (_) => CommentSheet(milestone: milestone),
                                  );
                                },
                                child: Text("💬 View Comments", style: TextStyle(fontSize: 16, color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: widget.userId == supabase.auth.currentUser?.id
          ? FloatingActionButton(
        onPressed: () async {
          bool? result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddMilestoneScreen()),
          );
          if (result == true) {
            _loadMilestones();
          }
        },
        backgroundColor: Colors.lightBlue,
        child: Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }
}

class CommentSheet extends StatefulWidget {
  final MilestoneModel milestone;

  CommentSheet({required this.milestone});

  @override
  _CommentSheetState createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final supabase = Supabase.instance.client;
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  // ✅ Fetch comments from Supabase
  Future<void> _loadComments() async {
    try {
      final response = await supabase
          .from('milestone_comments') // ✅ Correct table name
          .select('text, created_at, profiles(name)')
          .eq('milestone_id', widget.milestone.id)
          .order('created_at', ascending: false);

      setState(() {
        _comments = response;
      });
    } catch (e) {
      print("❌ Error loading comments: $e");
    }
  }

  // ✅ Add new comment
  void _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    _commentController.clear();

    try {
      await supabase.from('journey_comments').insert({
        'journey_id': widget.milestone.id,
        'user_id': supabase.auth.currentUser!.id,
        'text': content,
      });

      _loadComments(); // Refresh comments after adding
    } catch (e) {
      print("❌ Error adding comment: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(width: 40, height: 4, color: Colors.grey[300]),
          SizedBox(height: 10),
          Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Expanded(
            child: _comments.isEmpty
                ? Center(child: Text("No comments yet.", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                final comment = _comments[index];
                return ListTile(
                  title: Text(comment['text']),
                  subtitle: Text(comment['profiles']?['username'] ?? "Anonymous"),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 8, right: 8, top: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                      contentPadding: EdgeInsets.all(8),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blueAccent),
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