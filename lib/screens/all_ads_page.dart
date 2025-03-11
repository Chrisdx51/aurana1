import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'business_profile_page.dart';

class AllAdsPage extends StatefulWidget {
  @override
  _AllAdsPageState createState() => _AllAdsPageState();
}

class _AllAdsPageState extends State<AllAdsPage> {
  List<Map<String, dynamic>> _ads = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  final List<String> _serviceTypes = [
    'All',
    'Psychic',
    'Tarot Reader',
    'Healer',
    'Medium',
    'Astrologer',
    'Energy Worker',
  ];

  final Map<String, Color> _filterColors = {
    'All': Colors.lightBlue,
    'Psychic': Colors.deepPurple,
    'Tarot Reader': Colors.indigo,
    'Healer': Colors.teal,
    'Medium': Colors.pinkAccent,
    'Astrologer': Colors.amber,
    'Energy Worker': Colors.green,
  };

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  Future<void> _loadAds() async {
    setState(() {
      _isLoading = true;
    });

    final ads = await SupabaseService().fetchBusinessAds();

    final now = DateTime.now();

    // ✅ Filter out expired ads (safe check in case Supabase doesn't do it)
    final activeAds = ads.where((ad) {
      final expiry = DateTime.tryParse(ad['expiry_date'] ?? '');
      return expiry == null || expiry.isAfter(now);
    }).toList();

    activeAds.shuffle(); // ✅ Randomize ads display for fairness

    setState(() {
      _ads = activeAds;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredAds {
    if (_selectedFilter == 'All') return _ads;
    return _ads.where((ad) => ad['service_type'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Spiritual Experts Marketplace',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.lightBlue, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 10),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: _serviceTypes.map((type) {
                  final isSelected = _selectedFilter == type;

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = type;
                        });
                      },
                      selectedColor: _filterColors[type] ?? Colors.blue,
                      backgroundColor: Colors.black.withOpacity(0.3),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            SizedBox(height: 10),

            // GridView Ads
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _filteredAds.isEmpty
                  ? Center(
                child: Text(
                  'No ads available for $_selectedFilter.',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              )
                  : Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: GridView.builder(
                  itemCount: _filteredAds.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.65,
                  ),
                  itemBuilder: (context, index) {
                    final ad = _filteredAds[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BusinessProfilePage(
                              name: ad['name'] ?? '',
                              serviceType: ad['service_type'] ?? '',
                              tagline: ad['tagline'] ?? '',
                              description: ad['description'] ?? '',
                              profileImageUrl: ad['profile_image_url'] ?? '',
                              rating: ad['rating'] != null ? double.tryParse(ad['rating'].toString()) ?? 0.0 : 0.0,
                              adCreatedDate: ad['created_at'] ?? 'Unknown Date',
                              userId: ad['user_id'] ?? '', // ✅ correct reference!
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 6,
                              offset: Offset(2, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Image Section
                            ClipRRect(
                              borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16)),
                              child: ad['profile_image_url'] != null &&
                                  ad['profile_image_url'].isNotEmpty
                                  ? Image.network(
                                ad['profile_image_url'],
                                height: 120,
                                fit: BoxFit.cover,
                              )
                                  : Image.asset(
                                'assets/images/serv1.png',
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),

                            // Info Section
                            SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Column(
                                children: [
                                  Text(
                                    ad['name'] ?? 'No Name',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    ad['service_type'] ?? 'Unknown',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    ad['tagline'] ?? '',
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
