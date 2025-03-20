import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../services/supabase_service.dart';
import '../models/milestone_model.dart';
import 'profile_screen.dart';
import 'add_milestone_screen.dart';
import '../widgets/video_widget.dart';
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
  bool _isGlobal = false; // 🌕 False = Inner Realm | True = Cosmic Flow

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

  void _showReportDialog(String milestoneId) async {
    String? selectedReason;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Report Post', style: TextStyle(color: Colors.white)),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                dropdownColor: Colors.grey[800],
                value: selectedReason,
                hint: Text('Select Reason', style: TextStyle(color: Colors.white70)),
                onChanged: (value) => setState(() => selectedReason = value),
                items: [
                  'Spam',
                  'Harassment',
                  'Inappropriate Content',
                  'Misinformation',
                  'Other'
                ].map((reason) => DropdownMenuItem(
                  value: reason,
                  child: Text(reason, style: TextStyle(color: Colors.white)),
                )).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Report'),
            onPressed: () async {
              if (selectedReason == null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❗ Please select a reason.")));
                return;
              }

              try {
                await supabase.from('reports').insert({
                  'reported_by': supabase.auth.currentUser!.id,
                  'milestone_id': milestoneId,
                  'reason': selectedReason,
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Report submitted.")));
              } catch (error) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Failed to submit report.")));
              }
            },
          ),
        ],
      ),
    );
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
    // Debug print to confirm media URL (optional)
    print('🔗 Media URL for milestone ${milestone.id}: ${milestone.mediaUrl}');

    return Stack(
      children: [
        Positioned.fill(
          child: _buildMedia(milestone),
        ),

        Positioned(
          right: 10,
          bottom: 150,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => _toggleLike(milestone),
                child: Column(
                  children: [
                    Icon(Icons.auto_awesome, size: 32, color: milestone.likedByMe ? Colors.amber : Colors.white),
                    SizedBox(height: 4),
                    Text('${milestone.likeCount}', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              SizedBox(height: 20),

              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("🗨️ Comment tapped!")));
                },
                child: Column(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 32, color: Colors.white),
                    SizedBox(height: 4),
                    Text('Comment', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
              SizedBox(height: 20),

              GestureDetector(
                onTap: () {
                  Share.share("🌟 Check out this Soul Journey on Aurana!\n\n${milestone.content ?? ''}");
                },
                child: Column(
                  children: [
                    Icon(Icons.share, size: 32, color: Colors.white),
                    SizedBox(height: 4),
                    Text('Share', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
              SizedBox(height: 20),

              GestureDetector(
                onTap: () => _showReportDialog(milestone.id),
                child: Column(
                  children: [
                    Icon(Icons.flag_outlined, size: 32, color: Colors.redAccent),
                    SizedBox(height: 4),
                    Text('Report', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),

        Positioned(
          bottom: 80,
          left: 16,
          right: 80,
          child: Text(
            milestone.content ?? '',
            style: TextStyle(color: Colors.white, fontSize: 16, shadows: [
              Shadow(blurRadius: 6, color: Colors.black87, offset: Offset(1, 1))
            ]),
          ),
        ),

        Positioned(
          bottom: 20,
          left: 16,
          child: GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: milestone.userId)));
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: milestone.avatar != null && milestone.avatar!.isNotEmpty
                      ? NetworkImage(milestone.avatar!)
                      : AssetImage('assets/images/default_avatar.png') as ImageProvider,
                ),
                SizedBox(width: 10),
                Text(
                  milestone.username ?? "Unknown Seeker",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, shadows: [
                    Shadow(blurRadius: 4, color: Colors.black87, offset: Offset(1, 1))
                  ]),
                ),
              ],
            ),
          ),
        ),

        if (milestone.userId == currentUserId)
          Positioned(
            top: 60,
            left: 10,
            child: IconButton(
              icon: Icon(Icons.delete, color: Colors.red, size: 30),
              onPressed: () => _deleteMilestone(milestone.id),
            ),
          ),
      ],
    );
  }

  Widget _buildMedia(MilestoneModel milestone) {
    if (milestone.mediaUrl == null || milestone.mediaUrl!.isEmpty) {
      return Container(color: Colors.black);
    }

    if (milestone.mediaUrl!.toLowerCase().endsWith('.mp4')) {
      return VideoWidget(videoUrl: milestone.mediaUrl!);
    }

    return Image.network(
      milestone.mediaUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        return Center(child: Icon(Icons.error, color: Colors.red));
      },
    );
  }
}
