import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'profile_screen.dart';
import 'submit_service_page.dart';
import '../services/supabase_service.dart';

class BusinessProfilePage extends StatefulWidget {
  final String name;
  final String serviceType;
  final String tagline;
  final String description;
  final String profileImageUrl;
  final double rating;
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
  final supabaseService = SupabaseService();

  int selectedRating = 0;
  double averageRating = 0;
  String currentUserId = '';

  late BannerAd _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    currentUserId = supabase.auth.currentUser?.id ?? '';
    _loadAverageRating();
    _initBannerAd();
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  Future<void> _initBannerAd() async {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // ✅ Your test banner ad
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() => _isAdLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    _bannerAd.load();
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
      body: Column(
        children: [
          // ✅ Banner Ad on Top
          if (_isAdLoaded)
            Container(
              width: _bannerAd.size.width.toDouble(),
              height: _bannerAd.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd),
            ),

          // ✅ Page Content
          Expanded(
            child: Container(
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
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: widget.profileImageUrl.isNotEmpty
                          ? NetworkImage(widget.profileImageUrl)
                          : AssetImage('assets/images/default_avatar.png') as ImageProvider,
                    ),
                    SizedBox(height: 16),

                    Text(widget.name, style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(widget.serviceType, style: TextStyle(fontSize: 18, color: Colors.white70)),
                    SizedBox(height: 10),

                    _buildAverageRatingDisplay(),
                    SizedBox(height: 10),

                    Text(widget.tagline,
                        style: TextStyle(fontSize: 16, color: Colors.amberAccent, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center),
                    SizedBox(height: 10),

                    Text("Posted on: ${widget.adCreatedDate}", style: TextStyle(fontSize: 12, color: Colors.white54)),
                    SizedBox(height: 20),

                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(widget.description,
                          style: TextStyle(fontSize: 14, color: Colors.black87), textAlign: TextAlign.justify),
                    ),
                    SizedBox(height: 30),

                    _buildContactOrProfileButton(isOwner),
                    SizedBox(height: 10),

                    if (isOwner) ...[
                      _buildEditButton(),
                      SizedBox(height: 10),
                      _buildDeleteButton(),
                    ],

                    SizedBox(height: 20),

                    if (!isOwner) _buildStarRatingSection(),

                    SizedBox(height: 40), // ✅ Adds spacing before the report button

                    // ✅ Report Button at the VERY BOTTOM!
                    _buildReportButton(),

                    SizedBox(height: 20), // Add a little space below
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportButton() {
    return ElevatedButton.icon(
      onPressed: _showReportDialog,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        backgroundColor: Colors.black.withOpacity(0.7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        shadowColor: Colors.redAccent.withOpacity(0.4),
        elevation: 8,
      ).copyWith(
        foregroundColor: MaterialStateProperty.all(Colors.white),
      ),
      icon: Icon(Icons.flag_outlined, color: Colors.redAccent.shade100),
      label: Text('Report Ad', style: TextStyle(color: Colors.redAccent.shade100, fontWeight: FontWeight.bold)),
    );
  }

  void _showReportDialog() {
    TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.blueGrey.shade800,
        title: Text('Report Ad', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: reasonController,
          style: TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter the reason for reporting...',
            hintStyle: TextStyle(color: Colors.white60),
            filled: true,
            fillColor: Colors.blueGrey.shade700,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              String reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please provide a reason.')));
                return;
              }

              Navigator.pop(context);

              final success = await supabaseService.submitReport(
                reporterId: currentUserId,
                targetId: widget.userId,
                targetType: 'ad',
                reason: reason,
              );

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Report submitted successfully!')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Failed to submit report.')));
              }
            },
            child: Text('Submit', style: TextStyle(color: Colors.redAccent.shade100)),
          ),
        ],
      ),
    );
  }

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

  Widget _buildEditButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubmitYourServicePage(),
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
                Navigator.of(context).pop();
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
