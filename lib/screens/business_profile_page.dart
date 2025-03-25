import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'profile_screen.dart';
import 'submit_service_page.dart';
import '../services/supabase_service.dart';
import 'package:intl/intl.dart';

class BusinessProfilePage extends StatefulWidget {
  final String name;
  final String serviceType; // ✅ Added field
  final String tagline;
  final String description;
  final String profileImageUrl;
  final double rating;
  final String adCreatedDate;
  final String userId;
  final String adId;

  const BusinessProfilePage({
    Key? key,
    required this.name,
    required this.serviceType, // ✅ Added to constructor
    required this.tagline,
    required this.description,
    required this.profileImageUrl,
    required this.rating,
    required this.adCreatedDate,
    required this.userId,
    required this.adId,
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
  List<String> categories = [];

  late BannerAd _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    currentUserId = supabase.auth.currentUser?.id ?? '';
    _loadAverageRating();
    _fetchCategoriesForAd();
    _initBannerAd();
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  Future<void> _initBannerAd() async {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test ad unit
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isAdLoaded = true),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    );
    await _bannerAd.load();
  }

  Future<void> _loadAverageRating() async {
    try {
      final result = await supabase
          .from('ratings')
          .select('rating')
          .eq('business_id', widget.adId); // ✅ Corrected adId lookup

      if (result.isNotEmpty) {
        double total = result.fold(0.0, (sum, row) => sum + (row['rating'] as num).toDouble());
        setState(() {
          averageRating = total / result.length;
        });

        await supabase.from('service_ads').update({
          'rating': averageRating
        }).eq('id', widget.adId);
      } else {
        setState(() => averageRating = 0);
      }
    } catch (error) {
      print('❌ Error loading average rating: $error');
    }
  }

  Future<void> _fetchCategoriesForAd() async {
    try {
      final response = await supabase
          .from('service_ads_categories')
          .select('service_categories (name)') // ✅ Correct column name!
          .eq('ad_id', widget.adId); // ✅ Corrected id lookup

      final categoryNames = response
          .map<String>((row) => row['service_categories']['name'] as String)
          .toList();

      setState(() {
        categories = categoryNames;
      });
    } catch (error) {
      print('❌ Error fetching categories: $error');
    }
  }

  Future<void> _submitRating(int rating) async {
    if (currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❗ You need to be logged in to rate.')),
      );
      return;
    }

    try {
      await supabase.from('ratings').upsert({
        'user_id': currentUserId,
        'business_id': widget.adId,
        'rating': rating,
      }, onConflict: 'user_id, business_id');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Thanks for rating!')),
      );

      _loadAverageRating();
    } catch (error) {
      print('❌ Error submitting rating: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to submit rating.')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.blueGrey.shade800,
        title: Text("Delete Ad?", style: TextStyle(color: Colors.white)),
        content: Text("Are you sure?", style: TextStyle(color: Colors.white70)),
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
                await supabase.from('service_ads_categories').delete().eq('ad_id', widget.adId);
                await supabase.from('service_ads').delete().eq('id', widget.adId);

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

  Widget _categoriesDisplay() {
    if (categories.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8.0,
        children: categories.map((category) => Chip(
          label: Text(category, style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.deepPurpleAccent,
        )).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = currentUserId == widget.userId;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _backgroundGradient(),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _bannerAdWidget(),
                  _headerSection(),
                  SizedBox(height: 80),
                  _profileInfoCard(),
                  _categoriesDisplay(),
                  _descriptionCard(),
                  _ratingCard(),
                  _actionButtons(isOwner),
                  if (!isOwner) _buildStarRatingSection(),
                  SizedBox(height: 20),
                  _buildReportButton(),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backgroundGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade900, Colors.deepPurple.shade600],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _bannerAdWidget() {
    return _isAdLoaded
        ? Container(
      padding: EdgeInsets.only(top: 10),
      alignment: Alignment.center,
      width: _bannerAd.size.width.toDouble(),
      height: _bannerAd.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd),
    )
        : SizedBox.shrink();
  }

  Widget _headerSection() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/misc2.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.amberAccent.withOpacity(0.8),
                  blurRadius: 40,
                  spreadRadius: 15,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              backgroundImage: widget.profileImageUrl.isNotEmpty
                  ? NetworkImage(widget.profileImageUrl)
                  : AssetImage('assets/images/default_avatar.png') as ImageProvider,
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileInfoCard() {
    String formattedDate = _formatDate(widget.adCreatedDate);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurpleAccent.withOpacity(0.5),
              blurRadius: 12,
              spreadRadius: 2,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(widget.name, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text(widget.serviceType, style: TextStyle(color: Colors.amberAccent, fontSize: 16)),
            SizedBox(height: 6),
            Text(widget.tagline, style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 14)),
            SizedBox(height: 12),
            Text("Posted on: $formattedDate", style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dateTime = DateTime.parse(isoDate);
      return DateFormat('dd MMM yyyy').format(dateTime);
    } catch (e) {
      return isoDate;
    }
  }

  Widget _descriptionCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About This Service', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(widget.description, style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _ratingCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text('Ratings', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            _buildAverageRatingDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildAverageRatingDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(5, (index) {
          return Icon(
            index < averageRating.floor() ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 24,
          );
        }),
        SizedBox(width: 8),
        Text(averageRating.toStringAsFixed(1), style: TextStyle(color: Colors.white, fontSize: 16)),
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
                setState(() => selectedRating = starValue);
                _submitRating(starValue);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildReportButton() {
    return ElevatedButton.icon(
      onPressed: _showReportDialog,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black.withOpacity(0.7),
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      icon: Icon(Icons.flag_outlined, color: Colors.redAccent.shade100),
      label: Text('Report Ad', style: TextStyle(color: Colors.redAccent.shade100, fontWeight: FontWeight.bold)),
    );
  }

  Widget _actionButtons(bool isOwner) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          _buildContactOrProfileButton(isOwner),
          if (isOwner) ...[
            SizedBox(height: 10),
            _buildEditButton(),
            SizedBox(height: 10),
            _buildDeleteButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildContactOrProfileButton(bool isOwner) {
    return ElevatedButton.icon(
      onPressed: () {
        if (isOwner) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('This is your ad!')));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userId: widget.userId)));
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amberAccent,
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      icon: Icon(Icons.person, color: Colors.black87),
      label: Text('View Profile', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEditButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubmitYourServicePage(
              isEditing: true,
              existingAdData: {
                'id': widget.adId,
                'name': widget.name,
                'tagline': widget.tagline,
                'description': widget.description,
                'profile_image_url': widget.profileImageUrl,
                'categories': categories,
              },
            ),
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
      onPressed: _confirmDelete,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      icon: Icon(Icons.delete_outline, color: Colors.white),
      label: Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            hintText: 'Enter the reason...',
            hintStyle: TextStyle(color: Colors.white60),
            filled: true,
            fillColor: Colors.blueGrey.shade700,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.white70))),
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
                targetId: widget.adId,
                targetType: 'ad',
                reason: reason,
              );
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? '✅ Report submitted!' : '❌ Failed to submit report.')));
            },
            child: Text('Submit', style: TextStyle(color: Colors.redAccent.shade100)),
          ),
        ],
      ),
    );
  }
}
