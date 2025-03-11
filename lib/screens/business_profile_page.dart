import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_screen.dart';
import 'submit_service_page.dart';

class BusinessProfilePage extends StatefulWidget {
  final String name;
  final String serviceType;
  final String tagline;
  final String description;
  final String profileImageUrl;
  final double rating; // Can remove later if you want dynamic only.
  final String adCreatedDate;
  final String userId;

  const BusinessProfilePage({
    Key? key,
    required this.name,
    required this.serviceType,
    required this.tagline,
    required this.description,
    required this.profileImageUrl,
    required this.rating,
    required this.adCreatedDate,
    required this.userId,
  }) : super(key: key);

  @override
  _BusinessProfilePageState createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> {
  final supabase = Supabase.instance.client;

  int selectedRating = 0; // What the user selects to submit
  double averageRating = 0; // Average rating from database
  String currentUserId = '';

  @override
  void initState() {
    super.initState();
    currentUserId = supabase.auth.currentUser?.id ?? '';
    _loadAverageRating();
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = currentUserId == widget.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.white, Colors.redAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey.shade900, Colors.deepPurple.shade700],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Image
              CircleAvatar(
                radius: 60,
                backgroundImage: widget.profileImageUrl.isNotEmpty
                    ? NetworkImage(widget.profileImageUrl)
                    : AssetImage('assets/images/default_avatar.png') as ImageProvider,
              ),
              SizedBox(height: 16),

              // Name & Service Type
              Text(widget.name, style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
              Text(widget.serviceType, style: TextStyle(fontSize: 18, color: Colors.white70)),

              SizedBox(height: 10),

              // ⭐ Average Rating Display
              _buildAverageRatingDisplay(),

              SizedBox(height: 10),

              // Tagline
              Text(
                widget.tagline,
                style: TextStyle(fontSize: 16, color: Colors.amberAccent, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 10),

              // Date Posted
              Text("Posted on: ${widget.adCreatedDate}", style: TextStyle(fontSize: 12, color: Colors.white54)),

              SizedBox(height: 20),

              // Description
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(widget.description, style: TextStyle(fontSize: 14, color: Colors.black87), textAlign: TextAlign.justify),
              ),

              SizedBox(height: 30),

              // Contact / View Profile Button
              _buildContactOrProfileButton(isOwner),

              SizedBox(height: 10),

              // If owner, show Edit/Delete buttons
              if (isOwner) ...[
                _buildEditButton(),
                SizedBox(height: 10),
                _buildDeleteButton(),
              ],

              SizedBox(height: 20),

              // ⭐ Star Rating Section (only for visitors)
              if (!isOwner) _buildStarRatingSection(),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Display average rating stars
  Widget _buildAverageRatingDisplay() {
    int fullStars = averageRating.floor();
    bool hasHalfStar = (averageRating - fullStars) >= 0.5;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(5, (index) {
          if (index < fullStars) {
            return Icon(Icons.star, color: Colors.amber, size: 24);
          } else if (index == fullStars && hasHalfStar) {
            return Icon(Icons.star_half, color: Colors.amber, size: 24);
          } else {
            return Icon(Icons.star_border, color: Colors.amber, size: 24);
          }
        }),
        SizedBox(width: 8),
        Text(
          averageRating.toStringAsFixed(1),
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }

  // ✅ Build Star Rating Section for users to rate
  Widget _buildStarRatingSection() {
    return Column(
      children: [
        Text("Rate This Service", style: TextStyle(color: Colors.white)),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            int starValue = index + 1;
            return IconButton(
              icon: Icon(
                starValue <= selectedRating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 32,
              ),
              onPressed: () {
                setState(() {
                  selectedRating = starValue;
                });
                _submitRating(starValue);
              },
            );
          }),
        ),
      ],
    );
  }

  // ✅ Submit Rating to Supabase
  Future<void> _submitRating(int rating) async {
    try {
      await supabase.from('ratings').upsert({
        'user_id': currentUserId,
        'business_id': widget.userId,
        'rating': rating,
      }, onConflict: 'user_id, business_id');

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Thanks for rating!')));
      _loadAverageRating();
    } catch (error) {
      print('❌ Error submitting rating: $error');
    }
  }

  // ✅ Load Average Rating from Supabase
  Future<void> _loadAverageRating() async {
    try {
      final result = await supabase
          .from('ratings')
          .select('rating')
          .eq('business_id', widget.userId);

      if (result != null && result.isNotEmpty) {
        double total = 0;
        for (var row in result) {
          total += row['rating'];
        }

        setState(() {
          averageRating = total / result.length;
        });
      } else {
        setState(() {
          averageRating = 0;
        });
      }
    } catch (error) {
      print('❌ Error loading average rating: $error');
    }
  }

  // ✅ Contact or View Profile Button
  Widget _buildContactOrProfileButton(bool isOwner) {
    return ElevatedButton.icon(
      onPressed: () {
        if (currentUserId == null) return;

        if (isOwner) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('This is your ad!')));
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(userId: widget.userId),
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amberAccent,
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      icon: Icon(Icons.person, color: Colors.black87),
      label: Text(
        'View Profile',
        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ✅ Edit Ad Button
  Widget _buildEditButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubmitYourServicePage(), // Pass adId if you want to
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurpleAccent,
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      icon: Icon(Icons.edit, color: Colors.white),
      label: Text('Edit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  // ✅ Delete Ad Button
  Widget _buildDeleteButton() {
    return ElevatedButton.icon(
      onPressed: () => _confirmDelete(),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      icon: Icon(Icons.delete_outline, color: Colors.white),
      label: Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  // ✅ Confirm Delete Dialog
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.blueGrey.shade800,
        title: Text("Delete Ad?", style: TextStyle(color: Colors.white)),
        content: Text("Are you sure you want to delete this ad?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            child: Text("Cancel", style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: Text("Delete", style: TextStyle(color: Colors.redAccent)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await supabase
                    .from('service_ads')
                    .delete()
                    .eq('user_id', widget.userId);

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ad deleted successfully!")));
                Navigator.of(context).pop(); // Go back after delete
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete ad!")));
              }
            },
          ),
        ],
      ),
    );
  }
}
