import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/milestone_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_milestone_screen.dart';
import '../widgets/video_widget.dart';
import 'profile_screen.dart'; // Import ProfileScreen

class SoulJourneyScreen extends StatefulWidget {
  final String userId; // ✅ Ensure we pass a user ID

  SoulJourneyScreen({required this.userId});

  @override
  _SoulJourneyScreenState createState() => _SoulJourneyScreenState();
}

class _SoulJourneyScreenState extends State<SoulJourneyScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<MilestoneModel> _milestones = [];
  bool _isLoading = true;
  String _sortOption = "Newest";

  @override
  void initState() {
    super.initState();
    _loadMilestones();
  }

  Future<void> _loadMilestones() async {
    try {
      final userId = widget.userId; // ✅ Get user ID from the widget

      List<MilestoneModel> milestones = await _supabaseService.fetchMilestones(
        sortBy: _sortOption,
        userId: userId, // ✅ Only fetch this user's milestones
      );

      setState(() {
        _milestones = milestones;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Post"),
        content: Text("Are you sure you want to delete this milestone?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<void> _deleteMilestone(String milestoneId) async {
    bool confirmDelete = await _confirmDelete(context);
    if (!confirmDelete) return;

    bool success = await _supabaseService.deleteMilestone(milestoneId);

    if (success) {
      setState(() {
        _milestones.removeWhere((m) => m.id == milestoneId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Milestone deleted successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to delete milestone.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🔹 Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg10.png',
              fit: BoxFit.cover, // ✅ Ensures full coverage without distortion
            ),
          ),

          // 🔹 Main Content
          Column(
            children: [
              AppBar(
                title: Text("Your Soul Journey"),
                backgroundColor: Colors.white, // ✅ Makes AppBar blend in
                elevation: 0, // ✅ Removes shadow
              ),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _milestones.isEmpty
                    ? Center(
                    child: Text("No milestones yet. Start your journey!"))
                    : ListView.builder(
                  itemCount: _milestones.length,
                  itemBuilder: (context, index) {
                    var milestone = _milestones[index];

                    return Card(
                      margin: EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundImage: milestone.icon !=
                                  null &&
                                  milestone.icon!.isNotEmpty
                                  ? NetworkImage(milestone.icon!)
                                  : AssetImage(
                                  'assets/default_avatar.png')
                              as ImageProvider,
                            ),
                            title: GestureDetector(
                              onTap: () {
                                // ✅ Navigate to the clicked user's profile
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfileScreen(userId: milestone.userId),
                                  ),
                                );
                              },
                              child: Text(
                                milestone.username ?? "Unknown Seeker",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent, // ✅ Makes it look clickable
                                  decoration: TextDecoration.underline, // ✅ Highlights as a link
                                ),
                              ),
                            ),
                            subtitle: Text(
                                "${milestone.milestoneType} • ${milestone.createdAt.toLocal()}"),
                            trailing: milestone.userId ==
                                Supabase.instance.client.auth
                                    .currentUser?.id
                                ? IconButton(
                              icon: Icon(Icons.delete,
                                  color: Colors.red),
                              onPressed: () async {
                                await _deleteMilestone(
                                    milestone.id);
                              },
                            )
                                : null,
                          ),
                          Padding(
                            padding:
                            EdgeInsets.symmetric(horizontal: 10),
                            child: Text(milestone.content,
                                style: TextStyle(fontSize: 16)),
                          ),

                          // ✅ Fixed Media Display Logic
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: milestone.mediaUrl != null &&
                                  milestone.mediaUrl!.isNotEmpty
                                  ? Container(
                                height: 250, // ✅ Fixed Height
                                width: double.infinity, // ✅ Auto Adjust Width
                                child: milestone.mediaUrl!
                                    .endsWith('.mp4')
                                    ? VideoWidget(
                                    videoUrl: milestone
                                        .mediaUrl!)
                                    : Image.network(
                                  milestone.mediaUrl!,
                                  fit: BoxFit.contain, // ✅ Keeps the whole image visible
                                  errorBuilder: (context,
                                      error,
                                      stackTrace) =>
                                      Icon(
                                          Icons
                                              .broken_image,
                                          size: 100,
                                          color: Colors
                                              .grey),
                                ),
                              )
                                  : SizedBox(), // ✅ Prevents empty space if no media
                            ),
                          ),

                          Padding(
                            padding: EdgeInsets.all(10),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.start,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.local_fire_department,
                                    color: milestone.userHasBoosted
                                        ? Colors.orange
                                        : Colors.grey,
                                  ),
                                  onPressed: milestone.userHasBoosted
                                      ? null
                                      : () async {
                                    bool success =
                                    await _supabaseService
                                        .addEnergyBoost(
                                        milestone.id);
                                    if (success) {
                                      setState(() {
                                        _milestones[index] =
                                            milestone.copyWith(
                                              energyBoosts:
                                              milestone
                                                  .energyBoosts +
                                                  1,
                                              userHasBoosted: true,
                                            );
                                      });
                                    }
                                  },
                                ),
                                SizedBox(width: 5),
                                Text(
                                  "Boost ${milestone.energyBoosts}",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: widget.userId == Supabase.instance.client.auth.currentUser?.id
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
          : null, // ✅ Hide button if visiting another user's profile
    );
  }
}