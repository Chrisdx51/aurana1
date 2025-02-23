import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/milestone_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_milestone_screen.dart';
import '../widgets/video_widget.dart';

class SoulJourneyScreen extends StatefulWidget {
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
      List<MilestoneModel> milestones =
      await _supabaseService.fetchMilestones(sortBy: _sortOption);
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
      appBar: AppBar(
        title: Text("Soul Journey"),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _milestones.isEmpty
          ? Center(child: Text("No milestones yet. Start your journey!"))
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
                    backgroundImage:
                    milestone.icon != null && milestone.icon!.isNotEmpty
                        ? NetworkImage(milestone.icon!)
                        : AssetImage('assets/default_avatar.png')
                    as ImageProvider,
                  ),
                  title: Text(
                    milestone.username ?? "Unknown Seeker",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                      "${milestone.milestoneType} • ${milestone.createdAt.toLocal()}"),
                  trailing: milestone.userId ==
                      Supabase.instance.client.auth.currentUser?.id
                      ? IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await _deleteMilestone(milestone.id);
                    },
                  )
                      : null,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(milestone.content,
                      style: TextStyle(fontSize: 16)),
                ),

                // ✅ Fixed Media Display Logic
                if (milestone.mediaUrl != null && milestone.mediaUrl!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: milestone.mediaUrl!.endsWith('.mp4')
                          ? AspectRatio(
                        aspectRatio: 16 / 9,
                        child: VideoWidget(videoUrl: milestone.mediaUrl!),
                      )
                          : Image.network(
                        milestone.mediaUrl!,
                        width: double.infinity, // ✅ Full width
                        height: null, // ✅ No fixed height (auto scales)
                        fit: BoxFit.contain, // ✅ Ensures the whole image fits in frame
                        alignment: Alignment.center, // ✅ Centers the image properly
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.broken_image, size: 100, color: Colors.grey),
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
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
                              .addEnergyBoost(milestone.id);
                          if (success) {
                            setState(() {
                              _milestones[index] =
                                  milestone.copyWith(
                                    energyBoosts:
                                    milestone.energyBoosts + 1,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          bool? result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddMilestoneScreen()),
          );

          if (result == true) {
            _loadMilestones();
          }
        },
        backgroundColor: Colors.deepPurple,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
