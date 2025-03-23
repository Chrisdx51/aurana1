import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AuraAnalysisScreen extends StatefulWidget {
  final String imagePath;
  final Color auraColor;
  final String auraMeaning;
  final List<String> affirmations;

  const AuraAnalysisScreen({
    Key? key,
    required this.imagePath,
    required this.auraColor,
    required this.auraMeaning,
    required this.affirmations,
  }) : super(key: key);

  @override
  _AuraAnalysisScreenState createState() => _AuraAnalysisScreenState();
}

class _AuraAnalysisScreenState extends State<AuraAnalysisScreen> with SingleTickerProviderStateMixin {
  late final ConfettiController _confettiController;
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
    _initBannerAd();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _initBannerAd() async {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // ✅ Replace with live AdMob ID before publishing
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _isAdLoaded = true),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    );

    await _bannerAd!.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // fallback
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/profile.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                if (_isAdLoaded && _bannerAd != null)
                  Container(
                    color: Colors.transparent,
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildAuraImage(),
                          const SizedBox(height: 20),
                          _buildAuraMeaning(),
                          const SizedBox(height: 10),
                          _buildEnergyLevelIndicator(),
                          const SizedBox(height: 20),
                          _buildSpiritualRecommendations(),
                          const SizedBox(height: 20),
                          _buildDailyAffirmations(),
                          const SizedBox(height: 20),
                          _buildShareButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildConfetti(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "Aura Analysis",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48), // For symmetry
        ],
      ),
    );
  }

  Widget _buildAuraImage() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: widget.auraColor, width: 3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.file(
              File(widget.imagePath),
              fit: BoxFit.cover,
            ),
          ),
        ).animate().fadeIn(duration: 500.ms).scale(),
        Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: RadialGradient(
              colors: [widget.auraColor.withOpacity(0.5), Colors.transparent],
              radius: 1.0,
            ),
          ),
        ).animate().fadeIn().scaleXY(end: 1.05),
      ],
    );
  }

  Widget _buildAuraMeaning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Text(
        widget.auraMeaning,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: widget.auraColor,
        ),
        textAlign: TextAlign.center,
      ),
    ).animate().fadeIn(duration: 700.ms);
  }

  Widget _buildEnergyLevelIndicator() {
    final energyLevel = _calculateEnergyLevel(widget.auraColor);

    return Card(
      color: Colors.white.withOpacity(0.15),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            const Text(
              "Aura Energy Level",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '${energyLevel.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LinearProgressIndicator(
                    value: energyLevel / 100,
                    backgroundColor: Colors.grey.shade700,
                    color: widget.auraColor,
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpiritualRecommendations() {
    final recommendations = _getSpiritualRecommendations(widget.auraColor);
    return Card(
      color: Colors.white.withOpacity(0.15),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Spiritual Recommendations",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            ...recommendations.map((rec) => ListTile(
              leading: const Icon(Icons.self_improvement, color: Colors.white),
              title: Text(
                rec,
                style: const TextStyle(color: Colors.white),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyAffirmations() {
    final affirmations = widget.affirmations;
    return Card(
      color: Colors.white.withOpacity(0.15),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Daily Affirmations",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            ...affirmations.map((aff) => ListTile(
              leading: const Icon(Icons.auto_awesome, color: Colors.orange),
              title: Text(
                aff,
                style: const TextStyle(color: Colors.white),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton() {
    return ElevatedButton.icon(
      onPressed: _shareAuraDetails,
      icon: const Icon(Icons.share),
      label: const Text("Share Aura"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.2),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      ),
    ).animate().fadeIn().shake();
  }

  Widget _buildConfetti() {
    return Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: _confettiController,
        blastDirectionality: BlastDirectionality.explosive,
        numberOfParticles: 20,
        shouldLoop: false,
        colors: [widget.auraColor, Colors.white, Colors.amberAccent],
      ),
    );
  }

  void _shareAuraDetails() async {
    try {
      await Share.shareXFiles(
        [XFile(widget.imagePath)],
        text: 'Check out my aura! It\'s ${widget.auraMeaning}. What does your aura look like?',
      );
    } catch (e) {
      print("Error sharing aura details: $e");
    }
  }

  double _calculateEnergyLevel(Color color) {
    final totalColorValue = color.red + color.green + color.blue;
    return (totalColorValue / (255 * 3)) * 100;
  }

  List<String> _getSpiritualRecommendations(Color color) {
    if (color.red > color.green && color.red > color.blue) {
      return [
        "Practice grounding meditation.",
        "Engage in physical activity.",
        "Focus on deep breathing exercises."
      ];
    } else if (color.green > color.red && color.green > color.blue) {
      return [
        "Spend time in nature.",
        "Practice heart-centered meditations.",
        "Give yourself time to rest and heal."
      ];
    } else if (color.blue > color.red && color.blue > color.green) {
      return [
        "Journal your thoughts.",
        "Practice throat chakra exercises.",
        "Engage in mindful listening."
      ];
    } else if (color == Colors.purple) {
      return [
        "Meditate on your third eye.",
        "Trust your intuition today.",
        "Engage in spiritual study."
      ];
    } else if (color == Colors.yellow) {
      return [
        "Focus on your creative projects.",
        "Smile more today.",
        "Write down 3 things you're grateful for."
      ];
    } else {
      return [
        "Try something adventurous today.",
        "Dance or do expressive movement.",
        "Say yes to new opportunities."
      ];
    }
  }
}
