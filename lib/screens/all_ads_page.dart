import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'business_profile_page.dart';

class AllAdsPage extends StatefulWidget {
  @override
  _AllAdsPageState createState() => _AllAdsPageState();
}

class _AllAdsPageState extends State<AllAdsPage> {
  List<Map<String, dynamic>> _ads = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  late BannerAd _bannerAd;
  bool _isAdLoaded = false;

  final List<String> _serviceTypes = [
    'All',
    'Psychic',
    'Tarot Reader',
    'Healer',
    'Medium',
    'Astrologer',
    'Energy Worker',
  ];

  final List<Color> chakraColors = [
    Colors.redAccent,
    Colors.orangeAccent,
    Colors.yellowAccent,
    Colors.greenAccent,
    Colors.blueAccent,
    Colors.indigoAccent,
    Colors.purpleAccent,
  ];

  @override
  void initState() {
    super.initState();
    _loadAds();
    _initBannerAd();
  }

  Future<void> _loadAds() async {
    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client
          .from('service_ads')
          .select('''
            id,
            user_id,
            name,
            tagline,
            description,
            profile_image_url,
            rating,
            created_at,
            expiry_date,
            service_ads_categories (
              service_categories (
                id,
                name
              )
            )
          ''')
          .order('created_at', ascending: false);

      final now = DateTime.now();

      final ads = response.map<Map<String, dynamic>>((ad) {
        final categories = (ad['service_ads_categories'] as List)
            .map((item) => item['service_categories']['name'] as String)
            .toList();

        return {
          ...ad,
          'categories': categories,
        };
      }).toList();

      final activeAds = ads.where((ad) {
        final expiryDate = DateTime.tryParse(ad['expiry_date'] ?? '');
        return expiryDate == null || expiryDate.isAfter(now);
      }).toList();

      setState(() {
        _ads = activeAds;
        _isLoading = false;
      });
    } catch (error) {
      print('❌ Error fetching ads: $error');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initBannerAd() async {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _isAdLoaded = true),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    );
    await _bannerAd.load();
  }

  List<Map<String, dynamic>> get _filteredAds {
    if (_selectedFilter == 'All') return _ads;

    return _ads.where((ad) {
      final categories = ad['categories'] as List<String>;
      return categories.contains(_selectedFilter);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/misc2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _isAdLoaded
                  ? Container(
                width: _bannerAd.size.width.toDouble(),
                height: _bannerAd.size.height.toDouble(),
                margin: EdgeInsets.symmetric(vertical: 8),
                child: AdWidget(ad: _bannerAd),
              )
                  : SizedBox(height: 0),
              _buildFilterBoxes(),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: Colors.amberAccent))
                    : _buildScrollableContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Aurana Sacred Marketplace',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12, // Made smaller for sleekness
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBoxes() {
    return Container(
      height: 48, // Slightly smaller height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12),
        itemCount: _serviceTypes.length,
        itemBuilder: (context, index) {
          final type = _serviceTypes[index];
          final isSelected = _selectedFilter == type;
          final chakraColor = chakraColors[index % chakraColors.length];

          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = type),
            child: Container(
              margin: EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Slightly smaller padding
              decoration: BoxDecoration(
                color: isSelected ? chakraColor.withOpacity(0.8) : Colors.black.withOpacity(0.4),
                border: Border.all(
                  color: isSelected ? chakraColor : Colors.white24,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: chakraColor.withOpacity(0.7),
                    blurRadius: 6,
                    spreadRadius: 1,
                  )
                ]
                    : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 3,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: Center(
                child: Text(
                  type,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13, // Reduced font size for sleekness
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScrollableContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _filteredAds.isEmpty
              ? _emptyState()
              : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _filteredAds.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.65,
              ),
              itemBuilder: (context, index) {
                final ad = _filteredAds[index];
                return _buildAdCard(ad);
              },
            ),
          ),
          _footerDescriptionBox(),
        ],
      ),
    );
  }

  Widget _buildAdCard(Map<String, dynamic> ad) {
    final categories = (ad['categories'] as List<String>).join(', ');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BusinessProfilePage(
            name: ad['name'] ?? '',
            serviceType: categories.isNotEmpty ? categories : 'Unknown',
            tagline: ad['tagline'] ?? '',
            description: ad['description'] ?? '',
            profileImageUrl: ad['profile_image_url'] ?? '',
            rating: (ad['rating'] as num?)?.toDouble() ?? 0.0,
            adCreatedDate: ad['created_at'] ?? '',
            userId: ad['user_id'] ?? '',
            adId: ad['id'] ?? '',
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.deepPurpleAccent, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.9),
              blurRadius: 10,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.redAccent.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 1,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                ad['profile_image_url'] ?? '',
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/images/default_avatar.png',
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Flexible(
                    child: Text(
                      ad['name'] ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 6),
                  Flexible(
                    child: Text(
                      categories,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, color: Colors.white24, size: 80),
          SizedBox(height: 12),
          Text(
            'No ads available for $_selectedFilter.',
            textAlign: TextAlign.center, // Center text!
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _footerDescriptionBox() {
    return Container(
      margin: EdgeInsets.all(12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurpleAccent, width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 28),
          SizedBox(height: 8),
          Text(
            'Welcome to the Aurana Sacred Marketplace.\nExplore and connect with trusted spiritual guides ready to assist you on your personal journey of healing, clarity, and growth.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }
}
