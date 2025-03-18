import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../models/milestone_model.dart';
import 'profile_screen.dart';
import 'add_milestone_screen.dart';
import '../widgets/video_widget.dart';

// ✅ BannerAdWidget import here
import '../widgets/banner_ad_widget.dart';

class SoulJourneyScreen extends StatefulWidget {
  final String userId;

  const SoulJourneyScreen({required this.userId});

  @override
  _SoulJourneyScreenState createState() => _SoulJourneyScreenState();
}

class _SoulJourneyScreenState extends State<SoulJourneyScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final supabase = Supabase.instance.client;

  List<MilestoneModel> _milestones = [];
  bool _isLoading = true;

  // 🌕 False = Inner Realm | True = Cosmic Flow
  bool _isGlobal = false;

  @override
  void initState() {
    super.initState();
    _loadMilestones();
  }

  Future<void> _loadMilestones() async {
    setState(() => _isLoading = true);

    try {
      final currentUserId = supabase.auth.currentUser!.id;

      List<MilestoneModel> milestones;

      if (_isGlobal) {
        milestones = await _supabaseService.fetchMilestones(global: true);
      } else {
        milestones = await _supabaseService.fetchMilestones(userId: widget.userId);
      }

      print("✅ Loaded ${milestones.length} milestones.");

      setState(() {
        _milestones = milestones;
        _isLoading = false;
      });
    } catch (error) {
      print("❌ Error loading milestones: $error");
      setState(() => _isLoading = false);
    }
  }

  void _toggleLike(MilestoneModel milestone) async {
    final currentUserId = supabase.auth.currentUser!.id;

    setState(() {
      milestone.likedByMe = !milestone.likedByMe;
      milestone.likeCount += milestone.likedByMe ? 1 : -1;
    });

    try {
      if (milestone.likedByMe) {
        await supabase.from('journey_likes').insert({
          'journey_id': milestone.id,
          'user_id': currentUserId,
        });
      } else {
        await supabase.from('journey_likes').delete().match({
          'journey_id': milestone.id,
          'user_id': currentUserId,
        });
      }
    } catch (error) {
      print('❌ Error toggling like: $error');
    }
  }

  Future<void> _deleteMilestone(String milestoneId) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Post"),
        content: Text("Are you sure you want to delete this milestone?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text("Cancel")),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmDelete != true) return;

    final success = await _supabaseService.deleteMilestone(milestoneId);

    if (success) {
      setState(() => _milestones.removeWhere((m) => m.id == milestoneId));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Milestone deleted!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Failed to delete milestone.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = supabase.auth.currentUser!.id;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/bg10.png', fit: BoxFit.cover)),

          Column(
            children: [
              _buildAppBar(),

              // ✅ Banner Ad with spacing below it
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: BannerAdWidget(),
              ),
              SizedBox(height: 10),

              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _milestones.isEmpty
                    ? Center(child: Text("No milestones yet."))
                    : PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: _milestones.length,
                  itemBuilder: (context, index) {
                    final milestone = _milestones[index];
                    return _buildMilestoneItem(milestone, currentUserId);
                  },
                ),
              ),
            ],
          ),
        ],
      ),

      floatingActionButton: widget.userId == currentUserId
          ? FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddMilestoneScreen()),
          );
          if (result == true) _loadMilestones();
        },
        backgroundColor: Colors.lightBlue,
        child: Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }

  Widget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTabButton("Inner Realm", !_isGlobal, () {
            setState(() {
              _isGlobal = false;
              _loadMilestones();
            });
          }),
          SizedBox(width: 10),
          _buildTabButton("Cosmic Flow", _isGlobal, () {
            setState(() {
              _isGlobal = true;
              _loadMilestones();
            });
          }),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: TextButton(
        onPressed: onTap,
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMilestoneItem(MilestoneModel milestone, String currentUserId) {
    return Stack(
      children: [
        Positioned.fill(
          child: milestone.mediaUrl != null && milestone.mediaUrl!.isNotEmpty
              ? milestone.mediaUrl!.endsWith('.mp4')
              ? VideoWidget(videoUrl: milestone.mediaUrl!)
              : Image.network(milestone.mediaUrl!, fit: BoxFit.cover)
              : Container(color: Colors.black),
        ),

        Positioned(
          top: 50,
          left: 10,
          right: 10,
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: milestone.userId)));
                },
                child: CircleAvatar(
                  radius: 25,
                  backgroundImage: milestone.avatar != null && milestone.avatar!.isNotEmpty
                      ? NetworkImage(milestone.avatar!)
                      : AssetImage('assets/images/default_avatar.png') as ImageProvider,
                ),
              ),
              SizedBox(width: 10),
              Text(
                milestone.username ?? "Unknown Seeker",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              if (milestone.userId == currentUserId)
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteMilestone(milestone.id),
                )
              else
                IconButton(
                  icon: Icon(Icons.report, color: Colors.white),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("🚨 Report submitted!")));
                  },
                ),
            ],
          ),
        ),

        Positioned(
          bottom: 80,
          left: 10,
          right: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(milestone.content ?? '', style: TextStyle(color: Colors.white, fontSize: 16)),
              SizedBox(height: 10),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.auto_awesome, color: milestone.likedByMe ? Colors.amber : Colors.white),
                    onPressed: () => _toggleLike(milestone),
                  ),
                  Text('${milestone.likeCount}', style: TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
